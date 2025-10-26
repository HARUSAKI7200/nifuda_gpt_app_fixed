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
import 'package:permission_handler/permission_handler.dart'; // ★ 追加: パーミッション
import 'package:media_scanner/media_scanner.dart'; // ★ 追加: ギャラリースキャン

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

// --- Utility Functions (Duplicated for consistency) ---
// ( _logError, _showLoadingDialog, _hideLoadingDialog, _showErrorDialog, _logActionError, _formatTimestampForFilename, _applySharpeningFilter は変更なしのため省略 )
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
// --- End of Utility Functions ---


// ★★★ 追加: スキャンされた製品リスト画像を保存する関数 ★★★
Future<void> _saveScannedProductImages(
    BuildContext context,
    String projectFolderPath,
    List<String> sourceImagePaths) async {
  if (!Platform.isAndroid) {
    debugPrint("この画像保存方法はAndroid専用です。");
    return;
  }
  try {
    // ストレージパーミッションの確認・要求
    var status = await Permission.storage.status;
    if (!status.isGranted) status = await Permission.storage.request();
    if (!status.isGranted) {
      // Android 11以降向けの権限も確認
      if (Platform.isAndroid) {
        var externalStatus = await Permission.manageExternalStorage.status;
        if (!externalStatus.isGranted) {
          externalStatus = await Permission.manageExternalStorage.request();
        }
        if (!externalStatus.isGranted) {
          throw Exception('ストレージへのアクセス権限がありません。');
        }
      } else {
        throw Exception('ストレージへのアクセス権限がありません。');
      }
    }

    // 保存先フォルダのパスを作成 ([プロジェクトフォルダ]/製品リスト画像)
    final String targetDirPath = p.join(projectFolderPath, "製品リスト画像");
    final Directory targetDir = Directory(targetDirPath);

    // フォルダが存在しない場合は作成
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
      FlutterLogs.logInfo('IMAGE_SAVE', 'DIR_CREATED', 'Created directory: $targetDirPath');
    }

    int savedCount = 0;
    // 各画像ファイルをコピー
    for (final sourcePath in sourceImagePaths) {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        FlutterLogs.logWarn('IMAGE_SAVE', 'SOURCE_NOT_FOUND', 'Source image not found: $sourcePath');
        continue; // ソースファイルが見つからない場合はスキップ
      }

      // タイムスタンプ付きのファイル名を生成
      final timestamp = _formatTimestampForFilename(DateTime.now());
      // 元の拡張子を維持しつつ、ユニークなファイル名を生成
      final originalExtension = p.extension(sourcePath);
      final fileName = 'product_list_$timestamp$originalExtension';
      final targetFilePath = p.join(targetDir.path, fileName);

      try {
        // ファイルをコピー
        await sourceFile.copy(targetFilePath);
        // ギャラリーに反映させる
        await MediaScanner.loadMedia(path: targetFilePath);
        savedCount++;
        FlutterLogs.logInfo('IMAGE_SAVE', 'SAVE_SUCCESS', 'Saved product list image to $targetFilePath');
      } catch (e, s) {
        _logError('IMAGE_SAVE', 'COPY_ERROR', 'Failed to copy $sourcePath to $targetFilePath: $e', s);
        // 1つのファイルのコピーに失敗しても処理を続ける
      }
      // 短い待機時間を入れてファイル名の衝突を防ぐ（ミリ秒単位のタイムスタンプでも稀に衝突する可能性対策）
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
// ★★★ 保存関数ここまで ★★★


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
  // (荷札処理のコードは変更なしのため省略)
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

void showAndExportNifudaListAction(
  BuildContext context,
  List<List<String>> nifudaData,
  String projectTitle,
  String projectFolderPath,
) {
  // (荷札リスト表示・エクスポート処理は変更なしのため省略)
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
    // 1. DocumentScanner を起動して画像パスを取得
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

  // スキャンがキャンセルされたか、画像が0枚の場合
  if (imageFilePaths == null || imageFilePaths.isEmpty) {
    if (context.mounted) showCustomSnackBar(context, '製品リストのスキャンがキャンセルされました。');
    return null;
  }

  // ★★★ 2. スキャンした画像を指定フォルダに保存 ★★★
  // この処理は非同期で実行し、完了を待たずに次のステップへ進む (unawaited)
  // エラーが発生してもOCR処理は続行する
  unawaited(_saveScannedProductImages(context, projectFolderPath, imageFilePaths));
  // ★★★ 保存処理の呼び出しここまで ★★★


  // 3. 画像の読み込みと前処理 (リサイズ/シャープネス)
  List<Uint8List> rawImageBytesList = [];
  const int PERSPECTIVE_WIDTH = 1920;
  try {
    for (var path in imageFilePaths) {
      final file = File(path);
      // ★ 注意: スキャナから返されるパスのファイルは一時的なものである可能性があるため、
      // 保存処理(_saveScannedProductImages) とは別に、OCR処理用のバイトデータも読み込む。
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
    return null; // 画像読み込み/処理失敗時はOCR中断
  }
  if (rawImageBytesList.isEmpty) {
      if(context.mounted) _showErrorDialog(context, '画像処理エラー', '有効な画像が読み込めませんでした。');
      return null;
  }

  // 4. マスク処理とプレビュー
  String template;
  switch (selectedCompany) {
    case 'T社': template = 't'; break;
    case 'マスク処理なし': template = 'none'; break;
    case '動的マスク処理': template = 'dynamic'; break;
    default: if(context.mounted) _showErrorDialog(context, 'テンプレートエラー', '無効な会社名が選択されました。'); return null;
  }
  final Uint8List firstImageBytes = rawImageBytesList.first;
  if (!context.mounted) return null;
  // ★ 修正: ローディング表示はマスクプレビュー画面遷移直前に短く表示
  // _showLoadingDialog(context, 'プレビューを準備中...');
  // _hideLoadingDialog(context); // すぐ消す

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

  // 5. マスク適用後の最終画像リストを作成
  List<Uint8List> finalImagesToSend = [previewResult.imageBytes]; // 1枚目はプレビュー結果を使用
  if (rawImageBytesList.length > 1) {
    if (context.mounted) _showLoadingDialog(context, '画像を準備中... (2/${rawImageBytesList.length})');
    try {
      for (int i = 1; i < rawImageBytesList.length; i++) {
        if (!context.mounted) break; // 途中で破棄された場合
        if(i > 1 && context.mounted) { // 3枚目以降の進捗表示更新
            Navigator.pop(context); // 前のダイアログを閉じる
           _showLoadingDialog(context, '画像を準備中... (${i + 1}/${rawImageBytesList.length})');
        }

        final image = img.decodeImage(rawImageBytesList[i])!;
        img.Image maskedImage;

        if (template == 't') {
            maskedImage = applyMaskToImage(image, template: 't');
        } else if (template == 'dynamic' && dynamicMasks.isNotEmpty) {
            maskedImage = applyMaskToImage(image, template: 'dynamic', dynamicMaskRects: dynamicMasks);
        } else {
            maskedImage = image; // マスクなし
        }
        finalImagesToSend.add(Uint8List.fromList(img.encodeJpg(maskedImage, quality: 100)));
      }
    } finally {
       if (context.mounted) _hideLoadingDialog(context); // ループ後 or break後にダイアログを閉じる
    }
  }

  if (finalImagesToSend.isEmpty) {
    if(context.mounted) showCustomSnackBar(context, '処理対象の画像がありませんでした。');
    return null;
  }


  // 6. AI (GPT) へのストリーミングリクエスト実行
  List<Map<String, dynamic>?> allAiRawResults = [];
  final String companyForGpt = (selectedCompany == 'T社') ? 'TMEIC' : selectedCompany; // プロンプト用

  for (int i = 0; i < finalImagesToSend.length; i++) {
      if (!context.mounted) break;
      final imageBytes = finalImagesToSend[i];

      final Stream<String> stream = sendImageToGPTStream(
        imageBytes,
        company: companyForGpt,
      );

      final String streamTitle = '製品リスト抽出中 (GPT) (${i + 1} / ${finalImagesToSend.length})';

      // ストリーミングダイアログを表示し、結合されたJSON文字列を取得
      final String? rawJsonResponse = await StreamingProgressDialog.show(
        context: context,
        stream: stream,
        title: streamTitle,
        serviceTag: 'GPT_SERVICE'
      );

      if (rawJsonResponse == null) {
          // ストリーム失敗 or キャンセル
          _logError('OCR_ACTION', 'PRODUCT_LIST_GPT_STREAM_FAIL', 'Stream failed or cancelled for image ${i + 1}', null);
          if (context.mounted) _showErrorDialog(context, '抽出エラー', '${i + 1}枚目の画像の抽出に失敗しました。処理を中断します。');
          // 途中まででも結果があれば確認画面へ、なければ null を返す
          return allAiRawResults.isNotEmpty ? await _processRawProductResults(context, allAiRawResults, selectedCompany) : null;
      }

      // JSON パース試行
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
          allAiRawResults.add(null); // パース失敗時は null を追加
      }
  }

  // 7. 結果の統合と確認画面への遷移
  if (!context.mounted) return null; // 最終チェック
  return _processRawProductResults(context, allAiRawResults, selectedCompany);
}

// ★★★ 修正: 会社名(selectedCompany)を引数で受け取り、OrderNo生成ロジックを分岐 ★★★
Future<List<List<String>>?> _processRawProductResults(
  BuildContext context,
  List<Map<String, dynamic>?> allAiRawResults,
  String selectedCompany, // ★引数を追加
) async {
  List<Map<String, String>> allExtractedProductRows = [];
  // ★ 修正: product_list_ocr_confirm_page からフィールドリストを取得
  const List<String> expectedProductFields = ProductListOcrConfirmPage.productFields;

  final bool isTCompany = (selectedCompany == 'T社'); // ★ 簡略化: TMEIC は考慮しない (UI依存)

  for(final result in allAiRawResults){
     if (result != null && result.containsKey('products') && result['products'] is List) {
        final List<dynamic> productListRaw = result['products'];
        // AIが返す commonOrderNo (T社の場合は "QZ83941"、それ以外は "T-12345-")
        String commonOrderNo = result['commonOrderNo']?.toString() ?? '';

        for (final item in productListRaw) {
          if (item is Map) {
            Map<String, String> row = {};
            String finalOrderNo = '';

            // ★★★ Order No. 生成ロジック (再修正) ★★★
            if (isTCompany) {
              // T社の場合: commonOrderNo (QZ83941) + 備考(NOTE) (FEV2385)
              final String note = item['備考(NOTE)']?.toString() ?? '';
              finalOrderNo = '$commonOrderNo $note'.trim(); // 例: "QZ83941 FEV2385"
            } else {
              // T社以外の場合: commonOrderNo (T-12345-) + 備考(REMARKS) (01)
              final String remarks = item['備考(REMARKS)']?.toString() ?? '';
              finalOrderNo = commonOrderNo; // まずプレフィックスをセット

              // プレフィックスと枝番が両方あれば連結
              if (commonOrderNo.isNotEmpty && remarks.isNotEmpty) {
                 // プレフィックスの末尾がハイフンかスペースかチェック
                 if (commonOrderNo.endsWith('-') || commonOrderNo.endsWith(' ')) {
                     finalOrderNo = '$commonOrderNo$remarks'; // そのまま連結 T-12345-01
                 } else {
                     // 念のためスペース区切りで連結
                     finalOrderNo = '$commonOrderNo $remarks'; // 例: 12345 01
                 }
                 // さらに詳細なプレフィックス抽出ロジック（必要なら）
                 // final lastSeparatorIndex = commonOrderNo.lastIndexOf(RegExp(r'[\s-]'));
                 // if (lastSeparatorIndex != -1) {
                 //   final prefix = commonOrderNo.substring(0, lastSeparatorIndex + 1);
                 //   finalOrderNo = '$prefix$remarks'; // 例: "T-12345-" + "01"
                 // } else {
                 //   finalOrderNo = '$commonOrderNo $remarks'; // 例: "12345" + "01"
                 // }
              }
            }
            // ★★★ ロジック変更ここまで ★★★

            for (String field in expectedProductFields) {
              // 'ORDER No.' は上で生成したもの、他はAIの結果を使う
              row[field] = (field == 'ORDER No.') ? finalOrderNo : item[field]?.toString() ?? '';
            }
            allExtractedProductRows.add(row);
          }
        }
      } else {
        FlutterLogs.logWarn('OCR_ACTION', 'INVALID_AI_RESULT', 'Received null or invalid AI result structure.');
        // パースエラーは既にログ済みなのでここでは警告のみ
      }
  }

  if (allExtractedProductRows.isNotEmpty) {
      FlutterLogs.logInfo('OCR_ACTION', 'PRODUCT_LIST_CONFIRM', '${allExtractedProductRows.length} rows extracted for confirmation.');
      // 確認画面へ遷移
      return Navigator.push<List<List<String>>>(
        context, MaterialPageRoute(builder: (_) => ProductListOcrConfirmPage(extractedProductRows: allExtractedProductRows)),
      );
  } else {
      _logError('OCR_ACTION', 'PRODUCT_LIST_NO_RESULT', 'No valid product list data extracted after processing all images.', null);
      if (context.mounted) _showErrorDialog(context, 'OCR結果なし', '有効な製品リストデータが抽出されませんでした。');
      return null;
  }
}


void showAndExportProductListAction(
  BuildContext context,
  List<List<String>> productListData,
  String projectFolderPath,
) {
  // (製品リスト表示・エクスポート処理は変更なしのため省略)
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
  // (照合処理は変更なしのため省略)
  if (nifudaData.length <= 1 || productListData.length <= 1) {
    _showErrorDialog(context, 'データ不足', '照合には荷札と製品リストの両方のデータが必要です。');
    FlutterLogs.logThis(
      tag: 'MATCHING_ACTION',
      subTag: 'DATA_INSUFFICIENT',
      logMessage: 'Matching attempted with insufficient data.',
      level: LogLevel.WARNING,
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
     FlutterLogs.logThis(
       tag: 'MATCHING_ACTION',
       subTag: 'DATA_EMPTY',
       logMessage: 'Matching failed due to empty map lists.',
       level: LogLevel.WARNING,
     );
    return null;
  }

  final matchingLogic = ProductMatcher();
  final Map<String, dynamic> rawResults = matchingLogic.match(nifudaMapList, productMapList, pattern: matchingPattern);

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
    )),
  );
  if (context.mounted && newStatus != null) {
    return newStatus;
  }
  return null;
}