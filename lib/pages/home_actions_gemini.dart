// lib/pages/home_actions_gemini.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter_logs/flutter_logs.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import '../utils/gemini_service.dart';
import '../utils/product_matcher.dart';
import '../utils/excel_export.dart';
import '../utils/ocr_masker.dart';
import 'camera_capture_page.dart';
import 'nifuda_ocr_confirm_page.dart';
import 'product_list_ocr_confirm_page.dart';
import 'product_list_mask_preview_page.dart';
import '../widgets/excel_preview_dialog.dart';
import 'matching_result_page.dart';
import '../widgets/custom_snackbar.dart';
import 'directory_image_picker_page.dart';
import 'streaming_progress_dialog.dart';

// --- Local Helper Functions (Duplicated for consistency) ---

void _logError(String tag, String subTag, Object error, StackTrace? stack) {
  FlutterLogs.logThis(
    tag: tag,
    subTag: subTag,
    logMessage: stack == null ? error.toString() : '${error.toString()}\n$stack',
    exception: (error is Exception) ? error : Exception(error.toString()),
    level: LogLevel.ERROR,
  );
}

void _showLoadingDialog(BuildContext context, String message) {
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Flexible(child: Text(message)),
          ],
        ),
      );
    },
  );
}

void _hideLoadingDialog(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}

void _showErrorDialog(BuildContext context, String title, String message) {
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}

void _logActionError({
  required String tag,
  required String message,
  required Object error,
  StackTrace? stack,
}) {
  FlutterLogs.logThis(
    tag: tag,
    subTag: 'ACTION_ERROR',
    logMessage: '$message${stack != null ? '\n$stack' : ''}',
    exception: (error is Exception) ? error : Exception(error.toString()),
    level: LogLevel.ERROR,
  );
  debugPrint('[$tag] $message: $error');
}

img.Image _applySharpeningFilter(img.Image image) {
  final Float32List kernel = Float32List.fromList([
    0, -1, 0,
    -1, 5, -1,
    0, -1, 0,
  ]);
  return img.convolution(
    image,
    filter: kernel,
  );
}

// --- Nifuda Action (No change in flow) ---

Future<List<List<String>>?> captureProcessAndConfirmNifudaActionWithGemini(BuildContext context, String projectFolderPath) async {
  final List<Map<String, dynamic>>? allAiResults =
      await Navigator.push<List<Map<String, dynamic>>>(
    context,
    MaterialPageRoute(builder: (_) => CameraCapturePage(
        overlayText: '荷札を枠に合わせて撮影',
        isProductListOcr: false,
        projectFolderPath: projectFolderPath,
        // sendImageToGemini のシグネチャと一致
        aiService: sendImageToGemini,
    )),
  );
  if (allAiResults == null || allAiResults.isEmpty) {
    if (context.mounted) {
      showCustomSnackBar(context, '荷札の撮影またはOCR処理がキャンセルされました。');
      FlutterLogs.logThis(
        tag: 'OCR_ACTION',
        subTag: 'NIFUDA_GEMINI_CANCEL',
        logMessage: 'Nifuda Gemini OCR was cancelled by user.',
        level: LogLevel.WARNING,
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  List<List<String>> allConfirmedNifudaRows = [];
  int imageIndex = 0;
  for (final result in allAiResults) {
    imageIndex++;
    if (!context.mounted) break;
    if (context.mounted) _showLoadingDialog(context, '$imageIndex / ${allAiResults.length} 枚目の結果を確認中...');
    final Map<String, dynamic>? confirmedResultMap = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => NifudaOcrConfirmPage(
          extractedData: result,
          imageIndex: imageIndex,
          totalImages: allAiResults.length,
        ),
      ),
    );
    if (context.mounted) _hideLoadingDialog(context);
    if (confirmedResultMap != null) {
      List<String> confirmedRowAsList = NifudaOcrConfirmPage.nifudaFields
          .map((field) => confirmedResultMap[field]?.toString() ?? '')
          .toList();
      allConfirmedNifudaRows.add(confirmedRowAsList);
    } else {
      if (context.mounted) {
         final proceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
                  title: Text('$imageIndex枚目の確認が破棄されました'),
                  content: const Text('次の画像の確認に進みますか？\n「いいえ」を選択すると処理を中断します。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('いいえ (中断)')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('はい (次へ)')),
                  ],
                ));
        if (proceed != true) {
           if(context.mounted) showCustomSnackBar(context, '荷札確認処理が中断されました。');
           FlutterLogs.logThis(
             tag: 'OCR_ACTION',
             subTag: 'NIFUDA_GEMINI_CONFIRM_INTERRUPTED',
             logMessage: 'Nifuda Gemini confirmation interrupted after $imageIndex images.',
             level: LogLevel.WARNING,
           );
           return allConfirmedNifudaRows.isNotEmpty ? allConfirmedNifudaRows : null;
        }
      } else {
        break;
      }
    }
  }
  if (allConfirmedNifudaRows.isNotEmpty) {
    FlutterLogs.logInfo('OCR_ACTION', 'NIFUDA_GEMINI_CONFIRM_SUCCESS', '${allConfirmedNifudaRows.length} Nifuda rows confirmed by Gemini.');
    return allConfirmedNifudaRows;
  } else {
    if (context.mounted) showCustomSnackBar(context, '有効な荷札データが1件も確定されませんでした。');
    return null;
  }
}

// --- Product List Action (Streaming & Dynamic Masking Implemented) ---

Future<List<List<String>>?> captureProcessAndConfirmProductListActionWithGemini(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading,
  String projectFolderPath,
) async {
  List<String>? imageFilePaths;
  try {
    final options = DocumentScannerOptions(pageLimit: 100, isGalleryImport: false, documentFormat: DocumentFormat.jpeg, mode: ScannerMode.full);
    final docScanner = DocumentScanner(options: options);
    final result = await docScanner.scanDocument();
    imageFilePaths = result?.images;
  } catch (e, s) {
    _logError('DOC_SCANNER', 'Scanner launch error (Gemini)', e, s);
    if (context.mounted) _showErrorDialog(context, 'スキャナ起動エラー', 'Google ML Kit Document Scannerの起動に失敗しました: $e');
    return null;
  }
  if (imageFilePaths == null || imageFilePaths.isEmpty) {
    if (context.mounted) showCustomSnackBar(context, '製品リストの撮影がキャンセルされました。');
    return null;
  }

  // 1. 画像の読み込みと前処理 (リサイズ/シャープネス)
  List<Uint8List> rawImageBytesList = [];
  const int PERSPECTIVE_WIDTH = 1920;
  try {
    for (var path in imageFilePaths) {
      final file = File(path);
      final rawBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(rawBytes);
      if (originalImage == null) continue;
      img.Image normalizedImage = img.copyResize(originalImage, width: PERSPECTIVE_WIDTH, height: (originalImage.height * (PERSPECTIVE_WIDTH / originalImage.width)).round());
      normalizedImage = _applySharpeningFilter(normalizedImage);
      rawImageBytesList.add(Uint8List.fromList(img.encodeJpg(normalizedImage, quality: 100)));
    }
  } catch (e, s) {
    _logError('IMAGE_PROC', 'Image read/resize error (Gemini)', e, s);
    if (context.mounted) _showErrorDialog(context, '画像処理エラー', 'スキャン済みファイルの読み込みまたはリサイズに失敗しました: $e');
    return null;
  }
  if (rawImageBytesList.isEmpty) {
      if(context.mounted) _showErrorDialog(context, '画像処理エラー', '有効な画像が読み込めませんでした。');
      return null;
  }

  // 2. マスクテンプレートの決定
  String template;
  switch (selectedCompany) {
    case 'T社': template = 't'; break;
    case 'マスク処理なし': template = 'none'; break;
    case '動的マスク処理': template = 'dynamic'; break;
    default: if(context.mounted) _showErrorDialog(context, 'テンプレートエラー', '無効な会社名が選択されました。'); return null;
  }
  
  // 3. マスクプレビューと動的マスク情報の取得
  final Uint8List firstImageBytes = rawImageBytesList.first;
  if (!context.mounted) return null;
  _showLoadingDialog(context, 'プレビューを準備中...');
  _hideLoadingDialog(context);

  // ★ 修正: 戻り値の型を変更
  final MaskPreviewResult? previewResult = await Navigator.push<MaskPreviewResult>(
    context, MaterialPageRoute(builder: (_) => ProductListMaskPreviewPage(
      previewImageBytes: firstImageBytes, 
      maskTemplate: template, 
      imageIndex: 1, 
      totalImages: rawImageBytesList.length
    )),
  );
  
  if (previewResult == null) {
      if(context.mounted) showCustomSnackBar(context, 'マスク確認が破棄されたため、OCR処理を中断しました。');
      return null;
  }

  // ★ 修正: 動的マスクのRectリストを取得
  final List<Rect> dynamicMasks = previewResult.dynamicMasks;
  
  // 4. AIへ送信する最終画像の準備
  List<Uint8List> finalImagesToSend = [previewResult.imageBytes];
  
  for (int i = 1; i < rawImageBytesList.length; i++) {
    if(context.mounted) _showLoadingDialog(context, '画像を準備中... (${i + 1}/${rawImageBytesList.length})');
    final image = img.decodeImage(rawImageBytesList[i])!;
    
    img.Image maskedImage = image;
    
    if (template == 't') {
        // T社固定マスクを適用
        maskedImage = applyMaskToImage(image, template: 't');
    } else if (template == 'dynamic' && dynamicMasks.isNotEmpty) {
        // ★ 修正: 動的マスクを2枚目以降にも適用
        maskedImage = applyMaskToImage(image, template: 'dynamic', dynamicMaskRects: dynamicMasks);
    } else {
        maskedImage = image;
    }
    
    finalImagesToSend.add(Uint8List.fromList(img.encodeJpg(maskedImage, quality: 100)));
  }
  
  if(context.mounted) _hideLoadingDialog(context);
  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }
  
  // 5. ストリーミングリクエストの実行
  List<Map<String, dynamic>?> allAiRawResults = [];
  
  // ★★★ 修正: プロンプトと合わせるため、T社の場合は 'TMEIC' を渡す
  final String companyForGemini = (selectedCompany == 'T社') ? 'TMEIC' : selectedCompany;

  for (int i = 0; i < finalImagesToSend.length; i++) {
      if (!context.mounted) break;
      final imageBytes = finalImagesToSend[i];
      
      // ★ 修正: ストリーミング関数を使用 (companyForGemini を渡す)
      final Stream<String> stream = sendImageToGeminiStream(
        imageBytes, 
        company: companyForGemini,
      );
      
      final String streamTitle = '製品リスト抽出中 (Gemini) (${i + 1} / ${finalImagesToSend.length})';
      
      // ★ 修正: ストリーミングダイアログを表示
      final String? rawJsonResponse = await StreamingProgressDialog.show(
        context: context, 
        stream: stream, 
        title: streamTitle, 
        serviceTag: 'GEMINI_SERVICE'
      );
      
      if (rawJsonResponse == null) {
          _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_STREAM_FAIL', 'Stream failed or cancelled for image ${i + 1}', null);
          if (context.mounted) _showErrorDialog(context, '抽出エラー', '${i + 1}枚目の画像の抽出に失敗しました。処理を中断します。');
          // ★★★ 修正: _processRawProductResults に selectedCompany を渡す
          return allAiRawResults.isNotEmpty ? await _processRawProductResults(context, allAiRawResults, selectedCompany) : null;
      }
      
      // JSONのパース
      String? stripped; // ★ 修正: strippedをtry/catch外で定義
      try {
          // Gemini service内の _stripCodeFences を再実装（ここでは一旦簡易的に）
          stripped = rawJsonResponse.trim();
          if (stripped.startsWith('```')) {
            stripped = stripped
                .replaceFirst(RegExp(r'^```(json)?', caseSensitive: false), '')
                .replaceFirst(RegExp(r'```$'), '')
                .trim();
          }
          final Map<String, dynamic> decoded = jsonDecode(stripped) as Map<String, dynamic>;
          allAiRawResults.add(decoded);
          FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_GEMINI_PARSE_OK', 'Successfully parsed response for image ${i + 1}');
      } catch (e, s) {
          // ★ 修正: strippedがnullでないことを確認してからログに出力
          _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_PARSE_FAIL', 'Failed to parse JSON for image ${i + 1}: ${stripped ?? rawJsonResponse}', s);
          allAiRawResults.add(null);
      }
  }

  // 6. 結果の統合と確認画面への遷移
  if (!context.mounted) return null;
  // ★★★ 修正: _processRawProductResults に selectedCompany を渡す
  return _processRawProductResults(context, allAiRawResults, selectedCompany);
}

// ★★★ 修正: 会社名(selectedCompany)を引数で受け取り、OrderNo生成ロジックを分岐 ★★★
Future<List<List<String>>?> _processRawProductResults(
  BuildContext context, 
  List<Map<String, dynamic>?> allAiRawResults,
  String selectedCompany, // ★引数を追加
) async {
  List<Map<String, String>> allExtractedProductRows = [];
  // ★★★ 修正: productFieldsは 'product_list_ocr_confirm_page.dart' から取得する
  const List<String> expectedProductFields = ProductListOcrConfirmPage.productFields;
  
  // ★★★ 修正: T社の場合、プロンプトに 'TMEIC' を使用しているため、ここで 'T社' に戻す
  final bool isTCompany = (selectedCompany == 'T社') || (selectedCompany == 'TMEIC');

  for(final result in allAiRawResults){
     if (result != null && result.containsKey('products') && result['products'] is List) {
        final List<dynamic> productListRaw = result['products'];
        // 共通OrderNo (T社の場合は "QZ83941"、それ以外は "T-12345-" などを期待)
        String commonOrderNo = result['commonOrderNo']?.toString() ?? ''; 
        
        for (final item in productListRaw) {
          if (item is Map) {
            Map<String, String> row = {};
            String finalOrderNo = '';

            // ★★★ ユーザー要求に基づくロジック変更 (T社 vs T社以外) ★★★
            if (isTCompany) {
              // T社の場合: commonOrderNo (QZ83941) + 備考(NOTE) (FEV2385)
              // ★ 修正: プロンプトに合わせて '備考(NOTE)' を使用
              // (product_list_ocr_confirm_page.dart の
              // productFields に '備考(NOTE)' が含まれている必要がある)
              final String note = item['備考(NOTE)']?.toString() ?? '';
              finalOrderNo = '$commonOrderNo $note'.trim(); // 例: "QZ83941 FEV2385"
            } else {
              // T社以外の場合: commonOrderNo + 備考(REMARKS) ※枝番
              // ★ 修正: プロンプトに合わせて '備考(REMARKS)' を使用
              // (product_list_ocr_confirm_page.dart の
              // productFields に '備考(REMARKS)' が含まれている必要がある)
              final String remarks = item['備考(REMARKS)']?.toString() ?? ''; 
              finalOrderNo = commonOrderNo; // まず共通番号をセット

              if (commonOrderNo.isNotEmpty && remarks.isNotEmpty) {
                final lastSeparatorIndex = commonOrderNo.lastIndexOf(RegExp(r'[\s-]'));
                if (lastSeparatorIndex != -1) {
                  final prefix = commonOrderNo.substring(0, lastSeparatorIndex + 1);
                  finalOrderNo = '$prefix$remarks'; // 例: "T-12345-" + "01"
                } else {
                  finalOrderNo = '$commonOrderNo $remarks'; // 例: "12345" + "01"
                }
              }
            }
            // ★★★ ロジック変更ここまで ★★★
            
            for (String field in expectedProductFields) {
              // 'ORDER No.' のみ、上で生成した finalOrderNo を使う
              row[field] = (field == 'ORDER No.') ? finalOrderNo : item[field]?.toString() ?? '';
            }
            allExtractedProductRows.add(row);
          }
        }
      } else {
        // パースエラーは既にログ済み
      }
  }

  if (allExtractedProductRows.isNotEmpty) {
      FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_GEMINI_CONFIRM', '${allExtractedProductRows.length} rows extracted by Gemini for confirmation.');
      return Navigator.push<List<List<String>>>(
        context, MaterialPageRoute(builder: (_) => ProductListOcrConfirmPage(extractedProductRows: allExtractedProductRows)),
      );
  } else {
      _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_NO_RESULT', 'No valid product list data extracted by Gemini.', null);
      if (context.mounted) _showErrorDialog(context, 'OCR結果なし', '有効な製品リストデータが抽出されませんでした。');
      return null;
  }
}