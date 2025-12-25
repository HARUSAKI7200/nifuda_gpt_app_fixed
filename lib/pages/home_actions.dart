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
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:drift/drift.dart' show Value;
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart'; 

import '../utils/gpt_service.dart';
import '../utils/product_matcher.dart';
import '../utils/excel_export.dart';
import '../utils/ocr_masker.dart';
import '../utils/keyword_detector.dart'; 
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
import '../database/app_database.dart'; 

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
// --- End of Utility Functions ---


Future<void> _saveScannedProductImages(
    BuildContext context,
    String projectFolderPath,
    List<String> sourceImagePaths, {
    bool isNifuda = false, 
    String? caseNumber,    
}) async {
  if (!Platform.isAndroid) return;
  try {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    if (!statuses[Permission.storage]!.isGranted && !statuses[Permission.manageExternalStorage]!.isGranted) {
      throw Exception('ストレージへのアクセス権限がありません。');
    }

    String targetDirPath;
    String fileNamePrefix;
    if (isNifuda && caseNumber != null) {
      targetDirPath = p.join(projectFolderPath, "荷札画像/$caseNumber");
      fileNamePrefix = "nifuda_${caseNumber.replaceAll('#', 'Case_')}";
    } else {
      targetDirPath = p.join(projectFolderPath, "製品リスト画像");
      fileNamePrefix = "product_list";
    }

    final Directory targetDir = Directory(targetDirPath);
    if (!await targetDir.exists()) await targetDir.create(recursive: true);

    for (final sourcePath in sourceImagePaths) {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) continue;
      
      final timestamp = _formatTimestampForFilename(DateTime.now());
      final originalExtension = p.extension(sourcePath);
      final fileName = '${fileNamePrefix}_$timestamp$originalExtension';
      final targetFilePath = p.join(targetDir.path, fileName);

      try {
        await sourceFile.copy(targetFilePath);
        await MediaScanner.loadMedia(path: targetFilePath);
      } catch (e, s) {
        _logError('IMAGE_SAVE', 'COPY_ERROR', e, s);
      }
    }
  } catch (e, s) {
    _logError('IMAGE_SAVE', 'SAVE_PROCESS_ERROR', e, s);
  }
}

Future<String?> saveProjectAction(
  BuildContext context,
  String currentProjectFolderPath,
  String projectTitle,
  List<List<String>> nifudaData,
  List<List<String>> productListKariData,
  String currentCaseNumber,
  String? existingJsonSavePath,
  void Function(String?) updateJsonSavePath,
  { String? customSavePath } 
) async {
  try {
    String fileName = '$projectTitle.json';
    String saveFilePath;

    if (customSavePath != null) {
      saveFilePath = customSavePath;
      final saveDir = Directory(p.dirname(saveFilePath));
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }
    } 
    else {
      String saveDirPath;
      bool isNewSave = existingJsonSavePath == null;

      if (isNewSave) {
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
    }


    final file = File(saveFilePath);

    Map<String, dynamic> casesMap = {};

    if (nifudaData.length > 1) {
      for (int i = 1; i < nifudaData.length; i++) {
        final row = nifudaData[i];
        String caseNo = (row.length > 8) ? row[8] : 'Unknown';
        if (caseNo.isEmpty) caseNo = 'Unknown';

        if (!casesMap.containsKey(caseNo)) {
          casesMap[caseNo] = {'nifuda': [], 'products': []};
        }
        casesMap[caseNo]!['nifuda'].add(row);
      }
    }

    if (productListKariData.length > 1) {
      for (int i = 1; i < productListKariData.length; i++) {
        final row = productListKariData[i];
        String matchedCase = (row.length > 8) ? row[8] : '';
        String groupKey = matchedCase.isNotEmpty ? matchedCase : 'Unmatched';

        if (!casesMap.containsKey(groupKey)) {
          casesMap[groupKey] = {'nifuda': [], 'products': []};
        }
        casesMap[groupKey]!['products'].add(row);
      }
    }

    final projectData = {
      'projectTitle': projectTitle,
      'projectFolderPath': currentProjectFolderPath,
      'nifudaHeader': nifudaData.isNotEmpty ? nifudaData[0] : [],
      'productListHeader': productListKariData.isNotEmpty ? productListKariData[0] : [],
      'cases': casesMap, 
      'currentCaseNumber': currentCaseNumber,
    };

    final jsonString = jsonEncode(projectData);
    await file.writeAsString(jsonString);

    if (customSavePath == null) {
      bool isNewSave = existingJsonSavePath == null;
      if (isNewSave) {
          updateJsonSavePath(saveFilePath);
      }

      if (context.mounted) {
        final actionType = isNewSave ? '新規保存' : '上書き保存';
        final baseSavesDir = p.join(p.dirname(currentProjectFolderPath), 'SAVES');
        final relativePath = p.relative(saveFilePath, from: baseSavesDir);
        showCustomSnackBar(context, 'プロジェクトを SAVES/$relativePath にて $actionType しました。\n(全ケース統合保存)', durationSeconds: 3);
        FlutterLogs.logInfo('PROJECT_ACTION', 'SAVE_SUCCESS', 'Project $projectTitle $actionType to $saveFilePath (Structured)');
      }
    }

    return saveFilePath;
  } catch (e, s) {
    _logError('PROJECT_ACTION', 'SAVE_ERROR', e, s);
    if (context.mounted && customSavePath == null) {
      showCustomSnackBar(context, 'プロジェクトの保存に失敗しました: $e', isError: true);
    }
    return null;
  }
}

Future<Map<String, dynamic>?> loadProjectAction(
  BuildContext context,
  void Function(String?) updateJsonSavePath,
) async {
  final baseSaveDir = Directory(p.join(BASE_PROJECT_DIR, 'SAVES'));

  if (!await baseSaveDir.exists()) {
    if (context.mounted) showCustomSnackBar(context, 'JSON保存フォルダ(SAVES)が見つかりませんでした。', isError: true);
    return null;
  }

  final Map<String, String>? selectedFile = await Navigator.push<Map<String, String>>(
    context,
    MaterialPageRoute(builder: (_) => DirectoryImagePickerPage(
      rootDirectoryPath: baseSaveDir.path,
      title: 'JSONプロジェクトを選択',
      fileExtensionFilter: const ['.json'],
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
  final projectFolderPath = p.join(BASE_PROJECT_DIR, projectTitle);


  try {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('選択されたファイルが見つかりません。');
    }
    final jsonString = await file.readAsString();
    final Map<String, dynamic> loadedData = jsonDecode(jsonString) as Map<String, dynamic>;

    if (loadedData['projectTitle'] == null) {
      throw Exception('ファイルの構造が不正です(projectTitle欠落)。');
    }

    List<List<String>> nifudaData = [];
    List<List<String>> productListKariData = [];

    if (loadedData.containsKey('cases')) {
      if (loadedData['nifudaHeader'] != null) {
        nifudaData.add(List<String>.from(loadedData['nifudaHeader']));
      }
      if (loadedData['productListHeader'] != null) {
        productListKariData.add(List<String>.from(loadedData['productListHeader']));
      }

      final Map<String, dynamic> cases = loadedData['cases'];
      final sortedKeys = cases.keys.toList()..sort(); 

      for (var key in sortedKeys) {
        final caseData = cases[key];
        if (caseData is Map) {
          if (caseData['nifuda'] != null) {
            for (var row in caseData['nifuda']) {
              nifudaData.add(List<String>.from(row));
            }
          }
          if (caseData['products'] != null) {
            for (var row in caseData['products']) {
              productListKariData.add(List<String>.from(row));
            }
          }
        }
      }
    } else {
      if (loadedData['nifudaData'] is List) {
        nifudaData = (loadedData['nifudaData'] as List).map((e) => List<String>.from(e)).toList();
      }
      if (loadedData['productListKariData'] is List) {
        productListKariData = (loadedData['productListKariData'] as List).map((e) => List<String>.from(e)).toList();
      }
    }

    updateJsonSavePath(filePath);

    if (context.mounted) {
      showCustomSnackBar(context, 'プロジェクト「$projectTitle」を読み込みました。', durationSeconds: 3);
      FlutterLogs.logInfo('PROJECT_ACTION', 'LOAD_SUCCESS', 'Project $projectTitle loaded from $filePath');
    }

    return {
      'projectTitle': projectTitle,
      'currentProjectFolderPath': projectFolderPath,
      'nifudaData': nifudaData,
      'productListKariData': productListKariData,
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

Future<List<List<String>>?> captureProcessAndConfirmNifudaAction(
    BuildContext context,
    String projectFolderPath,
    String currentCaseNumber,
) async {
  final List<Map<String, dynamic>>? processedResults = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CameraCapturePage(
        overlayText: '荷札を撮影 (GPT)',
        isProductListOcr: false,
        projectFolderPath: projectFolderPath,
        caseNumber: currentCaseNumber,
        aiService: sendImageToGPT, // GPT用関数を渡す
    )),
  );

  if (processedResults == null || processedResults.isEmpty) {
    if (context.mounted) showCustomSnackBar(context, '荷札の撮影がキャンセルされました。');
    return null;
  }

  List<List<String>> allConfirmedNifudaRows = [];
  int imageIndex = 0;

  for (final result in processedResults) {
    imageIndex++;
    if (!context.mounted) break;

    final Map<String, dynamic>? confirmedResultMap = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NifudaOcrConfirmPage(
          extractedData: result,
          imageIndex: imageIndex,
          totalImages: processedResults.length,
        ),
      ),
    );

    if (confirmedResultMap != null) {
      List<String> confirmedRowAsList = NifudaOcrConfirmPage.nifudaFields
          .map((field) => confirmedResultMap[field]?.toString() ?? '')
          .toList();
      allConfirmedNifudaRows.add(confirmedRowAsList);
    } else {
      if (context.mounted && imageIndex < processedResults.length) {
         final proceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
                  title: Text('$imageIndex枚目の確認が破棄されました'),
                  content: const Text('次の確認に進みますか？\n「いいえ」で中断します。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('いいえ')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('はい')),
                  ],
                ));
        if (proceed != true) break;
      }
    }
  }

  if (allConfirmedNifudaRows.isNotEmpty) {
     return allConfirmedNifudaRows;
  } else {
    if (context.mounted) showCustomSnackBar(context, '有効な荷札データがありませんでした。');
    return null;
  }
}

void showAndExportNifudaListAction(
  BuildContext context,
  List<List<String>> nifudaData,
  String projectTitle,
  String projectFolderPath,
  String currentCaseNumber,
) {
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

// ★★★ captureProcessAndConfirmProductListAction (修正: AppDatabaseを受け取る) ★★★
Future<List<List<String>>?> captureProcessAndConfirmProductListAction(
  BuildContext context,
  String selectedCompany,
  void Function(bool) setLoading,
  String projectFolderPath,
  AppDatabase db, // ★ DBインスタンス
) async {
  List<String> imageFilePaths = [];
  
  // 1. Google ML Kit Document Scanner を起動
  try {
    final options = DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full, // 撮影・クロップ・フィルタなどの完全なUI
      pageLimit: 100, // 複数ページ対応
      isGalleryImport: true, // ギャラリーからのインポート許可
    );

    final documentScanner = DocumentScanner(options: options);
    final result = await documentScanner.scanDocument();

    if (result.images.isEmpty) {
      if (context.mounted) showCustomSnackBar(context, '製品リストのスキャンがキャンセルされました。');
      return null;
    }
    imageFilePaths = result.images;

  } catch (e, s) {
    _logError('DOC_SCANNER', 'ML Kit Scanner launch error', e, s);
    if (context.mounted) _showErrorDialog(context, 'スキャナ起動エラー', 'ML Kit Document Scannerの起動に失敗しました: $e');
    return null;
  }

  // 2. マスク処理 (バックグラウンドで実行)
  if (context.mounted) _showLoadingDialog(context, '画像を処理中...');

  List<String> processedImagePaths = [];
  
  try {
    // 一時ディレクトリ
    final tempDir = await getTemporaryDirectory();
    final redactionKeywords = [
      '東芝', '東芝エネルギーシステムズ', '東芝インフラシステムズ', '東芝エレベータ',
      '東芝プラントシステム', '東芝インフラテクノサービス', '東芝システムテクノロジー',
      '東芝ITコントロールシステム', '東芝EIコントロールシステム', '東芝ディーエムエス',
      'TMEIC', '東芝三菱電機産業システム',
    ];

    // ★ 追加: DBからカスタムマスク設定を読み込む
    List<Rect> customRelativeRects = [];
    if (selectedCompany != 'マスク処理なし' && selectedCompany != '動的マスク処理') {
      try {
        final profile = await db.maskProfilesDao.getProfileByName(selectedCompany);
        if (profile != null) {
          final List<dynamic> list = jsonDecode(profile.rectsJson);
          customRelativeRects = list.map((s) {
            final parts = s.toString().split(',');
            return Rect.fromLTWH(
              double.parse(parts[0]), double.parse(parts[1]), 
              double.parse(parts[2]), double.parse(parts[3])
            );
          }).toList();
        }
      } catch (e) {
        if (kDebugMode) print('Mask profile load error: $e');
      }
    }

    for (int i = 0; i < imageFilePaths.length; i++) {
      final originalPath = imageFilePaths[i];
      final originalFile = File(originalPath);
      final rawBytes = await originalFile.readAsBytes();
      
      img.Image? imageObj = img.decodeImage(rawBytes);
      if (imageObj == null) continue; // スキップ

      String internalTemplateName = 'none';
      if (selectedCompany == '動的マスク処理') internalTemplateName = 'dynamic';

      if (internalTemplateName == 'dynamic') {
        // 動的マスク (ML Kitでキーワード検出 -> マスク)
        final rects = await KeywordDetector.detectKeywords(originalPath, redactionKeywords);
        if (rects.isNotEmpty) {
           imageObj = applyMaskToImage(imageObj, template: 'dynamic', dynamicMaskRects: rects);
        }
      } else if (customRelativeRects.isNotEmpty) {
        // ★ 追加: カスタムマスク適用
        imageObj = applyMaskToImage(imageObj, relativeMaskRects: customRelativeRects);
      }

      // 保存 (上書きせず別名保存)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // ★ 修正: 保存形式をPNGに変更 (可逆圧縮で画質劣化を防ぐ)
      final savedPath = '${tempDir.path}/processed_scan_$i\_$timestamp.png';
      await File(savedPath).writeAsBytes(img.encodePng(imageObj));
      processedImagePaths.add(savedPath);
    }
  } catch (e, s) {
    _logError('IMAGE_PROC', 'Background Masking Error', e, s);
    if (context.mounted) {
      _hideLoadingDialog(context);
      _showErrorDialog(context, '画像処理エラー', '画像のマスク処理中にエラーが発生しました: $e');
    }
    return null;
  } finally {
    if (context.mounted) _hideLoadingDialog(context);
  }

  if (processedImagePaths.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '有効な画像がありませんでした。');
    return null;
  }

  // 3. プロジェクトフォルダへの保存 (オリジナルではなく処理済み画像を保存)
  unawaited(_saveScannedProductImages(context, projectFolderPath, processedImagePaths));

  // 4. プレビュー (1枚目のみ確認・手動修正用)
  
  if (context.mounted) _showLoadingDialog(context, 'プレビューを準備中...');

  Uint8List firstImageBytes;
  try {
    final path = processedImagePaths.first;
    final file = File(path);
    final rawBytes = await file.readAsBytes();
    // プレビュー用にデコード確認
    final originalImage = img.decodeImage(rawBytes);
    if (originalImage == null) throw Exception('画像のデコードに失敗');
    
    // PNGならそのまま使用
    firstImageBytes = rawBytes;

  } catch(e, s) {
    _logError('IMAGE_PROC', 'Preview Load Error', e, s);
    if (context.mounted) {
      _hideLoadingDialog(context);
      _showErrorDialog(context, 'エラー', 'プレビュー画像の読み込みに失敗しました。');
    }
    return null;
  } finally {
    if (context.mounted) _hideLoadingDialog(context);
  }

  if (!context.mounted) return null;

  // プレビュー画面へ遷移
  final MaskPreviewResult? previewResult = await Navigator.push<MaskPreviewResult>(
    context, MaterialPageRoute(builder: (_) => ProductListMaskPreviewPage(
      previewImageBytes: firstImageBytes,
      maskTemplate: 'none', // 既に処理済みなのでnone
      imageIndex: 1,
      totalImages: processedImagePaths.length,
    )),
  );

  if (previewResult == null) {
      if(context.mounted) showCustomSnackBar(context, 'OCR処理を中断しました。');
      return null;
  }

  // プレビューで編集された1枚目の画像 + 残りの画像
  List<Uint8List> finalImagesToSend = [previewResult.imageBytes];
  
  // 2枚目以降の読み込み
  if (processedImagePaths.length > 1) {
    if (context.mounted) _showLoadingDialog(context, '画像を準備中... (2/${processedImagePaths.length})');
    try {
      for (int i = 1; i < processedImagePaths.length; i++) {
        if (!context.mounted) break;
        if(i > 1 && context.mounted) {
            Navigator.pop(context);
           _showLoadingDialog(context, '画像を準備中... (${i + 1}/${processedImagePaths.length})');
        }

        final path = processedImagePaths[i];
        final file = File(path);
        final rawBytes = await file.readAsBytes();
        
        // PNGバイトデータをそのままリストに追加 (再エンコードなし)
        finalImagesToSend.add(rawBytes);
      }
    } finally {
       if (context.mounted) _hideLoadingDialog(context);
    }
  }

  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }

  // 5. GPT送信 & OCR解析
  List<Map<String, dynamic>?> allAiRawResults = [];
  final String companyForGpt = (selectedCompany == 'T社') ? 'TMEIC' : selectedCompany; // T社が削除されても、もしカスタム名がT社ならこれで動く

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

Future<List<List<String>>?> _processRawProductResults(
  BuildContext context,
  List<Map<String, dynamic>?> allAiRawResults,
  String selectedCompany,
) async {
  List<Map<String, String>> allExtractedProductRows = [];
  const List<String> expectedProductFields = ProductListOcrConfirmPage.productFields;

  // selectedCompanyが'T社'（今は削除済みだがカスタムで登録される可能性あり）または'TMEIC'を含むか
  final bool isTCompany = selectedCompany.contains('T社') || selectedCompany.contains('TMEIC');

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
    for (int i = 0; i < nifudaHeader.length; i++) { 
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

Future<String?> exportDataToStorageAction({
  required BuildContext context,
  required String projectTitle,
  required String projectFolderPath,
  required List<List<String>> nifudaData,
  required List<List<String>> productListData,
  required Map<String, dynamic> matchingResults,
  required String currentCaseNumber,
  required String? jsonSavePath,
  required String inspectionStatus,
}) async {
  if (!context.mounted) return null;
  _showLoadingDialog(context, '共有フォルダ(SMB)へ保存中です...');

  try {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      if (!statuses[Permission.storage]!.isGranted && !statuses[Permission.manageExternalStorage]!.isGranted) {
        throw Exception('ストレージへのアクセス権限が拒否されました。 (Storage: ${statuses[Permission.storage]}, Manage: ${statuses[Permission.manageExternalStorage]})');
      }
    }

    final finalJsonPath = await saveProjectAction(
      context,
      projectFolderPath,
      projectTitle,
      nifudaData,
      productListData,
      currentCaseNumber,
      jsonSavePath,
      (_) {},
    );
    if (finalJsonPath == null) {
       throw Exception('JSONデータファイルの最終保存に失敗しました。');
    }

    List<Future<Map<String, String>>> excelExports = [];

    final String excelSubfolder = '最終エクスポート/Excel';
    
    final nifudaFileName = 'Nifuda_All_Cases.xlsx';
    final productListFileName = 'ProductList_All.xlsx';
    final matchingResultFileName = 'MatchingResult_All.xlsx';

    final allMatchedData = (matchingResults['matched'] as List).cast<Map<String, dynamic>>();
    final allUnmatchedData = (matchingResults['unmatched'] as List).cast<Map<String, dynamic>>();
    final matchingHeaders = [
        '照合結果', '荷札_製番', '荷札_項目番号', '荷札_品名', '製品_ORDER No.', '製品_品名記号', '製品_製品コード番号', '照合済Case', '照合Case'
    ];
    final List<List<String>> matchingRows = [
      ...allMatchedData.map((m) => <String>[
          '照合成功',
          m['nifuda']?['製番']?.toString() ?? '', m['nifuda']?['項目番号']?.toString() ?? '', m['nifuda']?['品名']?.toString() ?? '',
          m['product']?['ORDER No.']?.toString() ?? '', 
          m['product']?['品名記号']?.toString() ?? '', 
          m['product']?['製品コード番号']?.toString() ?? '',
          m['product']?['照合済Case']?.toString() ?? '', m['nifuda']?['Case No.']?.toString() ?? '',
      ]),
      ...allUnmatchedData.map((u) => <String>[
          '照合失敗',
          u['nifuda']?['製番']?.toString() ?? '', u['nifuda']?['項目番号']?.toString() ?? '', u['nifuda']?['品名']?.toString() ?? '',
          '', '', '', '', 
          u['nifuda']?['Case No.']?.toString() ?? '', 
      ]),
    ];

    excelExports.add(exportToExcelStorage(
      fileName: nifudaFileName,
      sheetName: '荷札リスト',
      headers: nifudaData.first,
      rows: nifudaData.sublist(1),
      projectFolderPath: projectFolderPath,
      subfolder: excelSubfolder,
      skipPermissionCheck: true,
    ));

    excelExports.add(exportToExcelStorage(
      fileName: productListFileName,
      sheetName: '製品リスト',
      headers: productListData.first,
      rows: productListData.sublist(1),
      projectFolderPath: projectFolderPath,
      subfolder: excelSubfolder,
      skipPermissionCheck: true,
    ));

    excelExports.add(exportToExcelStorage(
      fileName: matchingResultFileName,
      sheetName: '照合結果',
      headers: matchingHeaders,
      rows: matchingRows,
      projectFolderPath: projectFolderPath,
      subfolder: excelSubfolder,
      skipPermissionCheck: true,
    ));

    final results = await Future.wait(excelExports);

    String localMessages = results.map((r) => r['local']).where((m) => m?.isNotEmpty ?? false).join(', ');
    String smbMessages = results.map((r) => r['smb']).where((m) => m?.isNotEmpty ?? false).join('; ');

    _hideLoadingDialog(context);

    String successMessage = "検品完了＆共有フォルダ(SMB)への保存が完了しました。\n\n";
    successMessage += "・JSONデータ: " + p.basename(finalJsonPath) + "を最終保存\n";
    successMessage += "・Excelエクスポート結果: ローカル($localMessages), SMB($smbMessages)\n";

    if (context.mounted) {
       _showErrorDialog(context, '共有フォルダ(SMB)へ保存', successMessage);
    }

    FlutterLogs.logInfo('PROJECT_ACTION', 'EXPORT_SMB_SUCCESS', 'Project $projectTitle exported to SMB.');

    return STATUS_COMPLETED;

  } catch (e, s) {
    if(context.mounted) _hideLoadingDialog(context);
    _logError('PROJECT_ACTION', 'EXPORT_SMB_FAIL', e, s);
    if (context.mounted) {
      _showErrorDialog(context, 'SMB保存エラー', '共有フォルダへの保存に失敗しました: ${e.toString()}');
    }
    return null;
  }
}

Future<String?> shareDataViaAppsAction({
  required BuildContext context,
  required String projectTitle,
  required String projectFolderPath,
  required List<List<String>> nifudaData,
  required List<List<String>> productListData,
  required Map<String, dynamic> matchingResults,
  required String currentCaseNumber,
  required String? jsonSavePath,
  required String inspectionStatus,
}) async {
  if (!context.mounted) return null;
  _showLoadingDialog(context, '共有ファイルを作成中です...');

  final Directory tempDir = await getTemporaryDirectory();
  final String tempPath = tempDir.path;

  try {
    final String tempJsonPath = p.join(tempPath, '$projectTitle.json');
    final finalJsonPath = await saveProjectAction(
      context,
      projectFolderPath,
      projectTitle,
      nifudaData,
      productListData,
      currentCaseNumber,
      jsonSavePath,
      (_) {}, 
      customSavePath: tempJsonPath,
    );
    if (finalJsonPath == null) {
       throw Exception('一時JSONデータファイルの作成に失敗しました。');
    }

    List<Future<Map<String, String>>> excelExports = [];

    final String excelSubfolder = ''; 
    final String excelBasePath = tempPath;
    
    final nifudaFileName = 'Nifuda_All_Cases.xlsx';
    final productListFileName = 'ProductList_All.xlsx';
    final matchingResultFileName = 'MatchingResult_All.xlsx';

    final allMatchedData = (matchingResults['matched'] as List).cast<Map<String, dynamic>>();
    final allUnmatchedData = (matchingResults['unmatched'] as List).cast<Map<String, dynamic>>();
    final matchingHeaders = [
        '照合結果', '荷札_製番', '荷札_項目番号', '荷札_品名', '製品_ORDER No.', '製品_品名記号', '製品_製品コード番号', '照合済Case', '照合Case'
    ];
    final List<List<String>> matchingRows = [
      ...allMatchedData.map((m) => <String>[
          '照合成功',
          m['nifuda']?['製番']?.toString() ?? '', m['nifuda']?['項目番号']?.toString() ?? '', m['nifuda']?['品名']?.toString() ?? '',
          m['product']?['ORDER No.']?.toString() ?? '', 
          m['product']?['品名記号']?.toString() ?? '', 
          m['product']?['製品コード番号']?.toString() ?? '',
          m['product']?['照合済Case']?.toString() ?? '', m['nifuda']?['Case No.']?.toString() ?? '',
      ]),
      ...allUnmatchedData.map((u) => <String>[
          '照合失敗',
          u['nifuda']?['製番']?.toString() ?? '', u['nifuda']?['項目番号']?.toString() ?? '', u['nifuda']?['品名']?.toString() ?? '',
          '', '', '', '', 
          u['nifuda']?['Case No.']?.toString() ?? '', 
      ]),
    ];

    excelExports.add(exportToExcelStorage(
      fileName: nifudaFileName,
      sheetName: '荷札リスト',
      headers: nifudaData.first,
      rows: nifudaData.sublist(1),
      projectFolderPath: excelBasePath, 
      subfolder: excelSubfolder,       
      skipPermissionCheck: true,     
    ));

    excelExports.add(exportToExcelStorage(
      fileName: productListFileName,
      sheetName: '製品リスト',
      headers: productListData.first,
      rows: productListData.sublist(1),
      projectFolderPath: excelBasePath,
      subfolder: excelSubfolder,
      skipPermissionCheck: true,
    ));

    excelExports.add(exportToExcelStorage(
      fileName: matchingResultFileName,
      sheetName: '照合結果',
      headers: matchingHeaders,
      rows: matchingRows,
      projectFolderPath: excelBasePath,
      subfolder: excelSubfolder,
      skipPermissionCheck: true,
    ));

    await Future.wait(excelExports);

    final List<XFile> filesToShare = [
      XFile(finalJsonPath), 
      XFile(p.join(excelBasePath, nifudaFileName)), 
      XFile(p.join(excelBasePath, productListFileName)),
      XFile(p.join(excelBasePath, matchingResultFileName)), 
    ];

    _hideLoadingDialog(context);

    final shareResult = await Share.shareXFiles(
      filesToShare,
      subject: '検品データ共有: $projectTitle', 
      text: '$projectTitle の検品データ（JSON, 荷札Excel, 製品リストExcel, 照合結果Excel）を共有します。', 
    );

    String successMessage = "検品完了＆アプリ共有が完了しました。\n\n";
    successMessage += "・一時ファイルを作成し、共有ダイアログを起動しました。\n";
    successMessage += "・共有ステータス: ${shareResult.status.name}";

    if (context.mounted) {
       _showErrorDialog(context, 'アプリ(LINE/Gmail)で共有', successMessage);
    }

    FlutterLogs.logInfo('PROJECT_ACTION', 'EXPORT_SHARE_SUCCESS', 'Project $projectTitle shared via Apps (Status: ${shareResult.status.name}).');

    return STATUS_COMPLETED;

  } catch (e, s) {
    if(context.mounted) _hideLoadingDialog(context);
    _logError('PROJECT_ACTION', 'EXPORT_SHARE_FAIL', e, s);
    if (context.mounted) {
      _showErrorDialog(context, 'アプリ共有エラー', 'アプリでの共有に失敗しました: ${e.toString()}');
    }
    return null;
  }
}


void showAndExportProductListAction(
  BuildContext context,
  List<List<String>> productListData,
  String projectFolderPath,
) {
  if (productListData.isEmpty) {
     _showErrorDialog(context, 'データなし', '製品リストデータが空です。');
     return;
  }

  if (productListData.length <= 1) {
    _showErrorDialog(context, 'データなし', '表示する製品リストデータがありません。');
    return;
  }

  showDialog(
    context: context,
    builder: (_) => ExcelPreviewDialog(
      title: '製品リスト (全体)', 
      data: productListData, 
      headers: productListData.first, 
      projectFolderPath: projectFolderPath,
      subfolder: '製品リスト', 
    ),
  );
}