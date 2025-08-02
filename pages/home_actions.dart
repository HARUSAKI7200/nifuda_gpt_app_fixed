// lib/pages/home_actions.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img; // imageパッケージをインポート

import '../utils/gpt_service.dart';
import '../utils/ocr_masker.dart';
import '../utils/product_matcher.dart';
import '../utils/excel_export.dart';
import 'camera_capture_page.dart';
import 'nifuda_ocr_confirm_page.dart';
import 'product_list_ocr_confirm_page.dart';
import 'product_list_mask_preview_page.dart';
import '../widgets/excel_preview_dialog.dart';
import 'matching_result_page.dart';
import '../widgets/custom_snackbar.dart';

// --- (既存のヘルパー関数、プロジェクト保存・読込機能は変更なし) ---
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
      showTopSnackBar(context, 'プロジェクト「$projectTitle」を保存しました。');
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
      showTopSnackBar(context, 'プロジェクト「${loadedData['projectTitle']}」を読み込みました。');
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
  final List<Map<String, dynamic>>? allGptResults =
      await Navigator.push<List<Map<String, dynamic>>>(
    context,
    MaterialPageRoute(builder: (_) => CameraCapturePage(
        overlayText: '荷札を枠に合わせて撮影',
        isProductListOcr: false,
        projectFolderPath: projectFolderPath,
    )),
  );

  if (allGptResults == null || allGptResults.isEmpty) {
    if (context.mounted) {
      showTopSnackBar(context, '荷札の撮影またはOCR処理がキャンセルされました。');
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
           if(context.mounted) showTopSnackBar(context, '荷札確認処理が中断されました。');
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
        showTopSnackBar(context, '有効な荷札データが1件も確定されませんでした。');
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


// --- 機能8-9: 製品リスト画像選択とOCR・確認 ---
Future<List<List<String>>?> pickProcessAndConfirmProductListAction(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading,
  String projectFolderPath,
) async {
  final picker = ImagePicker();
  final List<XFile> pickedFiles = await picker.pickMultiImage();

  if (pickedFiles.isEmpty) {
    if (context.mounted) showTopSnackBar(context, '製品リスト画像の選択がキャンセルされました。');
    return null;
  }

  List<Future<Map<String, dynamic>?>> gptResultFutures = [];
  String template = selectedCompany == 'T社' ? 't' : 'none';
  int successCount = 0;
  const int targetWidth = 3507;
  const int targetHeight = 2480;

  if (context.mounted) _showLoadingDialog(context, '画像を処理中...');
  
  try {
    for (int i = 0; i < pickedFiles.length; i++) {
      final file = pickedFiles[i];
      if (!context.mounted) return null;

      Uint8List imageBytes = await file.readAsBytes();
      
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
      // ★ 機能追加：画像リサイズ処理
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage != null) {
        if (originalImage.width != targetWidth || originalImage.height != targetHeight) {
          debugPrint('画像サイズを ${originalImage.width}x${originalImage.height} から ${targetWidth}x${targetHeight} にリサイズします。');
          final resizedImage = img.copyResize(originalImage, width: targetWidth, height: targetHeight, interpolation: img.Interpolation.average);
          // リサイズ後の画像をPNG形式でエンコード（JPEGより高品質）
          imageBytes = Uint8List.fromList(img.encodePng(resizedImage));
        } else {
          debugPrint('画像は既に既定サイズ ${targetWidth}x${targetHeight} です。');
        }
      } else {
        debugPrint('画像のデコードに失敗したため、リサイズをスキップします。');
      }
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★

      if (!context.mounted) return null;

      final Uint8List? maskedImageBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListMaskPreviewPage(
            originalImageBytes: imageBytes, // リサイズ後のバイトデータを渡す
            maskTemplate: template,
            imageIndex: i + 1,
            totalImages: pickedFiles.length,
          ),
        ),
      );

      if (maskedImageBytes != null) {
        successCount++;
        final gptFuture = sendImageToGPT(
          maskedImageBytes,
          isProductList: true,
          company: selectedCompany,
        ).then<Map<String, dynamic>?>((result) {
          return result;
        }).catchError((e) {
          debugPrint('GPT送信エラー(ファイル: ${file.name}): $e');
          return null;
        });
        gptResultFutures.add(gptFuture);
      }
    }
  } finally {
    if (context.mounted) _hideLoadingDialog(context);
  }

  if (gptResultFutures.isEmpty) {
    if(context.mounted) showTopSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }

  if (!context.mounted) return null;
  setLoading(true);
  showTopSnackBar(context, '$successCount / ${pickedFiles.length} 枚の画像をGPTへ送信依頼しました。結果を待っています...');

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
              if (field == 'ORDER No.') {
                row[field] = finalOrderNo;
              } else {
                row[field] = item[field]?.toString() ?? '';
              }
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
      subfolder: '製番リスト',
    ),
  );
}

void startMatchingAndShowResultsAction(
  BuildContext context,
  List<List<String>> nifudaData,
  List<List<String>> productListData,
  String selectedCompany,
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
  final Map<String, dynamic> rawResults = matchingLogic.match(nifudaMapList, productMapList, company: selectedCompany);

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