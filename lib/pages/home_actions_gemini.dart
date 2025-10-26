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
import 'package:permission_handler/permission_handler.dart'; // ★ 追加: パーミッション
import 'package:media_scanner/media_scanner.dart'; // ★ 追加: ギャラリースキャン

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
// ( _logError, _showLoadingDialog, _hideLoadingDialog, _showErrorDialog, _logActionError, _formatTimestampForFilename, _applySharpeningFilter は変更なしのため省略 )
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
// ログファイル名に使用するタイムスタンプを生成 (例: 20251026_140800)
String _formatTimestampForFilename(DateTime dateTime) {
  return '${dateTime.year.toString().padLeft(4, '0')}'
      '${dateTime.month.toString().padLeft(2, '0')}'
      '${dateTime.day.toString().padLeft(2, '0')}_'
      '${dateTime.hour.toString().padLeft(2, '0')}'
      '${dateTime.minute.toString().padLeft(2, '0')}'
      '${dateTime.second.toString().padLeft(2, '0')}';
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
// --- End of Utility Functions ---


// ★★★ 追加: スキャンされた製品リスト画像を保存する関数 (home_actions.dart と同じ) ★★★
Future<void> _saveScannedProductImages(
    BuildContext context,
    String projectFolderPath,
    List<String> sourceImagePaths) async {
  if (!Platform.isAndroid) {
    debugPrint("この画像保存方法はAndroid専用です。");
    return;
  }
  try {
    // ストレージパーミッションの確認・要求
    var status = await Permission.storage.status;
    if (!status.isGranted) status = await Permission.storage.request();
    if (!status.isGranted) {
      if (Platform.isAndroid) {
        var externalStatus = await Permission.manageExternalStorage.status;
        if (!externalStatus.isGranted) {
          externalStatus = await Permission.manageExternalStorage.request();
        }
        if (!externalStatus.isGranted) {
          throw Exception('ストレージへのアクセス権限がありません。');
        }
      } else {
        throw Exception('ストレージへのアクセス権限がありません。');
      }
    }

    final String targetDirPath = p.join(projectFolderPath, "製品リスト画像");
    final Directory targetDir = Directory(targetDirPath);

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
      FlutterLogs.logInfo('IMAGE_SAVE', 'DIR_CREATED', 'Created directory: $targetDirPath');
    }

    int savedCount = 0;
    for (final sourcePath in sourceImagePaths) {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        FlutterLogs.logWarn('IMAGE_SAVE', 'SOURCE_NOT_FOUND', 'Source image not found: $sourcePath');
        continue;
      }

      final timestamp = _formatTimestampForFilename(DateTime.now());
      final originalExtension = p.extension(sourcePath);
      final fileName = 'product_list_$timestamp$originalExtension';
      final targetFilePath = p.join(targetDir.path, fileName);

      try {
        await sourceFile.copy(targetFilePath);
        await MediaScanner.loadMedia(path: targetFilePath);
        savedCount++;
        FlutterLogs.logInfo('IMAGE_SAVE', 'SAVE_SUCCESS', 'Saved product list image to $targetFilePath');
      } catch (e, s) {
        _logError('IMAGE_SAVE', 'COPY_ERROR', 'Failed to copy $sourcePath to $targetFilePath: $e', s);
      }
       await Future.delayed(const Duration(milliseconds: 10));
    }

    if (context.mounted && savedCount > 0) {
      final savedPath = p.join(p.basename(projectFolderPath), "製品リスト画像");
      showCustomSnackBar(context, '$savedCount 枚の製品リスト画像を保存しました: $savedPath', showAtTop: true);
    } else if (context.mounted && sourceImagePaths.isNotEmpty && savedCount == 0) {
      showCustomSnackBar(context, '製品リスト画像の保存に失敗しました。', isError: true, showAtTop: true);
    }

  } catch (e, s) {
    _logError('IMAGE_SAVE', 'SAVE_PROCESS_ERROR', 'Error during product list image saving process: $e', s);
    if (context.mounted) {
      showCustomSnackBar(context, '製品リスト画像の保存中にエラーが発生しました: ${e.toString()}', isError: true, showAtTop: true);
    }
  }
}
// ★★★ 保存関数ここまで ★★★


// --- Nifuda Action ---
Future<List<List<String>>?> captureProcessAndConfirmNifudaActionWithGemini(BuildContext context, String projectFolderPath) async {
  // (荷札処理のコードは変更なしのため省略)
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

// --- Product List Action ---
Future<List<List<String>>?> captureProcessAndConfirmProductListActionWithGemini(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading,
  String projectFolderPath,
) async {
  List<String>? imageFilePaths;
  try {
    // 1. DocumentScanner を起動して画像パスを取得
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
    if (context.mounted) showCustomSnackBar(context, '製品リストのスキャンがキャンセルされました。');
    return null;
  }

  // ★★★ 2. スキャンした画像を指定フォルダに保存 ★★★
  unawaited(_saveScannedProductImages(context, projectFolderPath, imageFilePaths));
  // ★★★ 保存処理の呼び出しここまで ★★★

  // 3. 画像の読み込みと前処理
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

  // 4. マスク処理とプレビュー
  String template;
  switch (selectedCompany) {
    case 'T社': template = 't'; break;
    case 'マスク処理なし': template = 'none'; break;
    case '動的マスク処理': template = 'dynamic'; break;
    default: if(context.mounted) _showErrorDialog(context, 'テンプレートエラー', '無効な会社名が選択されました。'); return null;
  }

  final Uint8List firstImageBytes = rawImageBytesList.first;
  if (!context.mounted) return null;
  // ★ 修正: ローディング表示削除
  // _showLoadingDialog(context, 'プレビューを準備中...');
  // _hideLoadingDialog(context);

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
  final List<Rect> dynamicMasks = previewResult.dynamicMasks;

  // 5. マスク適用後の最終画像リストを作成
  List<Uint8List> finalImagesToSend = [previewResult.imageBytes];
  if(rawImageBytesList.length > 1) {
      if (context.mounted) _showLoadingDialog(context, '画像を準備中... (2/${rawImageBytesList.length})');
      try {
          for (int i = 1; i < rawImageBytesList.length; i++) {
            if(!context.mounted) break;
             if(i > 1 && context.mounted) {
                Navigator.pop(context);
               _showLoadingDialog(context, '画像を準備中... (${i + 1}/${rawImageBytesList.length})');
            }

            final image = img.decodeImage(rawImageBytesList[i])!;
            img.Image maskedImage;
            if (template == 't') {
                maskedImage = applyMaskToImage(image, template: 't');
            } else if (template == 'dynamic' && dynamicMasks.isNotEmpty) {
                maskedImage = applyMaskToImage(image, template: 'dynamic', dynamicMaskRects: dynamicMasks);
            } else {
                maskedImage = image;
            }
            finalImagesToSend.add(Uint8List.fromList(img.encodeJpg(maskedImage, quality: 100)));
          }
      } finally {
          if(context.mounted) _hideLoadingDialog(context);
      }
  }

  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }

  // 6. AI (Gemini) へのストリーミングリクエスト実行
  List<Map<String, dynamic>?> allAiRawResults = [];
  final String companyForGemini = (selectedCompany == 'T社') ? 'TMEIC' : selectedCompany; // プロンプト用

   for (int i = 0; i < finalImagesToSend.length; i++) {
      if (!context.mounted) break;
      final imageBytes = finalImagesToSend[i];

      final Stream<String> stream = sendImageToGeminiStream(
        imageBytes,
        company: companyForGemini,
      );

      final String streamTitle = '製品リスト抽出中 (Gemini) (${i + 1} / ${finalImagesToSend.length})';

      final String? rawJsonResponse = await StreamingProgressDialog.show(
        context: context,
        stream: stream,
        title: streamTitle,
        serviceTag: 'GEMINI_SERVICE'
      );

      if (rawJsonResponse == null) {
          _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_STREAM_FAIL', 'Stream failed or cancelled for image ${i + 1}', null);
           if (context.mounted) _showErrorDialog(context, '抽出エラー', '${i + 1}枚目の画像の抽出に失敗しました。処理を中断します。');
          return allAiRawResults.isNotEmpty ? await _processRawProductResults(context, allAiRawResults, selectedCompany) : null;
      }

      try {
          String stripped = rawJsonResponse.trim();
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
          _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_PARSE_FAIL', 'Failed to parse JSON for image ${i + 1}: ${rawJsonResponse}', s);
          allAiRawResults.add(null);
      }
  }

  // 7. 結果の統合と確認画面への遷移
  if (!context.mounted) return null;
  return _processRawProductResults(context, allAiRawResults, selectedCompany);
}


// ★★★ 修正: 会社名(selectedCompany)を引数で受け取り、OrderNo生成ロジックを分岐 ★★★
Future<List<List<String>>?> _processRawProductResults(
  BuildContext context,
  List<Map<String, dynamic>?> allAiRawResults,
  String selectedCompany, // ★引数を追加
) async {
  List<Map<String, String>> allExtractedProductRows = [];
  // ★ 修正: product_list_ocr_confirm_page からフィールドリストを取得
  const List<String> expectedProductFields = ProductListOcrConfirmPage.productFields;

  final bool isTCompany = (selectedCompany == 'T社'); // ★ 簡略化

  for(final result in allAiRawResults){
     if (result != null && result.containsKey('products') && result['products'] is List) {
        final List<dynamic> productListRaw = result['products'];
        // AIが返す commonOrderNo (T社の場合は "QZ83941"、それ以外は "T-12345-")
        String commonOrderNo = result['commonOrderNo']?.toString() ?? '';

        for (final item in productListRaw) {
          if (item is Map) {
            Map<String, String> row = {};
            String finalOrderNo = '';

            // ★★★ Order No. 生成ロジック (再修正) ★★★
            if (isTCompany) {
              // T社の場合: commonOrderNo (QZ83941) + 備考(NOTE) (FEV2385)
              final String note = item['備考(NOTE)']?.toString() ?? '';
              finalOrderNo = '$commonOrderNo $note'.trim(); // 例: "QZ83941 FEV2385"
            } else {
              // T社以外の場合: commonOrderNo (T-12345-) + 備考(REMARKS) (01)
              final String remarks = item['備考(REMARKS)']?.toString() ?? '';
              finalOrderNo = commonOrderNo; // まずプレフィックスをセット

              if (commonOrderNo.isNotEmpty && remarks.isNotEmpty) {
                 if (commonOrderNo.endsWith('-') || commonOrderNo.endsWith(' ')) {
                     finalOrderNo = '$commonOrderNo$remarks';
                 } else {
                     finalOrderNo = '$commonOrderNo $remarks';
                 }
              }
            }
            // ★★★ ロジック変更ここまで ★★★

            for (String field in expectedProductFields) {
              row[field] = (field == 'ORDER No.') ? finalOrderNo : item[field]?.toString() ?? '';
            }
            allExtractedProductRows.add(row);
          }
        }
      } else {
         FlutterLogs.logWarn('OCR_ACTION', 'INVALID_AI_RESULT_GEMINI', 'Received null or invalid AI result structure.');
      }
  }

  if (allExtractedProductRows.isNotEmpty) {
      FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_GEMINI_CONFIRM', '${allExtractedProductRows.length} rows extracted by Gemini for confirmation.');
      return Navigator.push<List<List<String>>>(
        context, MaterialPageRoute(builder: (_) => ProductListOcrConfirmPage(extractedProductRows: allExtractedProductRows)),
      );
  } else {
      _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_NO_RESULT', 'No valid product list data extracted by Gemini after processing.', null);
      if (context.mounted) _showErrorDialog(context, 'OCR結果なし', '有効な製品リストデータが抽出されませんでした。');
      return null;
  }
}