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
import 'package:flutter_logs/flutter_logs.dart'; // ★ 追加: flutter_logs
// ★★★ 修正: Google ML Kit Document Scanner のインポートを追加 ★★★
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


// --- (ヘルパー関数は変更なし) ---
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
            Text(message),
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

// ★★★ 追加: エラーロギングヘルパー関数 (home_actions.dartから流用) ★★★
void _logError(String tag, String message, dynamic error, StackTrace? stack) {
  FlutterLogs.logError(
    tag,
    'ACTION_ERROR',
    message,
    error: error,
    stackTrace: stack,
    timestamp: DateTime.now(),
  );
  debugPrint('[$tag] $message: $error');
}

// ★★★ 修正: シャープニングフィルター適用ヘルパー関数 - divisorとoffsetを削除 ★★★
img.Image _applySharpeningFilter(img.Image image) {
  // シャープニングカーネル (一般的なもの)
  // [0, -1, 0]
  // [-1, 5, -1]
  // [0, -1, 0]
  final Float32List kernel = Float32List.fromList([
    0, -1, 0,
    -1, 5, -1,
    0, -1, 0,
  ]);
  
  // 3x3 のカーネルで畳み込みを適用
  return img.convolution(
    image, 
    filter: kernel, // 'filter' named argumentを使用
    // divisor: 1, // エラーのため削除
    // offset: 0,  // エラーのため削除
  );
}


// ★★★ 追加：Geminiで荷札OCRを行う新機能 ★★★
Future<List<List<String>>?> captureProcessAndConfirmNifudaActionWithGemini(BuildContext context, String projectFolderPath) async {
  // (この関数は変更なし)
  final List<Map<String, dynamic>>? allAiResults =
      await Navigator.push<List<Map<String, dynamic>>>(
    context,
    MaterialPageRoute(builder: (_) => CameraCapturePage(
        overlayText: '荷札を枠に合わせて撮影',
        isProductListOcr: false,
        projectFolderPath: projectFolderPath,
        aiService: sendImageToGemini, // Geminiの関数を渡す
    )),
  );

  if (allAiResults == null || allAiResults.isEmpty) {
    if (context.mounted) {
      showCustomSnackBar(context, '荷札の撮影またはOCR処理がキャンセルされました。');
      FlutterLogs.logWarning('OCR_ACTION', 'NIFUDA_GEMINI_CANCEL', 'Nifuda Gemini OCR was cancelled by user.');
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
      List<String> confirmedRowAsList = NifudaOcrConfirmPage.nifudaFields.map((field) {
         return confirmedResultMap[field]?.toString() ?? '';
      }).toList();
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
           FlutterLogs.logWarning('OCR_ACTION', 'NIFUDA_GEMINI_CONFIRM_INTERRUPTED', 'Nifuda Gemini confirmation interrupted after $imageIndex images.');
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
    if (context.mounted) {
        showCustomSnackBar(context, '有効な荷札データが1件も確定されませんでした。');
    }
    return null;
  }
}


// ★★★ 変更: カメラ連続撮影による製品リストOCR処理 (Gemini版) - setloading削除とログ追加 ★★★
Future<List<List<String>>?> captureProcessAndConfirmProductListActionWithGemini(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading, // <--- このコールバックは使用しないが、引数は残す
  String projectFolderPath,
) async {
  // 1. ML Kit Document Scannerを起動して、補正済み画像のファイルパスリストを取得
  List<String>? imageFilePaths;
  try {
    // ★★★ 修正: DocumentScannerOptionsとDocumentScannerのインスタンス化を修正 ★★★
    final options = DocumentScannerOptions(
      pageLimit: 100, // ページ数の制限なし（実質）
      isGalleryImport: false, // ギャラリーからのインポートを許可しない
      documentFormat: DocumentFormat.jpeg, // JPEG形式で結果を取得
      mode: ScannerMode.full, // ★★★ 修正: scannerMode を mode に変更 ★★★
    );
    final docScanner = DocumentScanner(options: options); // instanceの代わりにコンストラクタを使用
    
    final result = await docScanner.scanDocument(); // インスタンスメソッドとして呼び出し
    imageFilePaths = result?.images; // ★★★ 修正: scannedImages を images に変更 ★★★
    
  } catch (e, s) {
    _logError('DOC_SCANNER', 'Scanner launch error (Gemini)', e, s);
    if (context.mounted) _showErrorDialog(context, 'スキャナ起動エラー', 'Google ML Kit Document Scannerの起動に失敗しました: $e');
    return null;
  }


  if (imageFilePaths == null || imageFilePaths.isEmpty) {
    if (context.mounted) showCustomSnackBar(context, '製品リストの撮影がキャンセルされました。');
    return null;
  }

  // 2. 取得したファイルパスからUint8Listリストを作成し、固定サイズにリサイズ（正規化）
  List<Uint8List> rawImageBytesList = [];
  // ★★★ 修正: 1600px から 1920px に変更 ★★★
  const int PERSPECTIVE_WIDTH = 1920; 
  
  try {
    for (var path in imageFilePaths) {
      final file = File(path);
      final rawBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(rawBytes);

      if (originalImage == null) continue;

      // ★★★ 修正: 幅1920pxにリサイズし、高さは元の画像のアスペクト比を維持する ★★★
      img.Image normalizedImage = img.copyResize(
        originalImage,
        width: PERSPECTIVE_WIDTH,
        height: (originalImage.height * (PERSPECTIVE_WIDTH / originalImage.width)).round(),
      );

      // ★★★ 追加: シャープニングフィルターを適用して文字のエッジを強調 ★★★
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
  
  // 3. マスクテンプレートの決定 (既存ロジック)
  String template;
  switch (selectedCompany) {
    case 'T社':
      template = 't';
      break;
    case 'マスク処理なし':
      template = 'none';
      break;
    case '動的マスク処理':
      template = 'dynamic';
      break;
    default:
      if(context.mounted) {
        _showErrorDialog(context, 'テンプレートエラー', '無効な会社名が選択されました。');
      }
      return null;
  }

  // 4. 1枚目のみマスクプレビュー/確定 (既存ロジック)
  final Uint8List firstImageBytes = rawImageBytesList.first;
  
  if (!context.mounted) return null;
  _showLoadingDialog(context, 'プレビューを準備中...');
  if(context.mounted) _hideLoadingDialog(context);

  final Uint8List? finalMaskedFirstImageBytes =
      await Navigator.push<Uint8List>(
    context,
    MaterialPageRoute(
      builder: (_) => ProductListMaskPreviewPage(
        previewImageBytes: firstImageBytes,
        maskTemplate: template,
        imageIndex: 1, // 1枚目として表示
        totalImages: rawImageBytesList.length,
      ),
    ),
  );
  
  if (finalMaskedFirstImageBytes == null) {
      if(context.mounted) showCustomSnackBar(context, 'マスク確認が破棄されたため、OCR処理を中断しました。');
      return null;
  }
  
  // 5. 全ての画像に確定したマスク処理を適用 (既存ロジック)
  List<Uint8List> finalImagesToSend = [];
  finalImagesToSend.add(finalMaskedFirstImageBytes); // 1枚目はユーザーが確認したものを使用

  for (int i = 1; i < rawImageBytesList.length; i++) {
    if(context.mounted) _showLoadingDialog(context, '画像を準備中... (${i + 1}/${rawImageBytesList.length})');
    final image = img.decodeImage(rawImageBytesList[i])!;
    
    // T社マスクは固定位置であるため、2枚目以降にも適用する
    if (template == 't') {
        final maskedImage = applyMaskToImage(image, template: 't');
        finalImagesToSend.add(Uint8List.fromList(img.encodeJpg(maskedImage, quality: 100)));
    } 
    // 動的マスクは1枚目のみに適用する（プレビュー画面で処理済み）ため、2枚目以降は適用しない（生の画像を使用）
    else {
        finalImagesToSend.add(rawImageBytesList[i]);
    }
  }
  if(context.mounted) _hideLoadingDialog(context);


  // 6. AIへの送信とOCR結果の取得 (既存ロジック)
  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }

  if (!context.mounted) return null;
  // setLoading(true); // ★ 削除
  showCustomSnackBar(context, '${finalImagesToSend.length} 枚の画像をGeminiへ送信依頼しました...');
  FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_GEMINI_START', '${finalImagesToSend.length} images sent to Gemini.');

  final client = http.Client();
  
  List<Future<Map<String, dynamic>?>> aiResultFutures = [];
  for (final imageBytes in finalImagesToSend) {
    final future = sendImageToGemini(
      imageBytes,
      isProductList: true,
      company: selectedCompany,
      client: client,
    ).catchError((e, s) {
      _logError('GEMINI_API', 'Gemini API call failed', e, s);
      return null;
    });
    aiResultFutures.add(future);
  }

  final List<Map<String, dynamic>?> allAiRawResults = await Future.wait(aiResultFutures);
  client.close();

  List<Map<String, String>> allExtractedProductRows = [];
  const List<String> expectedProductFields = ProductListOcrConfirmPage.productFields;

  for(final result in allAiRawResults){
     if (result != null && result.containsKey('products') && result['products'] is List) {
        final List<dynamic> productListRaw = result['products'];
        String commonOrderNo = result['commonOrderNo']?.toString() ?? '';
        for (final item in productListRaw) {
          if (item is Map) {
            Map<String, String> row = {};
            final String remarks = item['備考']?.toString() ?? '';
            String finalOrderNo = commonOrderNo;
            if (commonOrderNo.isNotEmpty && remarks.isNotEmpty) {
              final lastSeparatorIndex = commonOrderNo.lastIndexOf(RegExp(r'[\s-]'));
              if (lastSeparatorIndex != -1) {
                final prefix = commonOrderNo.substring(0, lastSeparatorIndex + 1);
                finalOrderNo = '$prefix$remarks';
              } else {
                finalOrderNo = '$commonOrderNo $remarks';
              }
            }
            for (String field in expectedProductFields) {
              row[field] = (field == 'ORDER No.') ? finalOrderNo : item[field]?.toString() ?? '';
            }
            allExtractedProductRows.add(row);
          }
        }
      } else {
        FlutterLogs.logWarning('OCR_ACTION', 'PRODUCT_LIST_GEMINI_PARSE_FAIL', 'Gemini response structure unexpected.');
        debugPrint('製品リストの解析に失敗した応答がありました (予期せぬ形式)。');
      }
  }
  
  if (!context.mounted) {
    // setLoading(false); // ★ 削除
    return null;
  }
  // setLoading(false); // ★ 削除

  // 6. 確認画面へ
  if (allExtractedProductRows.isNotEmpty) {
      FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_GEMINI_CONFIRM', '${allExtractedProductRows.length} rows extracted by Gemini for confirmation.');
      return await Navigator.push<List<List<String>>>(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListOcrConfirmPage(extractedProductRows: allExtractedProductRows),
        ),
      );
  } else {
      _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_NO_RESULT', 'No valid product list data extracted by Gemini.', null);
      if (context.mounted) _showErrorDialog(context, 'OCR結果なし', '有効な製品リストデータが抽出されませんでした。');
      return null;
  }
}