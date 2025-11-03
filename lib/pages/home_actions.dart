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
import 'package:share_plus/share_plus.dart';
import 'package:drift/drift.dart' show Value; // ProductMatcherで使用するため

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
import '../utils/gemini_service.dart';
import '../state/project_state.dart';

// --- Constants ---
const String BASE_PROJECT_DIR = "/storage/emulated/0/DCIM/検品関係";

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


// ★★★ _saveScannedProductImages (製品リスト画像はCase No.関係なし) ★★★
Future<void> _saveScannedProductImages(
    BuildContext context,
    String projectFolderPath,
    List<String> sourceImagePaths) async {
  if (!Platform.isAndroid) {
    debugPrint("この画像保存方法はAndroid専用です。");
    return;
  }
  try {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
       status = await Permission.manageExternalStorage.request();
    }
    if (!status.isGranted) {
      throw Exception('ストレージへのアクセス権限がありません。');
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

// ★★★ saveProjectAction (修正: JSON保存パス、新規/上書き対応) ★★★
Future<String?> saveProjectAction(
  BuildContext context,
  String currentProjectFolderPath,
  String projectTitle,
  List<List<String>> nifudaData,
  List<List<String>> productListKariData,
  String currentCaseNumber,
  String? existingJsonSavePath,
  void Function(String?) updateJsonSavePath,
) async {
  try {
    String fileName = '$projectTitle.json';
    String saveFilePath;
    String saveDirPath;
    bool isNewSave = existingJsonSavePath == null;

    if (isNewSave) {
      // 2-2: DCIM/検品関係/プロジェクトコード/SAVES/YYYYMMDD/hhmmss/プロジェクトコード.json
      final now = DateTime.now();
      final timestamp = _formatTimestampForFilename(now);
      final dateFolder = timestamp.substring(0, 8);
      final timeFolder = timestamp.substring(9);

      final savesDir = p.join(currentProjectFolderPath, 'SAVES');
      saveDirPath = p.join(savesDir, dateFolder, timeFolder);
      saveFilePath = p.join(saveDirPath, fileName);
    } else {
      saveFilePath = existingJsonSavePath!;
      saveDirPath = p.dirname(saveFilePath);
      fileName = p.basename(saveFilePath);
    }

    final saveDir = Directory(saveDirPath);

    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    final file = File(saveFilePath);

    final projectData = {
      'projectTitle': projectTitle,
      'projectFolderPath': currentProjectFolderPath,
      'nifudaData': nifudaData,
      'productListKariData': productListKariData,
      'currentCaseNumber': currentCaseNumber,
    };

    final jsonString = jsonEncode(projectData);
    await file.writeAsString(jsonString);

    if (isNewSave) {
        updateJsonSavePath(saveFilePath);
    }

    if (context.mounted) {
      final actionType = isNewSave ? '新規保存' : '上書き保存';
      // メッセージ用に相対パスを生成 (SAVESフォルダからの相対パス)
      // currentProjectFolderPath = .../DCIM/検品関係/プロジェクトコード
      // baseSavesDir = .../DCIM/検品関係/SAVES
      final baseSavesDir = p.join(p.dirname(currentProjectFolderPath), 'SAVES');
      final relativePath = p.relative(saveFilePath, from: baseSavesDir);
      showCustomSnackBar(context, 'プロジェクトを SAVES/$relativePath にて $actionType しました。', durationSeconds: 3);
      FlutterLogs.logInfo('PROJECT_ACTION', 'SAVE_SUCCESS', 'Project $projectTitle $actionType to $saveFilePath');
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

// ★★★ loadProjectAction (修正: JSON読み込み - UI変更対応) ★★★
Future<Map<String, dynamic>?> loadProjectAction(
  BuildContext context,
  void Function(String?) updateJsonSavePath,
) async {
  // ★ 修正: ベースのSAVESディレクトリを指定
  final baseSaveDir = Directory(p.join(BASE_PROJECT_DIR, 'SAVES'));

  if (!await baseSaveDir.exists()) {
    if (context.mounted) showCustomSnackBar(context, 'JSON保存フォルダ(SAVES)が見つかりませんでした。', isError: true);
    return null;
  }

  // ★ 修正: DirectoryImagePickerPage のコンストラクタ引数を修正
  final Map<String, String>? selectedFile = await Navigator.push<Map<String, String>>(
    context,
    MaterialPageRoute(builder: (_) => DirectoryImagePickerPage(
      rootDirectoryPath: baseSaveDir.path,
      title: 'JSONプロジェクトを選択', // ★ 修正: title を渡す
      fileExtensionFilter: const ['.json'], // ★ 修正: fileExtensionFilter を渡す
      showDirectoriesFirst: true,
      returnOnlyFilePath: true,
    ))
  );

  if (selectedFile == null || selectedFile['filePath'] == null) {
    if (context.mounted) showCustomSnackBar(context, 'プロジェクトの読み込みがキャンセルされました。');
    return null;
  }

  final filePath = selectedFile['filePath']!;
  final fileName = p.basename(filePath);
  final projectTitle = fileName.replaceAll(RegExp(r'\.json$', caseSensitive: false), '');
  // ★ 修正: projectFolderPath はJSONファイルからではなく、パス構造から決定
  // .../DCIM/検品関係/SAVES/YYYYMMDD/hhmmss/file.json
  // プロジェクトフォルダは .../DCIM/検品関係/プロジェクト名 になる
  // プロジェクト名は projectTitle と同じ
  final projectFolderPath = p.join(BASE_PROJECT_DIR, projectTitle);


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

    updateJsonSavePath(filePath);

    if (context.mounted) {
      showCustomSnackBar(context, 'プロジェクト「$projectTitle」を読み込みました。', durationSeconds: 3);
      FlutterLogs.logInfo('PROJECT_ACTION', 'LOAD_SUCCESS', 'Project $projectTitle loaded from $filePath');
    }

    return {
      'projectTitle': projectTitle,
      'currentProjectFolderPath': projectFolderPath,
      'nifudaData': (loadedData['nifudaData'] as List).map((e) => List<String>.from(e)).toList(),
      'productListKariData': (loadedData['productListKariData'] as List).map((e) => List<String>.from(e)).toList(),
      'currentCaseNumber': loadedData['currentCaseNumber'] ?? '#1',
    };
  } catch (e, s) {
    _logError('PROJECT_ACTION', 'LOAD_ERROR', e, s);
    if (context.mounted) {
      _showErrorDialog(context, '読み込みエラー', 'プロジェクトファイルの読み込みに失敗しました: $e');
    }
    return null;
  }
}


// ★★★ captureProcessAndConfirmNifudaAction (修正: Case No.を渡す) ★★★
Future<List<List<String>>?> captureProcessAndConfirmNifudaAction(
    BuildContext context,
    String projectFolderPath,
    String currentCaseNumber,
) async {
  final List<Map<String, dynamic>>? allGptResults =
      await Navigator.push<List<Map<String, dynamic>>>(
    context,
    MaterialPageRoute(builder: (_) => CameraCapturePage(
        overlayText: '荷札を枠に合わせて撮影',
        isProductListOcr: false,
        projectFolderPath: projectFolderPath,
        caseNumber: currentCaseNumber,
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

// ★★★ showAndExportNifudaListAction (修正: Case No.でフィルタリング) ★★★
void showAndExportNifudaListAction(
  BuildContext context,
  List<List<String>> nifudaData,
  String projectTitle,
  String projectFolderPath,
  String currentCaseNumber,
) {
  // ★ 修正: 変数定義を追加
  // nifudaHeader: ['製番', '項目番号', '品名', '形式', '個数', '図書番号', '摘要', '手配コード', 'Case No.']
  const int caseNoColumnIndex = 8;

  if (nifudaData.isEmpty) {
     _showErrorDialog(context, 'データなし', '荷札データが空です。');
     return;
  }
  final header = nifudaData.first;
  final filteredRows = nifudaData.sublist(1).where((row) {
    if (row.length > caseNoColumnIndex) {
      return row[caseNoColumnIndex] == currentCaseNumber;
    }
    return false;
  }).toList();

  final filteredData = [header, ...filteredRows];

  if (filteredData.length <= 1) {
    _showErrorDialog(context, 'データなし', '表示する荷札データがありません。\n（Case $currentCaseNumber のデータがありません）');
    return;
  }
  showDialog(
    context: context,
    builder: (_) => ExcelPreviewDialog(
      title: '荷札リスト (Case $currentCaseNumber)',
      data: filteredData,
      headers: filteredData.first,
      projectFolderPath: projectFolderPath,
      subfolder: '荷札リスト/$currentCaseNumber',
    ),
  );
}

// ★★★ captureProcessAndConfirmProductListAction (★ 修正: プレビュー遷移のロジック変更) ★★★
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

  // ★★★ 修正ここから (スキャン後の処理フロー変更) ★★★

  // 1. スキャン直後にローディングダイアログを表示
  if (context.mounted) _showLoadingDialog(context, 'プレビューを準備中... (1/${imageFilePaths.length})');

  Uint8List firstImageBytes;
  const int PERSPECTIVE_WIDTH = 1920;
  try {
    // 2. 1枚目の画像だけを先に処理する
    final path = imageFilePaths.first;
    final file = File(path);
    final rawBytes = await file.readAsBytes();
    final originalImage = img.decodeImage(rawBytes);
    
    if (originalImage == null) {
      if (context.mounted) _hideLoadingDialog(context);
      _showErrorDialog(context, '画像処理エラー', '1枚目の画像をデコードできませんでした。');
      return null;
    }
    
    img.Image normalizedImage = img.copyResize(originalImage, width: PERSPECTIVE_WIDTH, height: (originalImage.height * (PERSPECTIVE_WIDTH / originalImage.width)).round());
    normalizedImage = _applySharpeningFilter(normalizedImage);
    
    firstImageBytes = Uint8List.fromList(img.encodeJpg(normalizedImage, quality: 100));

  } catch (e, s) {
    _logError('IMAGE_PROC', 'Image read/resize error (First Image)', e, s);
    if (context.mounted) _hideLoadingDialog(context);
    if (context.mounted) _showErrorDialog(context, '画像処理エラー', 'スキャン済みファイルの読み込みまたはリサイズに失敗しました: $e');
    return null;
  } finally {
     // 3. 1枚目の処理が終わったら、プレビュー遷移の前にダイアログを消す
     if (context.mounted) _hideLoadingDialog(context);
  }
  // ★★★ 修正ここまで ★★★


  String template;
  switch (selectedCompany) {
    case 'T社': template = 't'; break;
    case 'マスク処理なし': template = 'none'; break;
    case '動的マスク処理': template = 'dynamic'; break;
    default: if(context.mounted) _showErrorDialog(context, 'テンプレートエラー', '無効な会社名が選択されました。'); return null;
  }

  // 4. 準備できた1枚目の画像でプレビュー画面に遷移
  if (!context.mounted) return null;
  final MaskPreviewResult? previewResult = await Navigator.push<MaskPreviewResult>(
    context, MaterialPageRoute(builder: (_) => ProductListMaskPreviewPage(
      previewImageBytes: firstImageBytes, // 処理済みの1枚目を渡す
      maskTemplate: template,
      imageIndex: 1,
      // ★★★ ここを修正 (Null安全エラーの解決) ★★★
      totalImages: imageFilePaths!.length, // ★ 修正: !.length に変更
    )),
  );

  if (previewResult == null) {
      if(context.mounted) showCustomSnackBar(context, 'マスク確認が破棄されたため、OCR処理を中断しました。');
      return null;
  }

  final List<Rect> dynamicMasks = previewResult.dynamicMasks;

  // 5. プレビュー確定後、残りの画像を処理する
  List<Uint8List> finalImagesToSend = [previewResult.imageBytes]; // プレビュー画面が返した1枚目（マスク適用済み）
  
  if (imageFilePaths.length > 1) {
    if (context.mounted) _showLoadingDialog(context, '画像を準備中... (2/${imageFilePaths.length})');
    try {
      // ★ 修正: ループを i = 1 (2枚目) から開始
      for (int i = 1; i < imageFilePaths.length; i++) {
        if (!context.mounted) break;
        if(i > 1 && context.mounted) {
            Navigator.pop(context);
           _showLoadingDialog(context, '画像を準備中... (${i + 1}/${imageFilePaths.length})');
        }

        // ★ 修正: 2枚目以降の画像をここで読み込み、処理する
        final path = imageFilePaths[i];
        final file = File(path);
        final rawBytes = await file.readAsBytes();
        final originalImage = img.decodeImage(rawBytes);

        if (originalImage == null) continue;

        // リサイズとシャープ化
        img.Image normalizedImage = img.copyResize(originalImage, width: PERSPECTIVE_WIDTH, height: (originalImage.height * (PERSPECTIVE_WIDTH / originalImage.width)).round());
        normalizedImage = _applySharpeningFilter(normalizedImage);
        
        // マスク適用
        img.Image maskedImage;
        if (template == 't') {
            maskedImage = applyMaskToImage(normalizedImage, template: 't');
        } else if (template == 'dynamic' && dynamicMasks.isNotEmpty) {
            maskedImage = applyMaskToImage(normalizedImage, template: 'dynamic', dynamicMaskRects: dynamicMasks);
        } else {
            maskedImage = normalizedImage;
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

  // --- (以降のAI送信処理は変更なし) ---
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

// ★★★ startMatchingAndShowResultsAction (修正: Case No.連携) ★★★
Future<String?> startMatchingAndShowResultsAction(
  BuildContext context,
  List<List<String>> nifudaData,
  List<List<String>> productListData,
  String matchingPattern,
  String projectTitle,
  String projectFolderPath,
  String currentCaseNumber,
) async {
  const nifudaCaseNoColumnIndex = 8;

  if (nifudaData.length <= 1 || productListData.length <= 1) {
    _showErrorDialog(context, 'データ不足', '照合には荷札と製品リストの両方のデータが必要です。');
    return null;
  }

  final nifudaHeader = nifudaData.first;
  final filteredNifudaData = [
    nifudaHeader,
    ...nifudaData.sublist(1).where((row) {
      if (row.length > nifudaCaseNoColumnIndex) {
        return row[nifudaCaseNoColumnIndex] == currentCaseNumber;
      }
      return false;
    })
  ];

  if (filteredNifudaData.length <= 1) {
    _showErrorDialog(context, 'データ不足', '照合には荷札(${currentCaseNumber}分)のデータが必要です。');
    return null;
  }

  _showLoadingDialog(context, '照合処理を実行中...');

  final nifudaMapList = filteredNifudaData.sublist(1).map((row) {
    final Map<String, String> map = {};
    for (int i = 0; i < nifudaHeader.length; i++) { // Include Case No. column
      map[nifudaHeader[i]] = (i < row.length ? row[i] : '');
    }
    return map;
  }).toList();


  final productHeader = productListData.first;
  final productMapList = productListData.sublist(1).map((row) {
    final Map<String, String> map = {};
    for (int i = 0; i < productHeader.length; i++) {
      map[productHeader[i]] = (i < row.length ? row[i] : '');
    }
    return map;
  }).toList();

  if (nifudaMapList.isEmpty || productMapList.isEmpty) {
     _hideLoadingDialog(context);
     _showErrorDialog(context, 'データ不足', '荷札(${currentCaseNumber}分)または製品リストの有効なデータがありません。');
     return null;
  }

  final matchingLogic = ProductMatcher();
  final Map<String, dynamic> rawResults = await matchingLogic.match(
      nifudaMapList,
      productMapList,
      pattern: matchingPattern,
      currentCaseNumber: currentCaseNumber,
  );

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
        currentCaseNumber: currentCaseNumber,
    )),
  );
  if (context.mounted && newStatus != null) {
    return newStatus;
  }
  return null;
}

// ★★★ exportAllProjectDataAction (修正: productListData パラメータ名修正、型修正、nullチェック追加) ★★★
Future<String?> exportAllProjectDataAction({
  required BuildContext context,
  required String projectTitle,
  required String projectFolderPath,
  required List<List<String>> nifudaData,
  required List<List<String>> productListData, // ★ 修正: パラメータ名
  required Map<String, dynamic> matchingResults,
  required String currentCaseNumber,
  required String? jsonSavePath,
  required String inspectionStatus,
}) async {
  if (!context.mounted) return null;
  _showLoadingDialog(context, '全データの検品完了＆共有処理を実行中...');

  try {
    // 1. JSONデータの保存（最新状態に更新）
    final jsonExporter = saveProjectAction(
      context,
      projectFolderPath,
      projectTitle,
      nifudaData,
      productListData, // ★ 修正: 正しいパラメータを渡す
      currentCaseNumber,
      jsonSavePath,
      (_) {},
    );
    final finalJsonPath = await jsonExporter;
    if (finalJsonPath == null) {
       throw Exception('JSONデータファイルの最終保存に失敗しました。');
    }

    // 2. Excelデータの作成とエクスポート（ローカル＆SMB）
    List<Future<Map<String, String>>> excelExports = [];

    // 2-1. 荷札リスト Excel (Case No.ごとの全データ)
    excelExports.add(exportToExcelStorage(
      fileName: 'Nifuda_All_Cases.xlsx',
      sheetName: '荷札リスト',
      headers: nifudaData.first,
      rows: nifudaData.sublist(1),
      projectFolderPath: projectFolderPath,
      subfolder: '最終エクスポート/Excel',
    ));

    // 2-2. 製品リスト Excel (全データ + 照合済Case)
    excelExports.add(exportToExcelStorage(
      fileName: 'ProductList_All.xlsx',
      sheetName: '製品リスト',
      headers: productListData.first,
      rows: productListData.sublist(1),
      projectFolderPath: projectFolderPath,
      subfolder: '最終エクスポート/Excel',
    ));

    // 2-3. 照合結果 Excel (全Caseの最新照合結果)
    final allMatchedData = (matchingResults['matched'] as List).cast<Map<String, dynamic>>();
    final allUnmatchedData = (matchingResults['unmatched'] as List).cast<Map<String, dynamic>>();

    final matchingHeaders = [
        '照合結果', '荷札_製番', '荷札_項目番号', '荷札_品名', '製品_ORDER No.', '製品_品名記号', '製品_製品コード番号', '照合済Case', '照合Case'
    ];

    // ★ 修正: 型を List<List<String>> に合わせる, null チェック強化
    final List<List<String>> matchingRows = [
      ...allMatchedData.map((m) => <String>[
          '照合成功',
          m['nifuda']?['製番']?.toString() ?? '', m['nifuda']?['項目番号']?.toString() ?? '', m['nifuda']?['品名']?.toString() ?? '',
          m['product']?['ORDER No.']?.toString() ?? '', 
          // ★★★ バグ修正 1 ★★★
          // '品名記D~H号' -> '品名記号'
          m['product']?['品名記号']?.toString() ?? '', 
          m['product']?['製品コード番号']?.toString() ?? '',
          m['product']?['照合済Case']?.toString() ?? '', m['nifuda']?['Case No.']?.toString() ?? '',
      ]),
      ...allUnmatchedData.map((u) => <String>[
          '照合失敗',
          u['nifuda']?['製番']?.toString() ?? '', u['nifuda']?['項目番号']?.toString() ?? '', u['nifuda']?['品名']?.toString() ?? '',
          // ★★★ バグ修正 2 ★★★
          // 'unmatched' の場合も9列にする (product側 4列 + case 1列)
          '', // 製品_ORDER No.
          '', // 製品_品名記号
          '', // 製品_製品コード番号
          '', // 照合済Case
          u['nifuda']?['Case No.']?.toString() ?? '', // 照合Case
      ]),
    ];


    excelExports.add(exportToExcelStorage(
      fileName: 'MatchingResult_All.xlsx',
      sheetName: '照合結果',
      headers: matchingHeaders,
      rows: matchingRows,
      projectFolderPath: projectFolderPath,
      subfolder: '最終エクスポート/Excel',
    ));

    final results = await Future.wait(excelExports);

    // ★ 修正: Nullチェックを強化 (?.isNotEmpty ?? false)
    String localMessages = results.map((r) => r['local']).where((m) => m?.isNotEmpty ?? false).join(', ');
    String smbMessages = results.map((r) => r['smb']).where((m) => m?.isNotEmpty ?? false).join('; ');

    // 4. メッセージの作成とSnackbar表示
    _hideLoadingDialog(context);

    String successMessage = "検品完了＆共有が完了しました。\n\n";
    successMessage += "・JSONデータ: " + p.basename(finalJsonPath) + "を最終保存\n";
    successMessage += "・Excelエクスポート結果: ローカル($localMessages), SMB($smbMessages)\n";
    successMessage += "・画像フォルダ: 製品リスト画像、荷札画像(Case_#1〜#50)はプロジェクトフォルダ内に保存されています。";

    if (context.mounted) {
       _showErrorDialog(context, '検品完了＆共有', successMessage);
    }

    FlutterLogs.logInfo('PROJECT_ACTION', 'EXPORT_ALL_SUCCESS', 'Project $projectTitle exported successfully.');

    return STATUS_COMPLETED;

  } catch (e, s) {
    _hideLoadingDialog(context);
    _logError('PROJECT_ACTION', 'EXPORT_ALL_FAIL', e, s);
    if (context.mounted) {
      _showErrorDialog(context, '共有エラー', '全データのエクスポートに失敗しました: ${e.toString()}');
    }
    return null;
  }
}

// ★★★ [FIX] showAndExportProductListAction (新規追加) ★★★
// 製品リストのプレビューとエクスポート
void showAndExportProductListAction(
  BuildContext context,
  List<List<String>> productListData,
  String projectFolderPath,
) {
  if (productListData.isEmpty) {
     _showErrorDialog(context, 'データなし', '製品リストデータが空です。');
     return;
  }

  // data[0] がヘッダー
  if (productListData.length <= 1) {
    _showErrorDialog(context, 'データなし', '表示する製品リストデータがありません。');
    return;
  }

  showDialog(
    context: context,
    builder: (_) => ExcelPreviewDialog(
      title: '製品リスト (全体)', // タイトル
      data: productListData, // 全データを渡す
      headers: productListData.first, // ヘッダー行
      projectFolderPath: projectFolderPath,
      subfolder: '製品リスト', // 保存用サブフォルダ
    ),
  );
}