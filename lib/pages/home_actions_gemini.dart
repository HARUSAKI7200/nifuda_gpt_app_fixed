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
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/gemini_service.dart';
import '../utils/ocr_masker.dart';
import 'camera_capture_page.dart';
import 'nifuda_ocr_confirm_page.dart';
import 'product_list_ocr_confirm_page.dart';
import 'product_list_mask_preview_page.dart';
import '../widgets/custom_snackbar.dart';
import 'streaming_progress_dialog.dart';
import '../utils/keyword_detector.dart';
import '../database/app_database.dart'; 
import '../utils/prompt_definitions.dart';

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

Future<List<List<String>>?> captureProcessAndConfirmProductListActionGemini(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading,
  String projectFolderPath,
  AppDatabase db, 
) async {
  
  List<String> imageFilePaths = [];
  String? promptIdToUse; 
  
  try {
    final options = DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full,
      pageLimit: 100,
      isGalleryImport: true,
    );

    final documentScanner = DocumentScanner(options: options);
    final result = await documentScanner.scanDocument();

    if (result.images.isEmpty) {
      if (context.mounted) showCustomSnackBar(context, '製品リストのスキャンがキャンセルされました。');
      return null;
    }
    imageFilePaths = result.images;

  } catch (e, s) {
    _logError('DOC_SCANNER', 'Scanner launch error (ML Kit/Gemini)', e, s);
    if (context.mounted) _showErrorDialog(context, 'スキャナ起動エラー', 'ML Kit Document Scannerの起動に失敗しました: $e');
    return null;
  }

  if (context.mounted) _showLoadingDialog(context, '画像を処理中...');

  List<String> processedImagePaths = [];
  try {
    final tempDir = await getTemporaryDirectory();
    final redactionKeywords = [
      '東芝', '東芝エネルギーシステムズ', '東芝インフラシステムズ', '東芝エレベータ',
      '東芝プラントシステム', '東芝インフラテクノサービス', '東芝システムテクノロジー',
      '東芝ITコントロールシステム', '東芝EIコントロールシステム', '東芝ディーエムエス',
      'TMEIC', '東芝三菱電機産業システム',
    ];

    List<Rect> customRelativeRects = [];
    if (selectedCompany != 'マスク処理なし' && selectedCompany != '動的マスク処理') {
      try {
        final profile = await db.maskProfilesDao.getProfileByName(selectedCompany);
        if (profile != null) {
          promptIdToUse = profile.promptId;
          
          final List<dynamic> list = jsonDecode(profile.rectsJson);
          customRelativeRects = list.map((s) {
            final parts = s.toString().split(',');
            return Rect.fromLTWH(
              double.parse(parts[0]), double.parse(parts[1]), 
              double.parse(parts[2]), double.parse(parts[3])
            );
          }).toList();
        }
      } catch (e) {
        if (kDebugMode) print('Mask profile load error: $e');
      }
    }

    for (int i = 0; i < imageFilePaths.length; i++) {
      final originalPath = imageFilePaths[i];
      final originalFile = File(originalPath);
      final rawBytes = await originalFile.readAsBytes();
      
      img.Image? imageObj = img.decodeImage(rawBytes);
      if (imageObj == null) continue;

      String internalTemplateName = 'none';
      if (selectedCompany == '動的マスク処理') internalTemplateName = 'dynamic';

      if (internalTemplateName == 'dynamic') {
        final rects = await KeywordDetector.detectKeywords(originalPath, redactionKeywords);
        if (rects.isNotEmpty) {
           imageObj = applyMaskToImage(imageObj, template: 'dynamic', dynamicMaskRects: rects);
        }
      } else if (customRelativeRects.isNotEmpty) {
        imageObj = applyMaskToImage(imageObj, relativeMaskRects: customRelativeRects);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = '${tempDir.path}/processed_scan_gemini_$i\_$timestamp.png';
      await File(savedPath).writeAsBytes(img.encodePng(imageObj));
      processedImagePaths.add(savedPath);
    }
  } catch (e, s) {
    _logError('IMAGE_PROC', 'Background Masking Error (Gemini)', e, s);
    if (context.mounted) {
      _hideLoadingDialog(context);
      _showErrorDialog(context, '画像処理エラー', '画像のマスク処理中にエラーが発生しました: $e');
    }
    return null;
  } finally {
    if (context.mounted) _hideLoadingDialog(context);
  }

  if (processedImagePaths.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '有効な画像がありませんでした。');
    return null;
  }

  unawaited(_saveScannedProductImages(context, projectFolderPath, processedImagePaths));

  if (context.mounted) _showLoadingDialog(context, 'プレビューを準備中...');

  Uint8List firstImageBytes;
  
  try {
    final path = processedImagePaths.first;
    final file = File(path);
    final rawBytes = await file.readAsBytes();
    firstImageBytes = rawBytes;

  } catch (e, s) {
    _logError('IMAGE_PROC', 'Preview Load Error (Gemini)', e, s);
    if (context.mounted) {
      _hideLoadingDialog(context);
      _showErrorDialog(context, 'エラー', 'プレビュー画像の読み込みに失敗しました。');
    }
    return null;
  } finally {
     if (context.mounted) _hideLoadingDialog(context);
  }

  if (!context.mounted) return null;

  final MaskPreviewResult? previewResult = await Navigator.push<MaskPreviewResult>(
    context, MaterialPageRoute(builder: (_) => ProductListMaskPreviewPage(
      previewImageBytes: firstImageBytes,
      maskTemplate: 'none', 
      imageIndex: 1,
      totalImages: processedImagePaths.length,
    )),
  );

  if (previewResult == null) {
      if(context.mounted) showCustomSnackBar(context, '処理を中断しました。');
      return null;
  }

  List<Uint8List> finalImagesToSend = [previewResult.imageBytes];

  if (processedImagePaths.length > 1) {
    if (context.mounted) _showLoadingDialog(context, '画像を準備中... (2/${processedImagePaths.length})');
    try {
      for (int i = 1; i < processedImagePaths.length; i++) {
        if (!context.mounted) break;
        if(i > 1 && context.mounted) {
            Navigator.pop(context);
           _showLoadingDialog(context, '画像を準備中... (${i + 1}/${processedImagePaths.length})');
        }

        final path = processedImagePaths[i];
        final file = File(path);
        final rawBytes = await file.readAsBytes();
        finalImagesToSend.add(rawBytes);
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
  
  final String actualPromptId = promptIdToUse ?? 'standard';

  for (int i = 0; i < finalImagesToSend.length; i++) {
      if (!context.mounted) break;
      final imageBytes = finalImagesToSend[i];

      final Stream<String> stream = sendImageToGeminiStream(
        imageBytes,
        promptId: actualPromptId,
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
          return allAiRawResults.isNotEmpty ? await _processRawProductResultsGemini(context, allAiRawResults, actualPromptId) : null;
      }

      if (kDebugMode) {
        debugPrint('================= [Gemini Product List Raw Response (${i + 1})] =================');
        debugPrint(rawJsonResponse);
        debugPrint('===========================================================================');
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
  return _processRawProductResultsGemini(context, allAiRawResults, actualPromptId);
}


Future<List<List<String>>?> _processRawProductResultsGemini(
  BuildContext context,
  List<Map<String, dynamic>?> allAiRawResults,
  String promptId, 
) async {
  List<Map<String, String>> allExtractedProductRows = [];
  
  final definition = PromptRegistry.getById(promptId);
  final List<String> expectedProductFields = definition.displayFields;

  for(final result in allAiRawResults){
     if (result != null && result.containsKey('products') && result['products'] is List) {
        final List<dynamic> productListRaw = result['products'];
        String commonOrderNo = result['commonOrderNo']?.toString() ?? '';

        for (final item in productListRaw) {
          if (item is Map) {
            Map<String, String> row = {};
            String finalOrderNo = '';
            String finalItemNo = '';

            switch (definition.type) {
              case PromptType.tmeic:
                final String note = item['備考(NOTE)']?.toString() ?? '';
                finalOrderNo = '$commonOrderNo $note'.trim();
                break;

              case PromptType.tmeic_ups_2:
                final trimmedCommon = commonOrderNo.trim();
                final splitIndex = trimmedCommon.indexOf(RegExp(r'\s+'));
                if (splitIndex != -1) {
                  finalOrderNo = trimmedCommon.substring(0, splitIndex);
                  finalItemNo = trimmedCommon.substring(splitIndex).trim();
                } else {
                  finalOrderNo = trimmedCommon;
                }
                break;

              case PromptType.fullRow:
                finalOrderNo = item['ORDER No.']?.toString() ?? item['製番']?.toString() ?? '';
                break;

              case PromptType.standard:
              default:
                final String remarks = item['備考(REMARKS)']?.toString() ?? '';
                finalOrderNo = commonOrderNo;
                if (commonOrderNo.isNotEmpty && remarks.isNotEmpty) {
                   if (commonOrderNo.endsWith('-') || commonOrderNo.endsWith(' ')) {
                       finalOrderNo = '$commonOrderNo$remarks'; 
                   } else {
                       finalOrderNo = '$commonOrderNo $remarks';
                   }
                }
                break;
            }

            for (String field in expectedProductFields) {
              if ((field == 'ORDER No.' || field == '製番') && finalOrderNo.isNotEmpty) {
                row[field] = finalOrderNo;
              } 
              else if ((field == 'ITEM OF SPARE' || field == '項番') && finalItemNo.isNotEmpty) {
                row[field] = finalItemNo;
              }
              else {
                row[field] = item[field]?.toString() ?? '';
              }
            }
            allExtractedProductRows.add(row);
          }
        }
      }
  }

  if (allExtractedProductRows.isNotEmpty) {
      final List<List<String>>? confirmedRows = await Navigator.push<List<List<String>>>(
        context,
        MaterialPageRoute(builder: (_) => ProductListOcrConfirmPage(
          extractedProductRows: allExtractedProductRows,
          displayFields: expectedProductFields,
        )),
      );

      if (confirmedRows != null && confirmedRows.isNotEmpty) {
        return confirmedRows; 
      }
      return null;
  } else {
      _logError('OCR_ACTION', 'PRODUCT_LIST_GEMINI_NO_RESULT', 'No valid product list data extracted by Gemini after processing.', null);
      if (context.mounted) _showErrorDialog(context, 'OCR結果なし', '有効な製品リストデータが抽出されませんでした。');
      return null;
  }
}