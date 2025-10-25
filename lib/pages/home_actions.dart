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
import 'package:flutter_logs/flutter_logs.dart'; // ★ 追加: flutter_logs
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

// ★★★ 追加: エラーロギングヘルパー関数 ★★★
void _logError(String tag, String message, dynamic error, StackTrace? stack) {
  FlutterLogs.logError(
    tag,
    'ACTION_ERROR',
    message,
    error: error,
    stackTrace: stack,
    timestamp: DateTime.now(),
  );
  debugPrint('[$tag] $message: $error');
}


// ★★★ 修正: シャープニングフィルター適用ヘルパー関数 - divisorとoffsetを削除 ★★★
img.Image _applySharpeningFilter(img.Image image) {
  // シャープニングカーネル (一般的なもの)
  // [0, -1, 0]
  // [-1, 5, -1]
  // [0, -1, 0]
  final Float32List kernel = Float32List.fromList([
    0, -1, 0,
    -1, 5, -1,
    0, -1, 0,
  ]);
  
  // 3x3 のカーネルで畳み込みを適用
  return img.convolution(
    image, 
    filter: kernel, // 'filter' named argumentを使用
    // divisor: 1, // エラーのため削除
    // offset: 0,  // エラーのため削除
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

    // ★ ログ追加
    FlutterLogs.logInfo('PROJECT_ACTION', 'SAVE_SUCCESS', 'Project $projectTitle saved to $filePath');

    if (context.mounted) {
      _hideLoadingDialog(context);
      showCustomSnackBar(context, 'プロジェクト「$projectTitle」を保存しました。');
    }
    return filePath; // 保存したファイルのパスを返す
  } catch (e, s) {
    // ★ ログ追加
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
    
    // ★ ログ追加
    FlutterLogs.logInfo('PROJECT_ACTION', 'LOAD_SUCCESS', 'Project ${loadedData['projectTitle']} loaded.');

    if (context.mounted) {
      _hideLoadingDialog(context);
      showCustomSnackBar(context, 'プロジェクト「${loadedData['projectTitle']}」を読み込みました。');
    }
    return loadedData;
  } catch (e, s) {
    // ★ ログ追加
    _logError('PROJECT_ACTION', 'LOAD_FAIL', e, s);
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
      FlutterLogs.logWarning('OCR_ACTION', 'NIFUDA_CANCEL', 'Nifuda OCR was cancelled by user.');
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
           FlutterLogs.logWarning('OCR_ACTION', 'NIFUDA_CONFIRM_INTERRUPTED', 'Nifuda confirmation interrupted after $imageIndex images.');
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

// ★★★ 変更: カメラ連続撮影による製品リストOCR処理 (GPT版) - setloading削除とログ追加 ★★★
Future<List<List<String>>?> captureProcessAndConfirmProductListAction(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading, // <--- このコールバックは使用しないが、引数は残す
  String projectFolderPath,
) async {
  // 1. ML Kit Document Scannerを起動して、補正済み画像のファイルパスリストを取得
  List<String>? imageFilePaths;
  try {
    final options = DocumentScannerOptions(
      pageLimit: 100, // ページ数の制限なし（実質）
      isGalleryImport: false, // ギャラリーからのインポートを許可しない
      documentFormat: DocumentFormat.jpeg, // JPEG形式で結果を取得
      mode: ScannerMode.full,
    );
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

  // 2. 取得したファイルパスからUint8Listリストを作成し、固定サイズにリサイズ（正規化）
  List<Uint8List> rawImageBytesList = [];
  const int PERSPECTIVE_WIDTH = 1920; 
  
  try {
    for (var path in imageFilePaths) {
      final file = File(path);
      final rawBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(rawBytes);

      if (originalImage == null) continue;

      img.Image normalizedImage = img.copyResize(
        originalImage,
        width: PERSPECTIVE_WIDTH,
        height: (originalImage.height * (PERSPECTIVE_WIDTH / originalImage.width)).round(),
      );
      
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
  // setLoading(true); // ★ 削除
  showCustomSnackBar(context, '${finalImagesToSend.length} 枚の画像をGPTへ送信依頼しました。結果を待っています...');
  FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_START', '${finalImagesToSend.length} images sent to GPT.');

  final client = http.Client();
  List<Future<Map<String, dynamic>?>> gptResultFutures = [];

  for (final imageBytes in finalImagesToSend) {
    final gptFuture = sendImageToGPT(
      imageBytes,
      isProductList: true,
      company: selectedCompany,
      client: client,
    ).catchError((e, s) {
      _logError('GPT_API', 'GPT API call failed', e, s);
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
        // ★ ログ追加
        FlutterLogs.logWarning('OCR_ACTION', 'PRODUCT_LIST_PARSE_FAIL', 'GPT response structure unexpected.');
        debugPrint('製品リストの解析に失敗した応答がありました (予期せぬ形式)。');
      }
  }
  
  if (!context.mounted) {
    // setLoading(false); // ★ 削除
    return null;
  }
  // setLoading(false); // ★ 削除

  if (allExtractedProductRows.isNotEmpty) {
      FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_CONFIRM', '${allExtractedProductRows.length} rows extracted for confirmation.');
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
    FlutterLogs.logWarning('MATCHING_ACTION', 'DATA_INSUFFICIENT', 'Matching attempted with insufficient data.');
    return null; // データ不足の場合は null を返す
  }

  // ... 既存の照合ロジック（変更なし）...
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
     FlutterLogs.logWarning('MATCHING_ACTION', 'DATA_EMPTY', 'Matching failed due to empty map lists.');
    return null; // データ不足の場合は null を返す
  }
  
  final matchingLogic = ProductMatcher();

  final Map<String, dynamic> rawResults = matchingLogic.match(nifudaMapList, productMapList, pattern: matchingPattern);

  // ★ ログ追加
  FlutterLogs.logInfo('MATCHING_ACTION', 'MATCHING_SUCCESS', 'Matching completed with pattern: $matchingPattern. Matched: ${(rawResults['matched'] as List).length}, Unmatched: ${(rawResults['unmatched'] as List).length}');


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