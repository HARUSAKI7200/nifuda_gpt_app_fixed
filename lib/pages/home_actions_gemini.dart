// lib/pages/home_actions_gemini.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_logs/flutter_logs.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import '../utils/gemini_service.dart';
import '../utils/ocr_masker.dart';
import 'camera_capture_page.dart';
import 'nifuda_ocr_confirm_page.dart';
import 'product_list_ocr_confirm_page.dart';
import 'product_list_mask_preview_page.dart';
import '../widgets/custom_snackbar.dart';
import 'streaming_progress_dialog.dart';

// --- Utility Functions (home_actions.dartと同様のプライベート関数) ---
void _logError(String tag, String subTag, Object error, StackTrace? stack) {
  FlutterLogs.logThis(
    tag: tag,
    subTag: subTag,
    logMessage: stack == null ? error.toString() : '${error.toString()}\n$stack',
    exception: (error is Exception) ? error : Exception(error.toString()),
    level: LogLevel.ERROR,
  );
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

// ★★★ captureProcessAndConfirmNifudaActionGemini (自作カメラ+バックグラウンド処理版) ★★★
Future<List<List<String>>?> captureProcessAndConfirmNifudaActionGemini(
    BuildContext context,
    String projectFolderPath,
    String currentCaseNumber,
) async {
  // 1. 自作カメラで撮影＆裏処理
  final List<Map<String, dynamic>>? processedResults = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CameraCapturePage(
        overlayText: '荷札を撮影 (Gemini)',
        isProductListOcr: false,
        projectFolderPath: projectFolderPath,
        caseNumber: currentCaseNumber,
        aiService: sendImageToGemini, 
    )),
  );

  if (processedResults == null || processedResults.isEmpty) {
    if (context.mounted) showCustomSnackBar(context, '荷札の撮影がキャンセルされました。');
    return null;
  }

  // 2. 結果を順次確認
  List<List<String>> allConfirmedNifudaRows = [];
  int imageIndex = 0;

  for (final result in processedResults) {
    imageIndex++;
    if (!context.mounted) break;

    final Map<String, dynamic>? confirmedResultMap = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NifudaOcrConfirmPage(
          extractedData: result,
          imageIndex: imageIndex,
          totalImages: processedResults.length,
        ),
      ),
    );

    if (confirmedResultMap != null) {
      List<String> confirmedRowAsList = NifudaOcrConfirmPage.nifudaFields
          .map((field) => confirmedResultMap[field]?.toString() ?? '')
          .toList();
      allConfirmedNifudaRows.add(confirmedRowAsList);
    } else {
      if (context.mounted && imageIndex < processedResults.length) {
         final proceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
                  title: Text('$imageIndex枚目の確認が破棄されました'),
                  content: const Text('次の確認に進みますか？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('いいえ')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('はい')),
                  ],
                ));
        if (proceed != true) break;
      }
    }
  }

  if (allConfirmedNifudaRows.isNotEmpty) {
     return allConfirmedNifudaRows;
  } else {
    if (context.mounted) showCustomSnackBar(context, '有効な荷札データがありませんでした。');
    return null;
  }
}

// ★★★ captureProcessAndConfirmProductListActionGemini (リサイズ撤廃修正済み) ★★★
Future<List<List<String>>?> captureProcessAndConfirmProductListActionGemini(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading,
  String projectFolderPath,
) async {
  List<String>? imageFilePaths;
  try {
    final options = DocumentScannerOptions(
      pageLimit: 100,
      isGalleryImport: false,
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full
    );
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

  // unawaited(_saveScannedProductImages(context, projectFolderPath, imageFilePaths));

  if (context.mounted) _showLoadingDialog(context, 'プレビューを準備中... (1/${imageFilePaths.length})');

  Uint8List firstImageBytes;
  
  // リサイズ処理を削除

  try {
    final path = imageFilePaths.first;
    final file = File(path);
    final rawBytes = await file.readAsBytes();
    final originalImage = img.decodeImage(rawBytes);
    
    if (originalImage == null) {
      if (context.mounted) _hideLoadingDialog(context);
      _showErrorDialog(context, '画像処理エラー', '1枚目の画像をデコードできませんでした。');
      return null;
    }
    
    // 元画像をそのまま最高画質でエンコード
    firstImageBytes = Uint8List.fromList(img.encodeJpg(originalImage, quality: 100));

  } catch (e, s) {
    _logError('IMAGE_PROC', 'Image read/resize error (Gemini First Image)', e, s);
    if (context.mounted) _hideLoadingDialog(context);
    if (context.mounted) _showErrorDialog(context, '画像処理エラー', 'スキャン済みファイルの読み込みまたはエンコードに失敗しました: $e');
    return null;
  } finally {
     if (context.mounted) _hideLoadingDialog(context);
  }


  String template;
  switch (selectedCompany) {
    case 'T社': template = 't'; break;
    case 'マスク処理なし': template = 'none'; break;
    case '動的マスク処理': template = 'dynamic'; break;
    default: if(context.mounted) _showErrorDialog(context, 'テンプレートエラー', '無効な会社名が選択されました。'); return null;
  }

  if (!context.mounted) return null;

  final MaskPreviewResult? previewResult = await Navigator.push<MaskPreviewResult>(
    context, MaterialPageRoute(builder: (_) => ProductListMaskPreviewPage(
      previewImageBytes: firstImageBytes,
      maskTemplate: template,
      imageIndex: 1,
      totalImages: imageFilePaths!.length, 
    )),
  );

  if (previewResult == null) {
      if(context.mounted) showCustomSnackBar(context, 'マスク確認が破棄されたため、OCR処理を中断しました。');
      return null;
  }

  final List<Rect> dynamicMasks = previewResult.dynamicMasks;

  List<Uint8List> finalImagesToSend = [previewResult.imageBytes];
  if (imageFilePaths.length > 1) {
    if (context.mounted) _showLoadingDialog(context, '画像を準備中... (2/${imageFilePaths.length})');
    try {
      for (int i = 1; i < imageFilePaths.length; i++) {
        if (!context.mounted) break;
        if(i > 1 && context.mounted) {
            Navigator.pop(context);
           _showLoadingDialog(context, '画像を準備中... (${i + 1}/${imageFilePaths.length})');
        }

        final path = imageFilePaths[i];
        final file = File(path);
        final rawBytes = await file.readAsBytes();
        final originalImage = img.decodeImage(rawBytes);
        
        if (originalImage == null) continue;

        img.Image maskedImage;
        if (template == 't') {
            maskedImage = applyMaskToImage(originalImage, template: 't'); 
        } else if (template == 'dynamic' && dynamicMasks.isNotEmpty) {
            maskedImage = applyMaskToImage(originalImage, template: 'dynamic', dynamicMaskRects: dynamicMasks); 
        } else {
            maskedImage = originalImage; 
        }
        finalImagesToSend.add(Uint8List.fromList(img.encodeJpg(maskedImage, quality: 100)));
      }
    } finally {
       if (context.mounted) _hideLoadingDialog(context);
    }
  }

  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }

  List<Map<String, dynamic>?> allAiRawResults = [];
  final String companyForGemini = (selectedCompany == 'T社') ? 'TMEIC' : selectedCompany;

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
          _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_STREAM_FAIL', 'Gemini stream failed or cancelled for image ${i + 1}', null);
          if (context.mounted) _showErrorDialog(context, '抽出エラー', '${i + 1}枚目の画像の抽出に失敗しました。処理を中断します。');
          return allAiRawResults.isNotEmpty ? await _processRawProductResultsGemini(context, allAiRawResults, selectedCompany) : null;
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
          FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_GEMINI_PARSE_OK', 'Successfully parsed Gemini response for image ${i + 1}');
      } catch (e, s) {
          _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_PARSE_FAIL', 'Failed to parse Gemini JSON for image ${i + 1}: ${rawJsonResponse}', s);
          allAiRawResults.add(null);
      }
  }

  if (!context.mounted) return null;
  return _processRawProductResultsGemini(context, allAiRawResults, selectedCompany);
}


// ★★★ _processRawProductResultsGemini (変更なし) ★★★
Future<List<List<String>>?> _processRawProductResultsGemini(
  BuildContext context,
  List<Map<String, dynamic>?> allAiRawResults,
  String selectedCompany,
) async {
  List<Map<String, String>> allExtractedProductRows = [];
  const List<String> expectedProductFields = ProductListOcrConfirmPage.productFields;

  final bool isTCompany = (selectedCompany == 'T社');

  for(final result in allAiRawResults){
     if (result != null && result.containsKey('products') && result['products'] is List) {
        final List<dynamic> productListRaw = result['products'];
        String commonOrderNo = result['commonOrderNo']?.toString() ?? '';

        for (final item in productListRaw) {
          if (item is Map) {
            Map<String, String> row = {};
            String finalOrderNo = '';

            if (isTCompany) {
              final String note = item['備考(NOTE)']?.toString() ?? '';
              finalOrderNo = '$commonOrderNo $note'.trim();
            } else {
              final String remarks = item['備考(REMARKS)']?.toString() ?? '';
              finalOrderNo = commonOrderNo;

              if (commonOrderNo.isNotEmpty && remarks.isNotEmpty) {
                 if (commonOrderNo.endsWith('-') || commonOrderNo.endsWith(' ')) {
                     finalOrderNo = '$commonOrderNo$remarks'; 
                 } else {
                     finalOrderNo = '$commonOrderNo $remarks';
                 }
              }
            }

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
        context,
        MaterialPageRoute(builder: (_) => ProductListOcrConfirmPage(extractedProductRows: allExtractedProductRows)),
      );
  } else {
      _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_NO_RESULT', 'No valid product list data extracted by Gemini after processing.', null);
      if (context.mounted) _showErrorDialog(context, 'OCR結果なし', '有効な製品リストデータが抽出されませんでした。');
      return null;
  }
}