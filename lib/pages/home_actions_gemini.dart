// lib/pages/home_actions_gemini.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_logs/flutter_logs.dart';
import 'package:http/http.dart' as http;
// ★ 追加: 不足していたインポート
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';

import '../utils/gemini_service.dart';
import '../utils/ocr_masker.dart';
import 'camera_capture_page.dart';
import 'nifuda_ocr_confirm_page.dart';
import 'product_list_ocr_confirm_page.dart';
import 'product_list_mask_preview_page.dart';
import '../widgets/custom_snackbar.dart';
import 'streaming_progress_dialog.dart';
import 'document_scanner_page.dart';

// --- Utility Functions ---

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

String _formatTimestampForFilename(DateTime dateTime) {
  return '${dateTime.year.toString().padLeft(4, '0')}'
      '${dateTime.month.toString().padLeft(2, '0')}'
      '${dateTime.day.toString().padLeft(2, '0')}_'
      '${dateTime.hour.toString().padLeft(2, '0')}'
      '${dateTime.minute.toString().padLeft(2, '0')}'
      '${dateTime.second.toString().padLeft(2, '0')}';
}

// ★ 追加: 不足していた画像保存関数
Future<void> _saveScannedProductImages(
    BuildContext context,
    String projectFolderPath,
    List<String> sourceImagePaths, {
    bool isNifuda = false, 
    String? caseNumber,    
}) async {
  if (!Platform.isAndroid) return;
  try {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    if (!statuses[Permission.storage]!.isGranted && !statuses[Permission.manageExternalStorage]!.isGranted) {
      throw Exception('ストレージへのアクセス権限がありません。');
    }

    String targetDirPath;
    String fileNamePrefix;
    if (isNifuda && caseNumber != null) {
      targetDirPath = p.join(projectFolderPath, "荷札画像/$caseNumber");
      fileNamePrefix = "nifuda_${caseNumber.replaceAll('#', 'Case_')}";
    } else {
      targetDirPath = p.join(projectFolderPath, "製品リスト画像");
      fileNamePrefix = "product_list";
    }

    final Directory targetDir = Directory(targetDirPath);
    if (!await targetDir.exists()) await targetDir.create(recursive: true);

    for (final sourcePath in sourceImagePaths) {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) continue;
      
      final timestamp = _formatTimestampForFilename(DateTime.now());
      final originalExtension = p.extension(sourcePath);
      final fileName = '${fileNamePrefix}_$timestamp$originalExtension';
      final targetFilePath = p.join(targetDir.path, fileName);

      try {
        await sourceFile.copy(targetFilePath);
        await MediaScanner.loadMedia(path: targetFilePath);
      } catch (e, s) {
        _logError('IMAGE_SAVE', 'COPY_ERROR', e, s);
      }
    }
  } catch (e, s) {
    _logError('IMAGE_SAVE', 'SAVE_PROCESS_ERROR', e, s);
  }
}

// --- Main Actions ---

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

// ★★★ captureProcessAndConfirmProductListActionGemini (OpenCV使用版) ★★★
Future<List<List<String>>?> captureProcessAndConfirmProductListActionGemini(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading,
  String projectFolderPath,
) async {
  
  List<String>? imageFilePaths;
  try {
    // カスタムスキャナーページへ遷移 (マスクテンプレートを渡す)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DocumentScannerPage(
        maxPages: 100,
        maskTemplate: selectedCompany, 
      )),
    );
    if (result is List<String>) {
      imageFilePaths = result;
    }
  } catch (e, s) {
    _logError('DOC_SCANNER', 'Scanner launch error (OpenCV/Gemini)', e, s);
    if (context.mounted) _showErrorDialog(context, 'スキャナ起動エラー', 'Document Scannerの起動に失敗しました: $e');
    return null;
  }

  if (imageFilePaths == null || imageFilePaths.isEmpty) {
    if (context.mounted) showCustomSnackBar(context, '製品リストのスキャンがキャンセルされました。');
    return null;
  }

  // 画像はすでにScannerPage内でマスク処理・保存されている
  unawaited(_saveScannedProductImages(context, projectFolderPath, imageFilePaths));

  if (context.mounted) _showLoadingDialog(context, 'プレビューを準備中... (1/${imageFilePaths!.length})'); // Null安全対応済み

  Uint8List firstImageBytes;
  
  // 1枚目を読み込み
  try {
    final path = imageFilePaths!.first; // Null安全対応済み
    final file = File(path);
    final rawBytes = await file.readAsBytes();
    
    // 画質確認のため、最高画質でエンコード
    final originalImage = img.decodeImage(rawBytes);
    
    if (originalImage == null) {
      if (context.mounted) _hideLoadingDialog(context);
      _showErrorDialog(context, '画像処理エラー', '1枚目の画像をデコードできませんでした。');
      return null;
    }
    
    firstImageBytes = Uint8List.fromList(img.encodeJpg(originalImage, quality: 100));

  } catch (e, s) {
    _logError('IMAGE_PROC', 'Image read/encode error (Gemini First Image)', e, s);
    if (context.mounted) _hideLoadingDialog(context);
    if (context.mounted) _showErrorDialog(context, '画像処理エラー', 'スキャン済みファイルの読み込みに失敗しました: $e');
    return null;
  } finally {
     if (context.mounted) _hideLoadingDialog(context);
  }

  if (!context.mounted) return null;

  // Preview (確認) - 既にマスク済みのため 'none' を指定
  final MaskPreviewResult? previewResult = await Navigator.push<MaskPreviewResult>(
    context, MaterialPageRoute(builder: (_) => ProductListMaskPreviewPage(
      previewImageBytes: firstImageBytes,
      maskTemplate: 'none', 
      imageIndex: 1,
      totalImages: imageFilePaths!.length, // Null安全対応済み
    )),
  );

  if (previewResult == null) {
      if(context.mounted) showCustomSnackBar(context, 'マスク確認が破棄されたため、OCR処理を中断しました。');
      return null;
  }

  final List<Rect> dynamicMasks = previewResult.dynamicMasks;
  
  List<Uint8List> finalImagesToSend = [previewResult.imageBytes];

  // 2枚目以降の処理
  if (imageFilePaths!.length > 1) { // Null安全対応済み
    if (context.mounted) _showLoadingDialog(context, '画像を準備中... (2/${imageFilePaths!.length})'); // Null安全対応済み
    try {
      for (int i = 1; i < imageFilePaths!.length; i++) { // Null安全対応済み
        if (!context.mounted) break;
        if(i > 1 && context.mounted) {
            Navigator.pop(context);
           _showLoadingDialog(context, '画像を準備中... (${i + 1}/${imageFilePaths!.length})'); // Null安全対応済み
        }

        final path = imageFilePaths![i]; // Null安全対応済み
        final file = File(path);
        final rawBytes = await file.readAsBytes();
        
        // 処理済み画像をそのままロード
        final originalImage = img.decodeImage(rawBytes);
        if (originalImage != null) {
           finalImagesToSend.add(Uint8List.fromList(img.encodeJpg(originalImage, quality: 100)));
        }
      }
    } finally {
       if (context.mounted) _hideLoadingDialog(context);
    }
  }

  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }

  // --- Gemini送信 ---
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