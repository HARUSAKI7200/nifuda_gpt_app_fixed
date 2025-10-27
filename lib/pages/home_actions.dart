// lib/pages/home_actions.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter_logs/flutter_logs.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart'; 
import 'package:media_scanner/media_scanner.dart'; 

import '../utils/gpt_service.dart';
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
// ★ 修正: ProjectLoadDialog (Drift版) をインポート
import 'project_load_dialog.dart'; 
import 'streaming_progress_dialog.dart';
import '../utils/gemini_service.dart'; 

// --- Constants ---
const String BASE_PROJECT_DIR = "/storage/emulated/0/DCIM/検品関係";

// --- Utility Functions (省略) ---
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


// ★★★ _saveScannedProductImages (変更なしのため省略) ★★★
Future<void> _saveScannedProductImages(
    BuildContext context,
    String projectFolderPath,
    List<String> sourceImagePaths) async {
  if (!Platform.isAndroid) {
    debugPrint("この画像保存方法はAndroid専用です。");
    return;
  }
  try {
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

// ★★★ saveProjectAction (変更なし) ★★★
// (これはDB保存ではなく「JSONエクスポート」機能として home_page.dart で使われ続ける)
Future<String?> saveProjectAction(
  BuildContext context,
  String currentProjectFolderPath,
  String projectTitle,
  List<List<String>> nifudaData,
  List<List<String>> productListKariData,
) async {
  try {
    final now = DateTime.now();
    final timestamp = _formatTimestampForFilename(now); 
    final fileName = '$projectTitle\_$timestamp.json';

    final saveDirPath = p.join(currentProjectFolderPath, 'SAVES');
    final saveDir = Directory(saveDirPath);

    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    final saveFilePath = p.join(saveDirPath, fileName);
    final file = File(saveFilePath);

    final projectData = {
      'projectTitle': projectTitle,
      'projectFolderPath': currentProjectFolderPath,
      'nifudaData': nifudaData,
      'productListKariData': productListKariData,
    };

    final jsonString = jsonEncode(projectData);
    await file.writeAsString(jsonString);

    if (context.mounted) {
      showCustomSnackBar(context, 'プロジェクトを $fileName に保存しました。', durationSeconds: 3);
      FlutterLogs.logInfo('PROJECT_ACTION', 'SAVE_SUCCESS', 'Project $projectTitle saved to $saveFilePath');
    }

    return saveFilePath;
  } catch (e, s) {
    _logError('PROJECT_ACTION', 'SAVE_ERROR', e, s);
    if (context.mounted) {
      showCustomSnackBar(context, 'プロジェクトの保存に失敗しました: $e', isError: true);
    }
    return null;
  }
}

// ★★★ 修正: loadProjectAction (JSON読み込み) ★★★
// home_page.dart からは呼ばれなくなったが、コンパイルエラーを解消するために
// ProjectLoadDialog.show() の呼び出しを修正する。
// (もしくはこの関数全体を削除しても良い)
Future<Map<String, dynamic>?> loadProjectAction(BuildContext context) async {
  final baseDir = Directory(BASE_PROJECT_DIR);

  if (!await baseDir.exists()) {
    if (context.mounted) showCustomSnackBar(context, 'プロジェクトの保存フォルダが見つかりませんでした。', isError: true);
    return null;
  }

  // ★ 修正: ProjectLoadDialog (Drift版) は引数を取らない。
  // このJSON読み込み機能は事実上DB版に置き換えられたため、
  // この関数は「古いJSONを読み込む」という目的でもはや機能しない。
  // コンパイルを通すため、呼び出し自体をコメントアウトする。
  
  // final Map<String, String>? selectedFile = await ProjectLoadDialog.show(context, BASE_PROJECT_DIR); // <-- エラー箇所
  
  if (context.mounted) {
    _showErrorDialog(context, '機能が変更されました', 'プロジェクトの読み込みは「DBから読み込み」ボタンを使用してください。\n\n（古いJSONバックアップファイルを読み込む機能は現在サポートされていません）');
  }
  return null;

  /* --- 以下、古いJSON読み込みロジック (到達不能) ---
  if (selectedFile == null) {
    if (context.mounted) showCustomSnackBar(context, 'プロジェクトの読み込みがキャンセルされました。');
    return null;
  }
  final filePath = selectedFile['filePath']!;
  final projectTitle = selectedFile['projectTitle']!;
  final projectFolderPath = selectedFile['projectFolderPath']!;
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('選択されたファイルが見つかりません。');
    }
    final jsonString = await file.readAsString();
    final Map<String, dynamic> loadedData = jsonDecode(jsonString) as Map<String, dynamic>;
    if (loadedData['projectTitle'] == null ||
        loadedData['nifudaData'] is! List ||
        loadedData['productListKariData'] is! List) {
      throw Exception('ファイルの構造が不正です。');
    }
    if (context.mounted) {
      showCustomSnackBar(context, 'プロジェクト「$projectTitle」を読み込みました。', durationSeconds: 3);
      FlutterLogs.logInfo('PROJECT_ACTION', 'LOAD_SUCCESS', 'Project $projectTitle loaded from $filePath');
    }
    return {
      'projectTitle': projectTitle,
      'currentProjectFolderPath': projectFolderPath,
      'nifudaData': (loadedData['nifudaData'] as List).map((e) => List<String>.from(e)).toList(),
      'productListKariData': (loadedData['productListKariData'] as List).map((e) => List<String>.from(e)).toList(),
    };
  } catch (e, s) {
    _logError('PROJECT_ACTION', 'LOAD_ERROR', e, s);
    if (context.mounted) {
      _showErrorDialog(context, '読み込みエラー', 'プロジェクトファイルの読み込みに失敗しました: $e');
    }
    return null;
  }
  */
}


// ★★★ captureProcessAndConfirmNifudaAction (変更なし) ★★★
Future<List<List<String>>?> captureProcessAndConfirmNifudaAction(BuildContext context, String projectFolderPath) async {
  final List<Map<String, dynamic>>? allGptResults =
      await Navigator.push<List<Map<String, dynamic>>>(
    context,
    MaterialPageRoute(builder: (_) => CameraCapturePage(
        overlayText: '荷札を枠に合わせて撮影',
        isProductListOcr: false,
        projectFolderPath: projectFolderPath,
        aiService: sendImageToGPT,
    )),
  );
  if (allGptResults == null || allGptResults.isEmpty) {
    if (context.mounted) {
      showCustomSnackBar(context, '荷札の撮影またはOCR処理がキャンセルされました。');
      FlutterLogs.logThis(
        tag: 'OCR_ACTION',
        subTag: 'NIFUDA_CANCEL',
        logMessage: 'Nifuda OCR was cancelled by user.',
        level: LogLevel.WARNING,
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  List<List<String>> allConfirmedNifudaRows = [];
  int imageIndex = 0;
  for (final gptResult in allGptResults) {
    imageIndex++;
    if (!context.mounted) break;
    if (context.mounted) _showLoadingDialog(context, '$imageIndex / ${allGptResults.length} 枚目の結果を確認中...');
    final Map<String, dynamic>? confirmedResultMap = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => NifudaOcrConfirmPage(
          extractedData: gptResult,
          imageIndex: imageIndex,
          totalImages: allGptResults.length,
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
             subTag: 'NIFUDA_CONFIRM_INTERRUPTED',
             logMessage: 'Nifuda confirmation interrupted after $imageIndex images.',
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
     FlutterLogs.logInfo('OCR_ACTION', 'NIFUDA_CONFIRM_SUCCESS', '${allConfirmedNifudaRows.length} Nifuda rows confirmed.');
     return allConfirmedNifudaRows;
  } else {
    if (context.mounted) showCustomSnackBar(context, '有効な荷札データが1件も確定されませんでした。');
    return null;
  }
}

// ★★★ showAndExportNifudaListAction (変更なし) ★★★
void showAndExportNifudaListAction(
  BuildContext context,
  List<List<String>> nifudaData,
  String projectTitle,
  String projectFolderPath,
) {
    if (nifudaData.length <= 1) {
    _showErrorDialog(context, 'データなし', '表示する荷札データがありません。');
    return;
  }
  showDialog(
    context: context,
    builder: (_) => ExcelPreviewDialog(
      title: '荷札リスト',
      data: nifudaData,
      headers: nifudaData.first,
      projectFolderPath: projectFolderPath,
      subfolder: '荷札リスト',
    ),
  );
}

// ★★★ captureProcessAndConfirmProductListAction (変更なし) ★★★
Future<List<List<String>>?> captureProcessAndConfirmProductListAction(
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
    _logError('DOC_SCANNER', 'Scanner launch error (GPT)', e, s);
    if (context.mounted) _showErrorDialog(context, 'スキャナ起動エラー', 'Google ML Kit Document Scannerの起動に失敗しました: $e');
    return null;
  }

  if (imageFilePaths == null || imageFilePaths.isEmpty) {
    if (context.mounted) showCustomSnackBar(context, '製品リストのスキャンがキャンセルされました。');
    return null;
  }

  unawaited(_saveScannedProductImages(context, projectFolderPath, imageFilePaths));

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
    _logError('IMAGE_PROC', 'Image read/resize error', e, s);
    if (context.mounted) _showErrorDialog(context, '画像処理エラー', 'スキャン済みファイルの読み込みまたはリサイズに失敗しました: $e');
    return null; 
  }
  if (rawImageBytesList.isEmpty) {
      if(context.mounted) _showErrorDialog(context, '画像処理エラー', '有効な画像が読み込めませんでした。');
      return null;
  }

  String template;
  switch (selectedCompany) {
    case 'T社': template = 't'; break;
    case 'マスク処理なし': template = 'none'; break;
    case '動的マスク処理': template = 'dynamic'; break;
    default: if(context.mounted) _showErrorDialog(context, 'テンプレートエラー', '無効な会社名が選択されました。'); return null;
  }
  final Uint8List firstImageBytes = rawImageBytesList.first;
  if (!context.mounted) return null;

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

  List<Uint8List> finalImagesToSend = [previewResult.imageBytes]; 
  if (rawImageBytesList.length > 1) {
    if (context.mounted) _showLoadingDialog(context, '画像を準備中... (2/${rawImageBytesList.length})');
    try {
      for (int i = 1; i < rawImageBytesList.length; i++) {
        if (!context.mounted) break; 
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
       if (context.mounted) _hideLoadingDialog(context); 
    }
  }

  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }

  List<Map<String, dynamic>?> allAiRawResults = [];
  final String companyForGpt = (selectedCompany == 'T社') ? 'TMEIC' : selectedCompany; 

  for (int i = 0; i < finalImagesToSend.length; i++) {
      if (!context.mounted) break;
      final imageBytes = finalImagesToSend[i];

      final Stream<String> stream = sendImageToGPTStream(
        imageBytes,
        company: companyForGpt,
      );

      final String streamTitle = '製品リスト抽出中 (GPT) (${i + 1} / ${finalImagesToSend.length})';
      final String? rawJsonResponse = await StreamingProgressDialog.show(
        context: context,
        stream: stream,
        title: streamTitle,
        serviceTag: 'GPT_SERVICE'
      );

      if (rawJsonResponse == null) {
          _logError('OCR_ACTION', 'PRODUCT_LIST_GPT_STREAM_FAIL', 'Stream failed or cancelled for image ${i + 1}', null);
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
          FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_GPT_PARSE_OK', 'Successfully parsed response for image ${i + 1}');
      } catch (e, s) {
          _logError('OCR_ACTION', 'PRODUCT_LIST_GPT_PARSE_FAIL', 'Failed to parse JSON for image ${i + 1}: ${rawJsonResponse}', s);
          allAiRawResults.add(null); 
      }
  }

  if (!context.mounted) return null; 
  return _processRawProductResults(context, allAiRawResults, selectedCompany);
}

// ★★★ _processRawProductResults (変更なし) ★★★
Future<List<List<String>>?> _processRawProductResults(
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
        FlutterLogs.logWarn('OCR_ACTION', 'INVALID_AI_RESULT', 'Received null or invalid AI result structure.');
      }
  }

  if (allExtractedProductRows.isNotEmpty) {
      FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_CONFIRM', '${allExtractedProductRows.length} rows extracted for confirmation.');
      return Navigator.push<List<List<String>>>(
        context, MaterialPageRoute(builder: (_) => ProductListOcrConfirmPage(extractedProductRows: allExtractedProductRows)),
      );
  } else {
      _logError('OCR_ACTION', 'PRODUCT_LIST_NO_RESULT', 'No valid product list data extracted after processing all images.', null);
      if (context.mounted) _showErrorDialog(context, 'OCR結果なし', '有効な製品リストデータが抽出されませんでした。');
      return null;
  }
}

// ★★★ showAndExportProductListAction (変更なし) ★★★
void showAndExportProductListAction(
  BuildContext context,
  List<List<String>> productListData,
  String projectFolderPath,
) {
    if (productListData.length <= 1) {
    _showErrorDialog(context, 'データなし', '表示する製品リストデータがありません。');
    return;
  }
  showDialog(
    context: context,
    builder: (_) => ExcelPreviewDialog(
      title: '製品リスト',
      data: productListData,
      headers: productListData.first,
      projectFolderPath: projectFolderPath,
      subfolder: '製品リスト',
    ),
  );
}

// ★★★ startMatchingAndShowResultsAction (変更なし) ★★★
Future<String?> startMatchingAndShowResultsAction(
  BuildContext context,
  List<List<String>> nifudaData,
  List<List<String>> productListData,
  String matchingPattern,
  String projectTitle,
  String projectFolderPath,
) async {
  if (nifudaData.length <= 1 || productListData.length <= 1) {
    _showErrorDialog(context, 'データ不足', '照合には荷札と製品リストの両方のデータが必要です。');
    FlutterLogs.logThis(
      tag: 'MATCHING_ACTION',
      subTag: 'DATA_INSUFFICIENT',
      logMessage: 'Matching attempted with insufficient data.',
      level: LogLevel.WARNING,
    );
    return null;
  }
  _showLoadingDialog(context, '照合処理を実行中...');

  final nifudaHeaders = nifudaData.first;
  final nifudaMapList = nifudaData.sublist(1).map((row) {
    return { for (int i = 0; i < nifudaHeaders.length; i++) nifudaHeaders[i]: (i < row.length ? row[i] : '') };
  }).toList();
  final productHeaders = productListData.first;
  final productMapList = productListData.sublist(1).map((row) {
    return { for (int i = 0; i < productHeaders.length; i++) productHeaders[i]: (i < row.length ? row[i] : '') };
  }).toList();
  if (nifudaMapList.isEmpty || productMapList.isEmpty) {
     _hideLoadingDialog(context);
     _showErrorDialog(context, 'データ不足', '荷札または製品リストの有効なデータがありません。');
     FlutterLogs.logThis(
       tag: 'MATCHING_ACTION',
       subTag: 'DATA_EMPTY',
       logMessage: 'Matching failed due to empty map lists.',
       level: LogLevel.WARNING,
     );
    return null;
  }

  final matchingLogic = ProductMatcher();
  final Map<String, dynamic> rawResults = matchingLogic.match(nifudaMapList, productMapList, pattern: matchingPattern);

  _hideLoadingDialog(context);

  FlutterLogs.logInfo('MATCHING_ACTION', 'MATCHING_SUCCESS', 'Matching completed with pattern: $matchingPattern. Matched: ${(rawResults['matched'] as List).length}, Unmatched: ${(rawResults['unmatched'] as List).length}');

  final String? newStatus = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => MatchingResultPage(
        matchingResults: rawResults,
        projectFolderPath: projectFolderPath,
        projectTitle: projectTitle,
        nifudaData: nifudaData,
        productListKariData: productListData,
    )),
  );
  if (context.mounted && newStatus != null) {
    return newStatus;
  }
  return null;
}