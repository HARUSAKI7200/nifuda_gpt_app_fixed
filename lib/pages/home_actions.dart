// lib/pages/home_actions.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // computeのために必要
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../utils/gpt_service.dart';
import '../utils/product_matcher.dart';
import '../utils/excel_export.dart';
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

// (saveProjectAction, loadProjectAction は変更なし)
Future<void> saveProjectAction(
  BuildContext context,
  String projectFolderPath,
  String projectTitle,
  List<List<String>> nifudaData,
  List<List<String>> productListData,
) async {
  if (!context.mounted) return;
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

    if (context.mounted) {
      _hideLoadingDialog(context);
      showCustomSnackBar(context, 'プロジェクト「$projectTitle」を保存しました。');
    }
  } catch (e) {
    if (context.mounted) {
      _hideLoadingDialog(context);
      _showErrorDialog(context, '保存エラー', 'プロジェクトの保存に失敗しました: $e');
    }
  }
}

Future<Map<String, dynamic>?> loadProjectAction(BuildContext context) async {
  try {
    const String baseDcimPath = "/storage/emulated/0/DCIM";
    final String inspectionRelatedPath = p.join(baseDcimPath, "検品関係");
    final dir = Directory(inspectionRelatedPath);

    if (!await dir.exists()) {
      if (context.mounted) {
        _showErrorDialog(context, 'フォルダなし', 'プロジェクトフォルダ「検品関係」が見つかりません。');
      }
      return null;
    }

    final projectDirs = (await dir.list().toList())
        .where((entity) => entity is Directory)
        .cast<Directory>()
        .toList();

    if (projectDirs.isEmpty) {
      if (context.mounted) {
        _showErrorDialog(context, 'プロジェクトなし', '保存されたプロジェクトがありません。');
      }
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
                  onTap: () {
                    Navigator.of(dialogContext).pop(projectDirs[index]);
                  },
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

    final nifudaData = (data['nifudaData'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).map((cell) => cell.toString()).toList())
        .toList();
    final productListKariData = (data['productListKariData'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).map((cell) => cell.toString()).toList())
        .toList();

    final loadedData = {
      'projectTitle': data['projectTitle'] as String,
      'currentProjectFolderPath': selectedDir.path,
      'nifudaData': nifudaData,
      'productListKariData': productListKariData,
    };

    if (context.mounted) {
      _hideLoadingDialog(context);
      showCustomSnackBar(context, 'プロジェクト「${loadedData['projectTitle']}」を読み込みました。');
    }
    return loadedData;
  } catch (e) {
    if (context.mounted) {
      _hideLoadingDialog(context);
      _showErrorDialog(context, '読み込みエラー', 'プロジェクトの読み込みに失敗しました: $e');
    }
    return null;
  }
}


Future<List<List<String>>?> captureProcessAndConfirmNifudaAction(BuildContext context, String projectFolderPath) async {
  // (この関数は変更なし)
  final List<Map<String, dynamic>>? allGptResults =
      await Navigator.push<List<Map<String, dynamic>>>(
    context,
    MaterialPageRoute(builder: (_) => CameraCapturePage(
        overlayText: '荷札を枠に合わせて撮影',
        isProductListOcr: false,
        projectFolderPath: projectFolderPath,
        aiService: sendImageToGPT, // GPTの関数を渡す
    )),
  );

  if (allGptResults == null || allGptResults.isEmpty) {
    if (context.mounted) {
      showCustomSnackBar(context, '荷札の撮影またはOCR処理がキャンセルされました。');
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
           return allConfirmedNifudaRows.isNotEmpty ? allConfirmedNifudaRows : null;
        }
      } else {
        break;
      }
    }
  }

  if (allConfirmedNifudaRows.isNotEmpty) {
    return allConfirmedNifudaRows;
  } else {
    if (context.mounted) {
        showCustomSnackBar(context, '有効な荷札データが1件も確定されませんでした。');
    }
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

Future<List<List<String>>?> pickProcessAndConfirmProductListAction(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading,
  String projectFolderPath,
) async {
  const String targetDirectory = '/storage/emulated/0/DCIM/製品リスト原紙';
  
  if (!await Directory(targetDirectory).exists()) {
    if(context.mounted) _showErrorDialog(context, 'フォルダ未検出', '指定されたフォルダが見つかりません:\n$targetDirectory');
    return null;
  }

  final List<String>? pickedFilePaths = await Navigator.push<List<String>>(
    context,
    MaterialPageRoute(
      builder: (_) => DirectoryImagePickerPage(rootDirectoryPath: targetDirectory),
    ),
  );

  if (pickedFilePaths == null || pickedFilePaths.isEmpty) {
    if (context.mounted) showCustomSnackBar(context, '製品リスト画像の選択がキャンセルされました。');
    return null;
  }
  final List<XFile> pickedFiles = pickedFilePaths.map((path) => XFile(path)).toList();

  List<Uint8List> finalImagesToSend = [];
  
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
  
  try {
    for (int i = 0; i < pickedFiles.length; i++) {
      final file = pickedFiles[i];
      if (!context.mounted) return null;

      _showLoadingDialog(context, 'プレビューを準備中... (${i + 1}/${pickedFiles.length})');
      final Uint8List previewImageBytes = (await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: 1280,
        minHeight: 1280,
        quality: 80,
      ))!;
      if(context.mounted) _hideLoadingDialog(context);

      final Uint8List? finalMaskedImageBytes =
          await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListMaskPreviewPage(
            previewImageBytes: previewImageBytes,
            maskTemplate: template,
            imageIndex: i + 1,
            totalImages: pickedFiles.length,
          ),
        ),
      );

      if (finalMaskedImageBytes != null) {
        finalImagesToSend.add(finalMaskedImageBytes);
      }
    }
  } catch (e) {
      if(context.mounted) {
        _hideLoadingDialog(context);
        _showErrorDialog(context, '画像処理エラー', e.toString());
      }
      return null;
  }

  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }

  if (!context.mounted) return null;
  setLoading(true);
  showCustomSnackBar(context, '${finalImagesToSend.length} 枚の画像をGPTへ送信依頼しました。結果を待っています...');

  final client = http.Client();
  List<Future<Map<String, dynamic>?>> gptResultFutures = [];

  for (final imageBytes in finalImagesToSend) {
    final gptFuture = sendImageToGPT(
      imageBytes,
      isProductList: true,
      company: selectedCompany,
      client: client,
    ).catchError((e) {
      debugPrint('GPT送信エラー: $e');
      return null;
    });
    gptResultFutures.add(gptFuture);
  }

  final List<Map<String, dynamic>?> allGptRawResults = await Future.wait(gptResultFutures);
  client.close();

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
        debugPrint('製品リストの解析に失敗した応答がありました (予期せぬ形式)。');
      }
  }
  
  if (!context.mounted) {
    setLoading(false);
    return null;
  }
  setLoading(false);

  if (allExtractedProductRows.isNotEmpty) {
      final List<List<String>>? confirmedData = await Navigator.push<List<List<String>>>(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListOcrConfirmPage(
            extractedProductRows: allExtractedProductRows,
          ),
        ),
      );
      return confirmedData;
  } else {
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

void startMatchingAndShowResultsAction(
  BuildContext context,
  List<List<String>> nifudaData,
  List<List<String>> productListData,
  String matchingPattern,
  String projectFolderPath,
) {
  if (nifudaData.length <= 1 || productListData.length <= 1) {
    _showErrorDialog(context, 'データ不足', '照合するには荷札と製品リストの両方のデータが必要です。');
    return;
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
    return;
  }
  
  final matchingLogic = ProductMatcher();

  final Map<String, dynamic> rawResults = matchingLogic.match(nifudaMapList, productMapList, pattern: matchingPattern);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MatchingResultPage(
        matchingResults: rawResults,
        projectFolderPath: projectFolderPath,
      ),
    ),
  );
}