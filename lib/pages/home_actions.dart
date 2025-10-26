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
import 'project_load_dialog.dart'; 
import 'streaming_progress_dialog.dart'; 
import '../utils/gemini_service.dart'; // 荷札アクションで使用する可能性があるためインポートを維持

// --- Constants ---
// ★ 修正: home_page.dartとの定数名の重複解消のため、BASE_PROJECT_DIRのみを公開
const String BASE_PROJECT_DIR = "/storage/emulated/0/DCIM/検品関係";

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

// ログファイル名に使用するタイムスタンプを生成 (例: 20251026_140800)
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

Future<String?> saveProjectAction(
  BuildContext context,
  String currentProjectFolderPath,
  String projectTitle,
  List<List<String>> nifudaData,
  List<List<String>> productListKariData,
) async {
  try {
    final now = DateTime.now();
    final timestamp = _formatTimestampForFilename(now); // ★ 修正: 日付/時刻をファイル名に含める
    final fileName = '$projectTitle\_$timestamp.json';
    
    // 保存先フォルダ: /DCIM/検品関係/[製番]/SAVES
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

// プロジェクトをJSONファイルから読み込み
Future<Map<String, dynamic>?> loadProjectAction(BuildContext context) async {
  // ベースフォルダ: /DCIM/検品関係
  final baseDir = Directory(BASE_PROJECT_DIR); 

  if (!await baseDir.exists()) {
    if (context.mounted) showCustomSnackBar(context, 'プロジェクトの保存フォルダが見つかりませんでした。', isError: true);
    return null;
  }
  
  // ★ 修正: ProjectLoadDialogを使用して、日時付きファイルを選択
  final Map<String, String>? selectedFile = await ProjectLoadDialog.show(context, BASE_PROJECT_DIR);

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

    // データ整合性のチェック（最低限）
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
      // ★ 修正: rowsパラメータが存在しないため、元のデータパラメータ名 'data' にデータを渡す
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
    // ★★★ 修正: DirectoryImagePickerPage の代わりに DocumentScanner を使用 ★★★
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
    // ★★★ 修正: エラーログとメッセージをスキャナー用に変更 ★★★
    _logError('DOC_SCANNER', 'Scanner launch error (GPT)', e, s);
    if (context.mounted) _showErrorDialog(context, 'スキャナ起動エラー', 'Google ML Kit Document Scannerの起動に失敗しました: $e');
    return null;
  }

  if (imageFilePaths == null || imageFilePaths.isEmpty) {
    // ★★★ 修正: メッセージをスキャナー用に変更 ★★★
    if (context.mounted) showCustomSnackBar(context, '製品リストのスキャンがキャンセルされました。');
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
    if (context.mounted) _showErrorDialog(context, '画像処理エラー', '選択済みファイルの読み込みまたはリサイズに失敗しました: $e');
    return null;
  }
  if (rawImageBytesList.isEmpty) {
      if(context.mounted) _showErrorDialog(context, '画像処理エラー', '有効な画像が読み込めませんでした。');
      return null;
  }
  String template;
  switch (selectedCompany) {
    // ★★★ 修正: 会社名を 'TMEIC' に合わせる (プロンプトと一致させるため)
    case 'T社': template = 't'; break; // ocr_masker側は 't' を期待
    case 'マスク処理なし': template = 'none'; break;
    case '動的マスク処理': template = 'dynamic'; break;
    default: if(context.mounted) _showErrorDialog(context, 'テンプレートエラー', '無効な会社名が選択されました。'); return null;
  }
  final Uint8List firstImageBytes = rawImageBytesList.first;
  if (!context.mounted) return null;
  _showLoadingDialog(context, 'プレビューを準備中...');
  if(context.mounted) _hideLoadingDialog(context);
  
  // ★ 修正: 戻り値の型を MaskPreviewResult に変更
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
  
  for (int i = 1; i < rawImageBytesList.length; i++) {
    if(context.mounted) _showLoadingDialog(context, '画像を準備中... (${i + 1}/${rawImageBytesList.length})');
    final image = img.decodeImage(rawImageBytesList[i])!;
    
    img.Image maskedImage = image;
    
    if (template == 't') {
        // T社固定マスクを適用
        maskedImage = applyMaskToImage(image, template: 't');
    } else if (template == 'dynamic' && dynamicMasks.isNotEmpty) {
        // ★ 修正: 動的マスクを2枚目以降にも適用
        maskedImage = applyMaskToImage(image, template: 'dynamic', dynamicMaskRects: dynamicMasks);
    } else {
        maskedImage = image;
    }
    
    finalImagesToSend.add(Uint8List.fromList(img.encodeJpg(maskedImage, quality: 100)));
  }
  
  if(context.mounted) _hideLoadingDialog(context);
  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }

  // 5. ストリーミングリクエストの実行
  List<Map<String, dynamic>?> allAiRawResults = [];

  // ★★★ 修正: プロンプトと合わせるため、T社の場合は 'TMEIC' を渡す
  final String companyForGpt = (selectedCompany == 'T社') ? 'TMEIC' : selectedCompany;

  for (int i = 0; i < finalImagesToSend.length; i++) {
      if (!context.mounted) break;
      final imageBytes = finalImagesToSend[i];
      
      // ★ 修正: ストリーミング関数を使用 (companyForGpt を渡す)
      final Stream<String> stream = sendImageToGPTStream(
        imageBytes, 
        company: companyForGpt,
      );
      
      final String streamTitle = '製品リスト抽出中 (GPT) (${i + 1} / ${finalImagesToSend.length})';
      
      // ★ 修正: ストリーミングダイアログを表示
      final String? rawJsonResponse = await StreamingProgressDialog.show(
        context: context, 
        stream: stream, 
        title: streamTitle, 
        serviceTag: 'GPT_SERVICE'
      );
      
      if (rawJsonResponse == null) {
          _logError('OCR_ACTION', 'PRODUCT_LIST_GPT_STREAM_FAIL', 'Stream failed or cancelled for image ${i + 1}', null);
          if (context.mounted) _showErrorDialog(context, '抽出エラー', '${i + 1}枚目の画像の抽出に失敗しました。処理を中断します。');
          // ★★★ 修正: _processRawProductResults に selectedCompany を渡す
          return allAiRawResults.isNotEmpty ? await _processRawProductResults(context, allAiRawResults, selectedCompany) : null;
      }
      
      // JSONのパース
      String? stripped; // ★ 修正: strippedをtry/catch外で定義
      try {
          // GPT service内の _stripCodeFences を再実装（ここでは一旦簡易的に）
          stripped = rawJsonResponse.trim();
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
          // ★ 修正: strippedがnullでないことを確認してからログに出力
          _logError('OCR_ACTION', 'PRODUCT_LIST_GPT_PARSE_FAIL', 'Failed to parse JSON for image ${i + 1}: ${stripped ?? rawJsonResponse}', s);
          allAiRawResults.add(null);
      }
  }

  // 6. 結果の統合と確認画面への遷移
  if (!context.mounted) return null;
  // ★★★ 修正: _processRawProductResults に selectedCompany を渡す
  return _processRawProductResults(context, allAiRawResults, selectedCompany);
}

// ★★★ 修正: 会社名(selectedCompany)を引数で受け取り、OrderNo生成ロジックを分岐 ★★★
Future<List<List<String>>?> _processRawProductResults(
  BuildContext context, 
  List<Map<String, dynamic>?> allAiRawResults,
  String selectedCompany, // ★引数を追加
) async {
  List<Map<String, String>> allExtractedProductRows = [];
  // ★★★ 修正: productFieldsは 'product_list_ocr_confirm_page.dart' から取得する
  // (プロンプトと一致している必要があるため、定義ファイル側も修正が必要だが、ここでは仮定する)
  const List<String> expectedProductFields = ProductListOcrConfirmPage.productFields;
  
  // ★★★ 修正: T社の場合、プロンプトに 'TMEIC' を使用しているため、ここで 'T社' に戻す
  final bool isTCompany = (selectedCompany == 'T社') || (selectedCompany == 'TMEIC');

  for(final result in allAiRawResults){
     if (result != null && result.containsKey('products') && result['products'] is List) {
        final List<dynamic> productListRaw = result['products'];
        // 共通OrderNo (T社の場合は "QZ83941"、それ以外は "T-12345-" などを期待)
        String commonOrderNo = result['commonOrderNo']?.toString() ?? ''; 
        
        for (final item in productListRaw) {
          if (item is Map) {
            Map<String, String> row = {};
            String finalOrderNo = '';

            // ★★★ ユーザー要求に基づくロジック変更 (T社 vs T社以外) ★★★
            if (isTCompany) {
              // T社の場合: commonOrderNo (QZ83941) + 備考(NOTE) (FEV2385)
              // ★ 修正: プロンプトに合わせて '備考(NOTE)' を使用
              // (product_list_ocr_confirm_page.dart の
              // productFields に '備考(NOTE)' が含まれている必要がある)
              final String note = item['備考(NOTE)']?.toString() ?? '';
              finalOrderNo = '$commonOrderNo $note'.trim(); // 例: "QZ83941 FEV2385"
            } else {
              // T社以外の場合: commonOrderNo + 備考(REMARKS) ※枝番
              // ★ 修正: プロンプトに合わせて '備考(REMARKS)' を使用
              // (product_list_ocr_confirm_page.dart の
              // productFields に '備考(REMARKS)' が含まれている必要がある)
              final String remarks = item['備考(REMARKS)']?.toString() ?? ''; 
              finalOrderNo = commonOrderNo; // まず共通番号をセット

              if (commonOrderNo.isNotEmpty && remarks.isNotEmpty) {
                final lastSeparatorIndex = commonOrderNo.lastIndexOf(RegExp(r'[\s-]'));
                if (lastSeparatorIndex != -1) {
                  final prefix = commonOrderNo.substring(0, lastSeparatorIndex + 1);
                  finalOrderNo = '$prefix$remarks'; // 例: "T-12345-" + "01"
                } else {
                  finalOrderNo = '$commonOrderNo $remarks'; // 例: "12345" + "01"
                }
              }
            }
            // ★★★ ロジック変更ここまで ★★★
            
            for (String field in expectedProductFields) {
              // 'ORDER No.' のみ、上で生成した finalOrderNo を使う
              row[field] = (field == 'ORDER No.') ? finalOrderNo : item[field]?.toString() ?? '';
            }
            allExtractedProductRows.add(row);
          }
        }
      } else {
        // パースエラーは既にログ済み
      }
  }

  if (allExtractedProductRows.isNotEmpty) {
      FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_CONFIRM', '${allExtractedProductRows.length} rows extracted for confirmation.');
      return Navigator.push<List<List<String>>>(
        context, MaterialPageRoute(builder: (_) => ProductListOcrConfirmPage(extractedProductRows: allExtractedProductRows)),
      );
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
      // ★ 修正: rowsパラメータが存在しないため、元のデータパラメータ名 'data' にデータを渡す
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
    _showErrorDialog(context, 'データ不足', '照合には荷札と製品リストの両方のデータが必要です。');
    // ★ 再修正: type -> type (そのまま)
    FlutterLogs.logThis(
      tag: 'MATCHING_ACTION',
      subTag: 'DATA_INSUFFICIENT',
      logMessage: 'Matching attempted with insufficient data.',
      level: LogLevel.WARNING, // ★ 正: type
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
     // ★ 再修正: type -> type (そのまま)
     FlutterLogs.logThis(
       tag: 'MATCHING_ACTION',
       subTag: 'DATA_EMPTY',
       logMessage: 'Matching failed due to empty map lists.',
       level: LogLevel.WARNING, // ★ 正: type
     );
    return null;
  }
  
  // ★ 修正: computeを使わず、直接matchingLogicを呼ぶ（compute用の定義がないため）
  final matchingLogic = ProductMatcher();
  final Map<String, dynamic> rawResults = matchingLogic.match(nifudaMapList, productMapList, pattern: matchingPattern);

  _hideLoadingDialog(context);
  
  FlutterLogs.logInfo('MATCHING_ACTION', 'MATCHING_SUCCESS', 'Matching completed with pattern: $matchingPattern. Matched: ${(rawResults['matched'] as List).length}, Unmatched: ${(rawResults['unmatched'] as List).length}');
  
  // ★ 修正: MatchingResultPageにnifudaDataとproductListKariDataを渡す
  final String? newStatus = await Navigator.push<String>(
    context, 
    MaterialPageRoute(builder: (_) => MatchingResultPage(
        matchingResults: rawResults, 
        projectFolderPath: projectFolderPath, 
        projectTitle: projectTitle,
        nifudaData: nifudaData, // ★ 修正: 追加
        productListKariData: productListData, // ★ 修正: 追加
    )),
  );
  if (context.mounted && newStatus != null) {
    // 成功ステータスを返す（home_page.dartで処理される）
    return newStatus;
  }
  return null;
}