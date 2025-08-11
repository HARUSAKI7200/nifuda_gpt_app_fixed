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
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

import '../utils/gemini_service.dart';
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
// ★★★ 追加：新規作成した画像選択画面をインポート ★★★
import 'directory_image_picker_page.dart';


// (このファイル内では共通のヘルパー関数やクラスも定義します)

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


// ★★★ Geminiを利用する製品リストOCR処理 ★★★
Future<List<List<String>>?> pickProcessAndConfirmProductListActionWithGemini(
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
      // ★★★ 修正点: パラメータ名を`directoryPath`から`rootDirectoryPath`に変更 ★★★
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
      template = 'none'; 
  }

  try {
    for (int i = 0; i < pickedFiles.length; i++) {
      final file = pickedFiles[i];
      if (!context.mounted) break;

      _showLoadingDialog(context, 'プレビューを準備中... (${i + 1}/${pickedFiles.length})');
      final Uint8List previewImageBytes = (await FlutterImageCompress.compressWithFile(
        file.path, minWidth: 1280, minHeight: 1280, quality: 80,
      ))!;
      if(context.mounted) _hideLoadingDialog(context);

      final Map<String, dynamic>? resultFromPreview =
          await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListMaskPreviewPage(
            originalImagePath: file.path,
            previewImageBytes: previewImageBytes,
            maskTemplate: template,
            imageIndex: i + 1, totalImages: pickedFiles.length,
          ),
        ),
      );

      if (resultFromPreview != null) {
        if(context.mounted) _showLoadingDialog(context, '画像を処理中... (${i + 1}/${pickedFiles.length})');
        
        final imagePath = resultFromPreview['path'] as String;
        final maskRects = resultFromPreview['rects'] as List<Rect>;
        final maskTemplate = resultFromPreview['template'] as String;
        final previewSize = resultFromPreview['previewSize'] as Size;

        final originalImageBytes = await File(imagePath).readAsBytes();
        final img.Image originalImage = img.decodeImage(originalImageBytes)!;

        final double scaleX = originalImage.width / previewSize.width;
        final double scaleY = originalImage.height / previewSize.height;

        final List<Rect> actualMaskRects = maskRects.map((rect) {
          return Rect.fromLTRB(
            rect.left * scaleX, rect.top * scaleY,
            rect.right * scaleX, rect.bottom * scaleY,
          );
        }).toList();

        final img.Image maskedImage = applyMaskToImage(
          originalImage,
          template: maskTemplate,
          dynamicMaskRects: actualMaskRects,
        );

        final Uint8List webpBytes = (await FlutterImageCompress.compressWithList(
          Uint8List.fromList(img.encodeJpg(maskedImage)),
          minHeight: maskedImage.height, minWidth: maskedImage.width,
          quality: 85, format: CompressFormat.webp,
        )) as Uint8List;

        finalImagesToSend.add(webpBytes);
        if(context.mounted) _hideLoadingDialog(context);
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