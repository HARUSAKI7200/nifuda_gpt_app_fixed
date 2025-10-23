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
import 'package:image/image.dart' as img; 
// ★★★ 修正: Google ML Kit Document Scanner のインポートを追加 ★★★
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

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

// ★★★ 修正点: 戻り値の型を Future<void> から Future<String?> に変更 ★★★
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

    if (context.mounted) {
      _hideLoadingDialog(context);
      showCustomSnackBar(context, 'プロジェクト「$projectTitle」を保存しました。');
    }
    return filePath; // 保存したファイルのパスを返す
  } catch (e) {
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

// ★★★ 変更: カメラ連続撮影による製品リストOCR処理 (GPT版) - ML Kit Document Scannerを使用 ★★★
Future<List<List<String>>?> captureProcessAndConfirmProductListAction(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading,
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
    
  } catch (e) {
    if (context.mounted) _showErrorDialog(context, 'スキャナ起動エラー', 'Google ML Kit Document Scannerの起動に失敗しました: $e');
    return null;
  }

  if (imageFilePaths == null || imageFilePaths.isEmpty) {
    if (context.mounted) showCustomSnackBar(context, '製品リストの撮影がキャンセルされました。');
    return null;
  }

  // 2. 取得したファイルパスからUint8Listリストを作成 
  List<Uint8List> rawImageBytesList = [];
  try {
    for (var path in imageFilePaths) {
      final file = File(path);
      // ML Kitの出力ファイルは一時的な場所にあるため、読み込み後に削除されることを前提とする
      rawImageBytesList.add(await file.readAsBytes());
    }
  } catch (e) {
    if (context.mounted) _showErrorDialog(context, 'ファイル読み込みエラー', 'スキャン済みファイルの読み込みに失敗しました: $e');
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

// ★★★ 修正点: 戻り値の型を Future<void> から Future<String?> に変更 ★★★
Future<String?> startMatchingAndShowResultsAction(
  BuildContext context,
  List<List<String>> nifudaData,
  List<List<String>> productListData,
  String matchingPattern,
  String projectTitle, // 追加
  String projectFolderPath,
) async {
  if (nifudaData.length <= 1 || productListData.length <= 1) {
    _showErrorDialog(context, 'データ不足', '照合するには荷札と製品リストの両方のデータが必要です。');
    return null; // データ不足の場合は null を返す
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
    return null; // データ不足の場合は null を返す
  }
  
  final matchingLogic = ProductMatcher();

  final Map<String, dynamic> rawResults = matchingLogic.match(nifudaMapList, productMapList, pattern: matchingPattern);

  // MatchingResultPageに生データとプロジェクト名を渡す
  final String? newStatus = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) => MatchingResultPage(
        matchingResults: rawResults,
        projectFolderPath: projectFolderPath,
        projectTitle: projectTitle, // 追加
        nifudaData: nifudaData, // 追加
        productListKariData: productListData, // 追加
      ),
    ),
  );
  
  // 戻り値があれば、それをHomePageに伝えるためにさらにpopする
  if (context.mounted && newStatus != null) {
    Navigator.pop(context, newStatus);
    return newStatus; // Navigator.pop(context, newStatus); が実行された場合でも、この関数自体は値を返す必要がある
  }
  
  return null; // 照合結果画面から何も返されなかった場合や、エラーの場合
}