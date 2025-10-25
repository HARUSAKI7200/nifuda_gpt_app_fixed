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

import '../utils/gemini_service.dart';
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

// 例外ログのユーティリティ（FlutterLogs API準拠）
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

Future<String?> saveProjectAction(
  BuildContext context,
  String projectFolderPath,
  String projectTitle,
  List<List<String>> nifudaData,
  List<List<String>> productListData,
) async {
  if (!context.mounted) return null;
  _showLoadingDialog(context, 'プロジェクトを保存中...');

  try {
    final projectData = {
      'projectTitle': projectTitle,
      'nifudaData': nifudaData,
      'productListKariData': productListData,
    };
    final jsonString = jsonEncode(projectData);
    final filePath = p.join(projectFolderPath, 'project_data.json');
    final file = File(filePath);
    await file.writeAsString(jsonString);
    FlutterLogs.logInfo('PROJECT_ACTION', 'SAVE_SUCCESS', 'Project $projectTitle saved to $filePath');
    if (context.mounted) {
      _hideLoadingDialog(context);
      showCustomSnackBar(context, 'プロジェクト「$projectTitle」を保存しました。');
    }
    return filePath;
  } catch (e, s) {
    _logError('PROJECT_ACTION', 'SAVE_FAIL', e, s);
    if (context.mounted) {
      _hideLoadingDialog(context);
      _showErrorDialog(context, '保存エラー', 'プロジェクトの保存に失敗しました: $e');
    }
    return null;
  }
}

Future<Map<String, dynamic>?> loadProjectAction(BuildContext context) async {
  try {
    const String baseDcimPath = "/storage/emulated/0/DCIM";
    final String inspectionRelatedPath = p.join(baseDcimPath, "検品関係");
    final dir = Directory(inspectionRelatedPath);
    if (!await dir.exists()) {
      if (context.mounted) _showErrorDialog(context, 'フォルダなし', 'プロジェクトフォルダ「検品関係」が見つかりません。');
      return null;
    }
    final projectDirs = (await dir.list().toList())
        .whereType<Directory>()
        .toList();
    if (projectDirs.isEmpty) {
      if (context.mounted) _showErrorDialog(context, 'プロジェクトなし', '保存されたプロジェクトがありません。');
      return null;
    }
    if (!context.mounted) return null;
    final Directory? selectedDir = await showDialog<Directory>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('プロジェクトを選択'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: projectDirs.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(p.basename(projectDirs[index].path)),
                  onTap: () => Navigator.of(dialogContext).pop(projectDirs[index]),
                );
              },
            ),
          ),
        );
      },
    );
    if (selectedDir == null) return null;
    _showLoadingDialog(context, 'プロジェクトを読み込み中...');
    final filePath = p.join(selectedDir.path, 'project_data.json');
    final file = File(filePath);
    if (!await file.exists()) {
      if (context.mounted) {
        _hideLoadingDialog(context);
        _showErrorDialog(context, 'データなし', '選択されたプロジェクトに保存データがありません。');
      }
      return null;
    }
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString);
    final nifudaData = (data['nifudaData'] as List)
        .map((row) => (row as List).map((cell) => cell.toString()).toList())
        .toList();
    final productListKariData = (data['productListKariData'] as List)
        .map((row) => (row as List).map((cell) => cell.toString()).toList())
        .toList();
    final loadedData = {
      'projectTitle': data['projectTitle'] as String,
      'currentProjectFolderPath': selectedDir.path,
      'nifudaData': nifudaData,
      'productListKariData': productListKariData,
    };
    FlutterLogs.logInfo('PROJECT_ACTION', 'LOAD_SUCCESS', 'Project ${loadedData['projectTitle']} loaded.');
    if (context.mounted) {
      _hideLoadingDialog(context);
      showCustomSnackBar(context, 'プロジェクト「${loadedData['projectTitle']}」を読み込みました。');
    }
    return loadedData;
  } catch (e, s) {
    _logError('PROJECT_ACTION', 'LOAD_FAIL', e, s);
    if (context.mounted) {
      _hideLoadingDialog(context);
      _showErrorDialog(context, '読み込みエラー', 'プロジェクトの読み込みに失敗しました: $e');
    }
    return null;
  }
}

Future<List<List<String>>?> captureProcessAndConfirmNifudaAction(BuildContext context, String projectFolderPath) async {
  final List<Map<String, dynamic>>? allGptResults =
      await Navigator.push<List<Map<String, dynamic>>>(
    context,
    MaterialPageRoute(builder: (_) => CameraCapturePage(
        overlayText: '荷札を枠に合わせて撮影',
        isProductListOcr: false,
        projectFolderPath: projectFolderPath,
        // 修正後の sendImageToGPT のシグネチャ (Map? 戻り値と client 引数) に対応
        aiService: sendImageToGPT,
    )),
  );
  if (allGptResults == null || allGptResults.isEmpty) {
    if (context.mounted) {
      showCustomSnackBar(context, '荷札の撮影またはOCR処理がキャンセルされました。');
      // ★ 再修正: type -> type (そのまま)
      FlutterLogs.logThis(
        tag: 'OCR_ACTION',
        subTag: 'NIFUDA_CANCEL',
        logMessage: 'Nifuda OCR was cancelled by user.',
        level: LogLevel.WARNING, // ★ 正: type
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
           // ★ 再修正: type -> type (そのまま)
           FlutterLogs.logThis(
             tag: 'OCR_ACTION',
             subTag: 'NIFUDA_CONFIRM_INTERRUPTED',
             logMessage: 'Nifuda confirmation interrupted after $imageIndex images.',
             level: LogLevel.WARNING, // ★ 正: type
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

Future<List<List<String>>?> captureProcessAndConfirmProductListAction(
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
    _logError('DOC_SCANNER', 'Scanner launch error', e, s);
    if (context.mounted) _showErrorDialog(context, 'スキャナ起動エラー', 'Google ML Kit Document Scannerの起動に失敗しました: $e');
    return null;
  }
  if (imageFilePaths == null || imageFilePaths.isEmpty) {
    if (context.mounted) showCustomSnackBar(context, '製品リストの撮影がキャンセルされました。');
    return null;
  }
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
  _showLoadingDialog(context, 'プレビューを準備中...');
  if(context.mounted) _hideLoadingDialog(context);
  final Uint8List? finalMaskedFirstImageBytes = await Navigator.push<Uint8List>(
    context, MaterialPageRoute(builder: (_) => ProductListMaskPreviewPage(previewImageBytes: firstImageBytes, maskTemplate: template, imageIndex: 1, totalImages: rawImageBytesList.length)),
  );
  if (finalMaskedFirstImageBytes == null) {
      if(context.mounted) showCustomSnackBar(context, 'マスク確認が破棄されたため、OCR処理を中断しました。');
      return null;
  }
  List<Uint8List> finalImagesToSend = [finalMaskedFirstImageBytes];
  for (int i = 1; i < rawImageBytesList.length; i++) {
    if(context.mounted) _showLoadingDialog(context, '画像を準備中... (${i + 1}/${rawImageBytesList.length})');
    final image = img.decodeImage(rawImageBytesList[i])!;
    if (template == 't') {
        final maskedImage = applyMaskToImage(image, template: 't');
        finalImagesToSend.add(Uint8List.fromList(img.encodeJpg(maskedImage, quality: 100)));
    } else {
        finalImagesToSend.add(rawImageBytesList[i]);
    }
  }
  if(context.mounted) _hideLoadingDialog(context);
  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }
  if (!context.mounted) return null;
  showCustomSnackBar(context, '${finalImagesToSend.length} 枚の画像をGPTへ送信依頼しました。結果を待っています...');
  FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_START', '${finalImagesToSend.length} images sent to GPT.');
  
  List<Future<Map<String, dynamic>?>> gptResultFutures = [];
  for (final imageBytes in finalImagesToSend) {
    // 修正: client 引数を削除（sendImageToGPTのシグネチャに合わせるため）
    final gptFuture = sendImageToGPT(imageBytes, isProductList: true, company: selectedCompany)
        .catchError((e, s) { _logError('GPT_API', 'GPT API call failed', e, s); return null; });
    gptResultFutures.add(gptFuture);
  }
  final List<Map<String, dynamic>?> allGptRawResults = await Future.wait(gptResultFutures);
  
  List<Map<String, String>> allExtractedProductRows = [];
  const List<String> expectedProductFields = ProductListOcrConfirmPage.productFields;
  for(final gptResponse in allGptRawResults){
     if (gptResponse != null && gptResponse.containsKey('products') && gptResponse['products'] is List) {
        final List<dynamic> productListRaw = gptResponse['products'];
        String commonOrderNoFromGpt = gptResponse['commonOrderNo']?.toString() ?? '';
        for (final item in productListRaw) {
          if (item is Map) {
            Map<String, String> row = {};
            final String remarks = item['備考']?.toString() ?? '';
            String finalOrderNo = commonOrderNoFromGpt;
            if (commonOrderNoFromGpt.isNotEmpty && remarks.isNotEmpty) {
              final lastSeparatorIndex = commonOrderNoFromGpt.lastIndexOf(RegExp(r'[\s-]'));
              if (lastSeparatorIndex != -1) {
                final prefix = commonOrderNoFromGpt.substring(0, lastSeparatorIndex + 1);
                finalOrderNo = '$prefix$remarks';
              } else {
                finalOrderNo = '$commonOrderNoFromGpt $remarks';
              }
            }
            for (String field in expectedProductFields) {
              row[field] = (field == 'ORDER No.') ? finalOrderNo : item[field]?.toString() ?? '';
            }
            allExtractedProductRows.add(row);
          }
        }
      } else {
        // ★ 再修正: type -> type (そのまま)
        FlutterLogs.logThis(
          tag: 'OCR_ACTION',
          subTag: 'PRODUCT_LIST_PARSE_FAIL',
          logMessage: 'GPT response structure unexpected.',
          level: LogLevel.WARNING, // ★ 正: type
        );
        debugPrint('製品リストの解析に失敗した応答がありました (予期せぬ形式)。');
      }
  }
  if (!context.mounted) return null;
  if (allExtractedProductRows.isNotEmpty) {
      FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_CONFIRM', '${allExtractedProductRows.length} rows extracted for confirmation.');
      final List<List<String>>? confirmedData = await Navigator.push<List<List<String>>>(
        context, MaterialPageRoute(builder: (_) => ProductListOcrConfirmPage(extractedProductRows: allExtractedProductRows)),
      );
      return confirmedData;
  } else {
      _logError('OCR_ACTION', 'PRODUCT_LIST_NO_RESULT', 'No valid product list data extracted.', null);
      if (context.mounted) _showErrorDialog(context, 'OCR結果なし', '有効な製品リストデータが抽出されませんでした。');
      return null;
  }
}

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

Future<String?> startMatchingAndShowResultsAction(
  BuildContext context,
  List<List<String>> nifudaData,
  List<List<String>> productListData,
  String matchingPattern,
  String projectTitle,
  String projectFolderPath,
) async {
  if (nifudaData.length <= 1 || productListData.length <= 1) {
    _showErrorDialog(context, 'データ不足', '照合するには荷札と製品リストの両方のデータが必要です。');
    // ★ 再修正: type -> type (そのまま)
    FlutterLogs.logThis(
      tag: 'MATCHING_ACTION',
      subTag: 'DATA_INSUFFICIENT',
      logMessage: 'Matching attempted with insufficient data.',
      level: LogLevel.WARNING, // ★ 正: type
    );
    return null;
  }
  final nifudaHeaders = nifudaData.first;
  final nifudaMapList = nifudaData.sublist(1).map((row) {
    return { for (int i = 0; i < nifudaHeaders.length; i++) nifudaHeaders[i]: (i < row.length ? row[i] : '') };
  }).toList();
  final productHeaders = productListData.first;
  final productMapList = productListData.sublist(1).map((row) {
    return { for (int i = 0; i < productHeaders.length; i++) productHeaders[i]: (i < row.length ? row[i] : '') };
  }).toList();
  if (nifudaMapList.isEmpty || productMapList.isEmpty) {
     _showErrorDialog(context, 'データ不足', '荷札または製品リストの有効なデータがありません。');
     // ★ 再修正: type -> type (そのまま)
     FlutterLogs.logThis(
       tag: 'MATCHING_ACTION',
       subTag: 'DATA_EMPTY',
       logMessage: 'Matching failed due to empty map lists.',
       level: LogLevel.WARNING, // ★ 正: type
     );
    return null;
  }
  final matchingLogic = ProductMatcher();
  final Map<String, dynamic> rawResults = matchingLogic.match(nifudaMapList, productMapList, pattern: matchingPattern);
  FlutterLogs.logInfo('MATCHING_ACTION', 'MATCHING_SUCCESS', 'Matching completed with pattern: $matchingPattern. Matched: ${(rawResults['matched'] as List).length}, Unmatched: ${(rawResults['unmatched'] as List).length}');
  final String? newStatus = await Navigator.push<String>(
    context, MaterialPageRoute(builder: (_) => MatchingResultPage(matchingResults: rawResults, projectFolderPath: projectFolderPath, projectTitle: projectTitle, nifudaData: nifudaData, productListKariData: productListData)),
  );
  if (context.mounted && newStatus != null) {
    Navigator.pop(context, newStatus);
    return newStatus;
  }
  return null;
}