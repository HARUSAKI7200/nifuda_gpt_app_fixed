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

import '../utils/gemini_service.dart';
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


// ★★★ Geminiを利用する製品リストOCR処理 ★★★
Future<List<List<String>>?> pickProcessAndConfirmProductListActionWithGemini(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading,
  String projectFolderPath,
  String productListPath, // ★★★ 追加：フォルダパスを受け取る引数
) async {
  // ★★★ 変更点：ハードコーディングされたパスを引数で受け取ったものに置き換え ★★★
  final String targetDirectory = productListPath;
  
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
        file.path, minWidth: 1280, minHeight: 1280, quality: 80,
      ))!;
      if(context.mounted) _hideLoadingDialog(context);

      final Uint8List? finalMaskedImageBytes =
          await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListMaskPreviewPage(
            previewImageBytes: previewImageBytes,
            maskTemplate: template,
            imageIndex: i + 1, totalImages: pickedFiles.length,
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
  showCustomSnackBar(context, '${finalImagesToSend.length} 枚の画像をGeminiへ送信依頼しました...');

  final client = http.Client();
  
  List<Future<Map<String, dynamic>?>> aiResultFutures = [];
  for (final imageBytes in finalImagesToSend) {
    final future = sendImageToGemini(
      imageBytes,
      isProductList: true,
      company: selectedCompany,
      client: client,
    ).catchError((e) {
      debugPrint('Gemini送信エラー: $e');
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
        debugPrint('製品リストの解析に失敗した応答がありました (予期せぬ形式)。');
      }
  }
  
  if (!context.mounted) {
    setLoading(false);
    return null;
  }
  setLoading(false);

  if (allExtractedProductRows.isNotEmpty) {
      return await Navigator.push<List<List<String>>>(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListOcrConfirmPage(extractedProductRows: allExtractedProductRows),
        ),
      );
  } else {
      if (context.mounted) _showErrorDialog(context, 'OCR結果なし', '有効な製品リストデータが抽出されませんでした。');
      return null;
  }
}