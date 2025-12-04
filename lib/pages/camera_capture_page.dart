// lib/pages/camera_capture_page.dart

import 'dart:async';
import 'dart:collection'; // ★ 修正: Queueのために追加
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:media_scanner/media_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // 画面向き固定用
import 'package:path_provider/path_provider.dart'; // ★ 追加: 一時ファイル保存用

import '../widgets/custom_snackbar.dart';
import '../utils/keyword_detector.dart'; // ★ 追加: キーワード検出
import '../utils/ocr_masker.dart'; // ★ 追加: 黒塗り処理

// --- 設定値 ---
class _CropConfig {
  // ★ ユーザー指定: 0.6 (画面幅の60%)
  static const double widthFactor = 0.6;

  // ★ ユーザー指定: 3.0 / 3.0 (1:1) を反映
  static const double aspectRatio = 3.0 / 3.0; // (1.0)

  // 画面中央からの縦オフセット（+で下へ, 単位は画面高さに対する割合）
  static const double verticalOffsetFactor = 0.0;

  // 枠の線幅・色など
  static const double borderWidth = 3.0;
  static const double cornerLength = 26.0;
  static const double cornerThickness = 5.0;
  static const Color borderColor = Colors.white70;
  static const Color cornerColor = Colors.lightBlueAccent;

  // マスクの暗さ
  static const double maskOpacity = 0.55;
}

// ★★★ 既存のAIサービス型定義を復元 ★★★
typedef AiServiceFunction = Future<Map<String, dynamic>?> Function(
  Uint8List imageBytes, {
  required bool isProductList,
  required String company,
  http.Client? client,
});

class CameraCapturePage extends StatefulWidget {
  final String overlayText;
  final double overlayWidthRatio;
  final double overlayHeightRatio;
  final bool isProductListOcr;
  final String? companyForGpt;
  final String projectFolderPath;
  final AiServiceFunction aiService;
  final String? caseNumber;

  const CameraCapturePage({
    super.key,
    this.overlayText = '枠内に対象を収めてください',
    this.overlayWidthRatio = 0.9,
    this.overlayHeightRatio = 0.4,
    required this.isProductListOcr,
    this.companyForGpt,
    required this.projectFolderPath,
    required this.aiService,
    this.caseNumber,
  });

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  // ★ 修正: 連続撮影とAI非同期処理のための状態
  bool _isTakingPicture = false; // 撮影ボタンの多重タップ防止
  bool _isAiProcessing = false; // AI処理キューが動作中か
  final Queue<Uint8List> _imageQueue = Queue<Uint8List>(); // AI処理待ちの画像キュー
  int _totalPhotosCount = 0; // 撮影枚数 (分母)
  int _resultsReceivedCount = 0; // AI処理完了枚数 (分子)
  final List<Map<String, dynamic>> _allGptResults = []; // AI結果の格納場所

  String? _lastError;

  // 画面上で実際にプレビューが描かれている領域（Containでの描画矩形）
  Rect _previewRectOnScreen = Rect.zero;

  // 画面上のトリミング枠（固定サイズ・中央寄せ）
  Rect _cropRectOnScreen = Rect.zero;

  // プレビューのキー（実寸取得用）
  final GlobalKey _previewKey = GlobalKey();

  // ★★★ 黒塗り対象のキーワードリスト ★★★
  // ここに隠したい単語を追加してください
  final List<String> _redactionKeywords = [
  // 東芝・府中事業所関連 (主要グループ会社)
    '東芝', // "東芝"を含むすべての社名に対応（誤検出に注意）
    '東芝エネルギーシステムズ',
    '東芝インフラシステムズ',
    '東芝エレベータ',
    '東芝プラントシステム',
    '東芝インフラテクノサービス',
    '東芝システムテクノロジー',
    '東芝ITコントロールシステム',
    '東芝EIコントロールシステム',
    '東芝ディーエムエス',
    
    // 関連企業・組織 (府中事業所内)
    'TMEIC',
    '東芝三菱電機産業システム',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ★ 修正: カメラ画面を縦画面に固定
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _initializeControllerFuture = _initCamera();
  }

  @override
  void dispose() {
    // ★ 修正: 画面の向きの固定を解除
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeControllerFuture = _initCamera();
      setState(() {});
    }
  }

  Future<void> _initCamera() async {
    // 権限チェック
    if (!await Permission.camera.request().isGranted) {
      if (mounted) {
        showCustomSnackBar(context, 'カメラのアクセス権限が拒否されました。', isError: true);
      }
      if (mounted) Navigator.pop(context);
      throw 'カメラ権限なし';
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw '利用可能なカメラが見つかりませんでした。';
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;
      await controller.initialize();

      if (Platform.isAndroid) {
        await controller.setFocusMode(FocusMode.auto);
      }

      setState(() {
        _lastError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = 'カメラ初期化に失敗しました: $e';
        });
        showCustomSnackBar(context, 'カメラ初期化に失敗しました。', isError: true);
        Navigator.pop(context);
      }
      rethrow;
    }
  }

  // --- 座標/矩形計算ロジック（Contain/ズームなし） ---

  // 画面サイズとカメラのアスペクト比を元に、Containで貼ったときの矩形を計算
  Rect _computePreviewRectOnScreen(Size screenSize) {
    // ★ 修正: プレビュー領域のアスペクト比を 1:1 に固定
    const targetAspectRatio = 1.0; // 3.0 / 3.0

    // 画面のアスペクト比
    final screenAspect = screenSize.width / screenSize.height;

    double drawWidth, drawHeight, dx, dy;

    // ★ 修正: controller.value.aspectRatio の代わりに targetAspectRatio を使う
    if (screenAspect < targetAspectRatio) {
      // 画面の方が縦長 (または 1:1 より狭い)
      drawWidth = screenSize.width;
      drawHeight = drawWidth / targetAspectRatio;
      dx = 0.0;
      dy = (screenSize.height - drawHeight) / 2.0;
    } else {
      // 画面の方が横長 (1:1 より広い)
      drawHeight = screenSize.height;
      drawWidth = drawHeight * targetAspectRatio;
      dx = (screenSize.width - drawWidth) / 2.0;
      dy = 0.0;
    }
    // 実際にプレビューが描画される領域（黒帯を含まない領域）
    return Rect.fromLTWH(dx, dy, drawWidth, drawHeight);
  }

  // 画面中央に固定サイズでトリミング枠を置く
  Rect _computeCropRectOnScreen(Size screenSize) {
    // ★ _CropConfig の値 (widthFactor = 0.6) を使用
    final cropW = screenSize.width * _CropConfig.widthFactor;
    // ★ _CropConfig の値 (aspectRatio = 1.0) を使用
    final cropH = cropW / _CropConfig.aspectRatio;
    final center = Offset(screenSize.width / 2,
        screenSize.height / 2 + screenSize.height * _CropConfig.verticalOffsetFactor);
    return Rect.fromCenter(center: center, width: cropW, height: cropH);
  }

  // --- 既存機能の再実装 ---

  // タイムスタンプ生成関数 (省略)
  String _formatTimestampForFilename(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  // ★ 修正: 画像をプロジェクトフォルダに保存する関数 (Uint8List を受け取る)
  Future<String?> _saveImageToProjectFolder(
    Uint8List imageBytes,
    String originalFileExtension, // 元のファイルの拡張子 (例: .jpg)
  ) async {
    try {
      if (widget.projectFolderPath.isEmpty) {
        throw Exception("プロジェクトフォルダパスが設定されていません。");
      }
      String subfolder;
      String fileNamePrefix;
      if (widget.isProductListOcr) {
        subfolder = "製品リスト画像";
        fileNamePrefix = "product_list";
      } else {
        final caseNo = widget.caseNumber ?? 'UnknownCase';
        subfolder = "荷札画像/$caseNo";
        fileNamePrefix = "nifuda_${caseNo.replaceAll('#', 'Case_')}";
      }
      final targetDirPath = p.join(widget.projectFolderPath, subfolder);
      final targetDir = Directory(targetDirPath);
      if (!await targetDir.exists()) await targetDir.create(recursive: true);
      final timestamp = _formatTimestampForFilename(DateTime.now());
      // ★ 修正: 拡張子を引数から取得
      final fileName = '${fileNamePrefix}_$timestamp$originalFileExtension';
      final targetFilePath = p.join(targetDir.path, fileName);

      // ★ 修正: XFile.copy() の代わりに bytes を書き込む
      final file = File(targetFilePath);
      await file.writeAsBytes(imageBytes);

      await MediaScanner.loadMedia(path: targetFilePath);
      return targetFilePath;
    } catch (e) {
      debugPrint('Error saving image to project folder: $e');
      if (mounted) {
        showCustomSnackBar(context, '画像の保存に失敗しました: $e', isError: true);
      }
      return null;
    }
  }

  // ★ 修正: 画像のクロップロジック (BoxFit.cover 座標変換ロジック)
  Future<Uint8List?> _cropImageBytes(XFile xfile) async {
    final rawBytes = await xfile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(rawBytes);
    if (originalImage == null) return null;

    if (_cropRectOnScreen == Rect.zero || _previewRectOnScreen == Rect.zero) {
      debugPrint('Warning: Crop or Preview rect is zero. Cannot crop accurately.');
      return Uint8List.fromList(img.encodeJpg(originalImage, quality: 90));
    }

    // プレビュー領域のサイズ (e.g., W=360, H=360)
    final sw = _previewRectOnScreen.width;
    final sh = _previewRectOnScreen.height;
    // ★ ターゲットのアスペクト比 (1:1 = 1.0)
    final targetAspectRatio = sw / sh;

    // 撮影された画像(originalImage)の縦向きアスペクト比を計算
    final bool isImageLandscape = originalImage.width > originalImage.height;
    // 縦向きにしたときの (W, H)
    final double iw_v = isImageLandscape
        ? originalImage.height.toDouble()
        : originalImage.width.toDouble();
    final double ih_v = isImageLandscape
        ? originalImage.width.toDouble()
        : originalImage.height.toDouble();
    // 縦向きの比率 (W_v / H_v)
    final cameraPreviewAspectRatio = iw_v / ih_v; // e.g., 3000/4000 = 0.75 (4:3)

    // プレビュー表示時のスケール（BoxFit.cover）を計算
    double scale;

    // R_cam < R_target ? (Camera THINNER) : (Camera WIDER or SAME)
    if (cameraPreviewAspectRatio < targetAspectRatio) {
      // Camera is THINNER (e.g., 4:3) than target (1:1)
      // -> Scale up to match width
      // scale = W_t / W_v
      scale = sw / iw_v;
    } else {
      // Camera is WIDER or SAME (e.g., 1:1) than target (1:1)
      // -> Scale up to match height
      // scale = H_t / H_v
      scale = sh / ih_v;
    }

    // プレビュー領域 (sw, sh) の中央と、
    // 描画された画像 (iw_v * scale, ih_v * scale) の中央のズレ (Offset)
    final dx = (sw - (iw_v * scale)) / 2.0;
    final dy = (sh - (ih_v * scale)) / 2.0;

    // 画面上のクロップ矩形 (_cropRectOnScreen) を、
    // 描画された画像(クリップ前)の左上を原点としたローカル座標に変換
    // ★ ここで _cropRectOnScreen (Configから計算された矩形) を使用
    final sx1 = (_cropRectOnScreen.left - _previewRectOnScreen.left) - dx;
    final sy1 = (_cropRectOnScreen.top - _previewRectOnScreen.top) - dy;

    // ローカル座標をスケールで割って、画像のピクセル座標 (縦向き基準) に変換
    final ix1_v = sx1 / scale;
    final iy1_v = sy1 / scale;
    final cropRectW_v = _cropRectOnScreen.width / scale;
    final cropRectH_v = _cropRectOnScreen.height / scale;

    // 画像ピクセル (縦向き基準 iw_v, ih_v) から、
    // 実際の画像 (originalImage.width, originalImage.height) の座標に変換
    int cropX, cropY, cropW, cropH;

    if (isImageLandscape) {
      // 画像は横向き (W > H)
      cropX = iy1_v.round();
      cropY = ix1_v.round();
      cropW = cropRectH_v.round();
      cropH = cropRectW_v.round();
    } else {
      // 画像は縦向き (W <= H)
      cropX = ix1_v.round();
      cropY = iy1_v.round();
      cropW = cropRectW_v.round();
      cropH = cropRectH_v.round();
    }

    // クランプ処理
    cropX = cropX.clamp(0, originalImage.width);
    cropY = cropY.clamp(0, originalImage.height);
    cropW = cropW.clamp(1, originalImage.width - cropX);
    cropH = cropH.clamp(1, originalImage.height - cropY);

    // ★ 最終的な切り抜き実行
    final croppedImage = img.copyCrop(
      originalImage,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    return Uint8List.fromList(img.encodeJpg(croppedImage, quality: 90));
  }

  // ★ 修正: 撮影アクション (連続撮影対応 + 自動黒塗り処理)
  Future<void> _onShootAndSend() async {
    if (_isTakingPicture) return; // 多重タップ防止
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _isTakingPicture = true; // 撮影中ロック
      _lastError = null;
    });

    try {
      // 1. 撮影 (元画像)
      final XFile xfile = await controller.takePicture();

      // 2. トリミング (元画像 -> トリミング後のBytes)
      final Uint8List? croppedBytes = await _cropImageBytes(xfile);

      if (croppedBytes == null) {
        if (mounted) {
          showCustomSnackBar(context, '画像クロップ中にエラーが発生しました。', isError: true);
        }
        return;
      }

      // ▼▼▼ 自動黒塗り処理の追加 ▼▼▼
      Uint8List finalBytes;
      try {
        // (1) ML Kitに渡すため一時ファイルを作成
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/temp_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(croppedBytes);

        // (2) キーワード検出 (AI)
        // ターゲットキーワードリスト (_redactionKeywords) を使用
        final List<Rect> maskRects = await KeywordDetector.detectKeywords(tempPath, _redactionKeywords);

        // (3) 黒塗り適用
        if (maskRects.isNotEmpty) {
          // バイトデータを画像オブジェクトに変換
          final img.Image? originalImage = img.decodeImage(croppedBytes);
          if (originalImage != null) {
            // 黒塗り処理 (ocr_masker.dart を再利用)
            final img.Image redactedImage = applyMaskToImage(
              originalImage,
              template: 'dynamic', // 動的マスクモード
              dynamicMaskRects: maskRects,
            );
            // 画像をバイトデータに戻す
            finalBytes = Uint8List.fromList(img.encodeJpg(redactedImage, quality: 90));
          } else {
            // デコード失敗時は元の画像を使用
            finalBytes = croppedBytes;
          }
        } else {
          // キーワードが見つからなければ元の画像を使用
          finalBytes = croppedBytes;
        }

        // 一時ファイルを削除
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

      } catch (e) {
        debugPrint('Auto-redaction failed: $e');
        // 黒塗り処理に失敗しても、最低限元の画像で続行する
        finalBytes = croppedBytes;
      }
      // ▲▲▲ 自動黒塗り処理終了 ▲▲▲


      // 3. 保存 (黒塗り後のBytesを保存)
      final originalExtension = p.extension(xfile.path);
      //    (保存も待機)
      final savedPath =
          await _saveImageToProjectFolder(finalBytes, originalExtension);

      if (savedPath == null) {
        if (mounted) {
          showCustomSnackBar(context, '画像の保存に失敗しました。', isError: true);
        }
        return;
      }

      // 4. AI処理キューに追加 (黒塗り後の画像を送信)
      setState(() {
        _totalPhotosCount++; // 分母を増やす
      });
      _imageQueue.add(finalBytes);
      
      // 5. AI処理キューの起動（AI処理自体は待たない）
      _triggerAiProcessing(); 

    } catch (e, s) {
      debugPrint('Error taking picture: $e\n$s');
      if (mounted) {
        setState(() => _lastError = '撮影エラー: $e');
        showCustomSnackBar(context, '撮影中に予期せぬエラーが発生しました。', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false; // 撮影ロック解除
        });
      }
    }
  }

  // ★ 新規: AI処理キューを1件ずつ処理する
  Future<void> _triggerAiProcessing() async {
    if (_isAiProcessing) return; // 既に処理中
    if (_imageQueue.isEmpty) return; // キューが空

    setState(() {
      _isAiProcessing = true; // AI処理中ロック
    });

    // キューの先頭を取り出す
    final bytesToProcess = _imageQueue.removeFirst();

    try {
      // 4. AI処理 (トリミング後のBytesをAIに送信)
      final result = await widget.aiService(
        bytesToProcess,
        isProductList: widget.isProductListOcr,
        company: widget.companyForGpt ?? '',
      );

      if (result != null) {
        _allGptResults.add(result);
        if (mounted) {
          // ★ 修正: スナックバーは連続撮影の邪魔なのでコメントアウト
          // showCustomSnackBar(context,
          //     '画像 #${_resultsReceivedCount + 1} のOCRが完了しました。');
        }
      } else {
        if (mounted) {
          showCustomSnackBar(context, '画像 #${_resultsReceivedCount + 1} のOCR処理に失敗しました。',
              isError: true);
        }
      }
    } catch (e, s) {
      debugPrint('Error during AI processing: $e\n$s');
      if (mounted) {
        showCustomSnackBar(
            context, '画像 #${_resultsReceivedCount + 1} のAI処理中にエラーが発生しました。',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _resultsReceivedCount++; // 分子を増やす
          _isAiProcessing = false; // AIロック解除
        });
        // 次のキューを処理
        // (AI処理完了後、少し待ってから次を処理)
        await Future.delayed(const Duration(milliseconds: 100));
        _triggerAiProcessing();
      }
    }
  }

  // ★ 新規: 撮影終了ボタンのアクション
  Future<void> _onFinishShooting() async {
    // AI処理中またはキューに未処理の画像があるか
    final bool isProcessing = _isAiProcessing || _imageQueue.isNotEmpty;

    if (isProcessing && mounted) {
      // 未処理のタスクがある場合、ユーザーに確認
      final bool? confirmExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('処理が完了していません'),
          content: Text(
              'AIの処理がまだ完了していません。(結果: $_resultsReceivedCount/$_totalPhotosCount)\n本当に撮影を終了しますか？\n(完了した分までの結果が渡されます)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('終了する'),
            ),
          ],
        ),
      );

      // キャンセルした場合
      if (confirmExit != true) {
        return;
      }
    }

    // 終了を決定
    if (mounted) {
      Navigator.pop(context, _allGptResults);
    }
  }

  // --- UIウィジェット ---

  // ★ 修正: _buildCameraPreview を Transform.scale を使う方式に変更
  Widget _buildCameraPreview() {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // ユーザー要望のターゲットアスペクト比 (1:1)
    const double targetAspectRatio = 1.0; // 3.0 / 3.0

    // カメラのプレビューアスペクト比 (縦向き)
    // (縦向き固定なので、常に 1.0 未満 (または 1.0) になるように計算)
    final cameraPreviewAspectRatio =
        (controller.value.previewSize!.height > controller.value.previewSize!.width)
            ? controller.value.previewSize!.width /
                controller.value.previewSize!.height
            : controller.value.previewSize!.height /
                controller.value.previewSize!.width;

    return Positioned.fill(
      child: Center(
        child: Container(
          key: _previewKey,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
            maxHeight: MediaQuery.of(context).size.height,
          ),
          child: AspectRatio(
            aspectRatio: targetAspectRatio, // (1:1) の枠
            child: ClipRect(
              // 枠外をクリップ
              child: LayoutBuilder(builder: (context, constraints) {
                // R_target = 1.0
                final R_cam_preview = cameraPreviewAspectRatio; // e.g., 0.75 (4:3)

                double finalScale;

                // R_cam < R_target ? (Camera THINNER) : (Camera WIDER or SAME)
                if (R_cam_preview < targetAspectRatio) {
                  // Camera is THINNER (e.g., 4:3) than target (1:1)
                  // -> Scale up to match width
                  finalScale =
                      targetAspectRatio / R_cam_preview; // e.g., 1.0 / 0.75 = 1.333
                } else {
                  // Camera is WIDER or SAME (e.g., 1:1) than target (1:1)
                  // -> Scale up to match height
                  finalScale =
                      R_cam_preview / targetAspectRatio; // e.g., 1.0 / 1.0 = 1.0
                }

                if (finalScale < 1.0) finalScale = 1.0;

                return Transform.scale(
                  scale: finalScale,
                  alignment: Alignment.center,
                  child: AspectRatio(
                    aspectRatio: cameraPreviewAspectRatio,
                    child: CameraPreview(controller),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropOverlay() {
    return IgnorePointer(
      ignoring: true,
      child: CustomPaint(
        painter: _CropOverlayPainter(
          cropRect: _cropRectOnScreen,
          maskOpacity: _CropConfig.maskOpacity,
        ),
        size: Size.infinite,
      ),
    );
  }

  // ★ 修正: ご要望のUIに合わせた新しいボトムバー
  Widget _buildCustomBottomBar() {
    // AI処理中かキューに残タスクがあるか
    final bool isProcessing = _isAiProcessing || _imageQueue.isNotEmpty;

    return SafeArea(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 結果カウンター
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isProcessing) // AI処理中のみインジケーターを表示
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                if (isProcessing) const SizedBox(width: 8),
                Text(
                  '結果: $_resultsReceivedCount / $_totalPhotosCount 枚',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左側: 撮影＆送信
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('撮影＆送信'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // 撮影中はボタンを無効化
                    onPressed: _isTakingPicture ? null : _onShootAndSend,
                  ),
                ),
                const SizedBox(width: 16),
                // 右側: 撮影終了
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('撮影終了'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _onFinishShooting,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ★ 修正: ご要望のタイトルに変更 (isProductListOcrがfalseの場合)
    final String appBarTitle =
        widget.isProductListOcr ? '製品リスト撮影' : '荷札連続撮影';

    return Scaffold(
      backgroundColor: Colors.black,
      // ★ 修正: AppBarを追加
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        // 戻るボタン (自動的に < が表示される)
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snap) {
          final isInitialized = _controller?.value.isInitialized ?? false;

          if (!isInitialized) {
            return Center(
              child: snap.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator()
                  : Text(_lastError ?? 'カメラ初期化に失敗しました。',
                      style: const TextStyle(color: Colors.white)),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // LayoutBuilder内で、画面レイアウト確定時に矩形を更新
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return; // ★ mounted チェックを追加

                // プレビュー表示サイズを取得
                final box =
                    _previewKey.currentContext?.findRenderObject() as RenderBox?;
                if (box != null) {
                  final offset = box.localToGlobal(Offset.zero);
                  final newPreviewRect = offset & box.size;

                  // 座標が更新された場合のみStateを更新
                  if (_previewRectOnScreen != newPreviewRect) {
                    setState(() {
                      _previewRectOnScreen = newPreviewRect;
                    });
                  }
                }

                // クロップ矩形を計算 (画面サイズベース)
                final screenSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                // ★ 修正: _computeCropRectOnScreen は Config (0.6, 1:1) に対応済み
                final newCropRect = _computeCropRectOnScreen(screenSize);
                if (_cropRectOnScreen != newCropRect) {
                  setState(() {
                    _cropRectOnScreen = newCropRect;
                  });
                }
              });

              return Stack(
                children: [
                  // 1. カメラプレビュー（1:1 固定、BoxFit.cover）
                  _buildCameraPreview(),

                  // 2. トリミング枠オーバーレイ (全画面を覆う)
                  Positioned.fill(child: _buildCropOverlay()),

                  // 3. UI要素
                  // エラーメッセージ
                  if (_lastError != null)
                    Positioned(
                      top: 0, // AppBarの下
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.red.withOpacity(0.7),
                            child: Text(_lastError!,
                                style:
                                    const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),

                  // ★ 修正: 新しい下部バー（カウンター/ボタン）
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildCustomBottomBar(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// 画面全体を暗くマスクし、中央の cropRect をくり抜き、枠とコーナーを描くペインター
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final double maskOpacity;

  const _CropOverlayPainter({
    required this.cropRect,
    required this.maskOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 暗幕（外側）
    paint.color = Colors.black.withOpacity(maskOpacity);
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()..addRect(cropRect);
    final mask = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(mask, paint);

    // 枠線
    final border = Paint()
      ..color = _CropConfig.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _CropConfig.borderWidth;
    canvas.drawRect(cropRect, border);

    // コーナー（L字）
    final corner = Paint()
      ..color = _CropConfig.cornerColor
      ..strokeWidth = _CropConfig.cornerThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final cl = _CropConfig.cornerLength;
    // 左上
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + Offset(cl, 0), corner);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + Offset(0, cl), corner);
    // 右上
    canvas.drawLine(cropRect.topRight, cropRect.topRight + Offset(-cl, 0), corner);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + Offset(0, cl), corner);
    // 左下
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + Offset(cl, 0), corner);
    canvas.drawLine(
        cropRect.bottomLeft, cropRect.bottomLeft + Offset(0, -cl), corner);
    // 右下
    canvas.drawLine(
        cropRect.bottomRight, cropRect.bottomRight + Offset(-cl, 0), corner);
    canvas.drawLine(
        cropRect.bottomRight, cropRect.bottomRight + Offset(0, -cl), corner);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.maskOpacity != maskOpacity;
  }
}