// lib/pages/camera_capture_page.dart

import 'dart:async';
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
import '../widgets/custom_snackbar.dart';

// --- 設定値 ---
class _CropConfig {
  // 画面幅に対する枠の横幅率（例: 0.85 = 画面幅の85%）
  static const double widthFactor = 0.85;

  // 枠のアスペクト比（幅/高さ）。例: 1.4142 = A4縦っぽい
  static const double aspectRatio = 4 / 3; // (約1.333)

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

class _CameraCapturePageState extends State<CameraCapturePage> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  
  bool _isBusy = false;
  String? _lastError;
  int _capturedImageCount = 0;
  final List<Map<String, dynamic>> _allGptResults = []; 

  // 画面上で実際にプレビューが描かれている領域（Containでの描画矩形）
  Rect _previewRectOnScreen = Rect.zero; 

  // 画面上のトリミング枠（固定サイズ・中央寄せ）
  Rect _cropRectOnScreen = Rect.zero;

  // プレビューのキー（実寸取得用）
  final GlobalKey _previewKey = GlobalKey();

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
      if (mounted) showCustomSnackBar(context, 'カメラのアクセス権限が拒否されました。', isError: true);
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
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    }

    // プレビューの横/縦の比率を取得
    final previewAspect = controller.value.aspectRatio; 
    final screenAspect = screenSize.width / screenSize.height;

    double drawWidth, drawHeight, dx, dy;

    if (screenAspect < previewAspect) {
      // 画面の方が縦長 → 幅に合わせて縮小 → 上下黒帯 (Contain)
      drawWidth = screenSize.width;
      drawHeight = drawWidth / previewAspect;
      dx = 0.0;
      dy = (screenSize.height - drawHeight) / 2.0;
    } else {
      // 画面の方が横長 → 高さにあわせて縮小 → 左右黒帯 (Contain)
      drawHeight = screenSize.height;
      drawWidth = drawHeight * previewAspect;
      dx = (screenSize.width - drawWidth) / 2.0;
      dy = 0.0;
    }
    // 実際にプレビューが描画される領域（黒帯を含まない領域）
    return Rect.fromLTWH(dx, dy, drawWidth, drawHeight);
  }

  // 画面中央に固定サイズでトリミング枠を置く
  Rect _computeCropRectOnScreen(Size screenSize) {
    final cropW = screenSize.width * _CropConfig.widthFactor;
    final cropH = cropW / _CropConfig.aspectRatio;
    final center = Offset(screenSize.width / 2, screenSize.height / 2 + screenSize.height * _CropConfig.verticalOffsetFactor);
    return Rect.fromCenter(center: center, width: cropW, height: cropH);
  }

  // 画面座標 → 画像ピクセル座標へのシンプルな線形変換 (Contain表示のためオフセット補正不要)
  Rect _mapScreenCropToImagePixels({
    required ui.Size imageSize,
    required Rect previewRectOnScreen,
    required Rect screenCropRect,
  }) {
    // 画面上のクロップ枠と、実際に描画されているプレビュー領域のサイズ比を求める
    final sw = previewRectOnScreen.width;
    final sh = previewRectOnScreen.height;
    final iw = imageSize.width.toDouble();
    final ih = imageSize.height.toDouble();

    // プレビューの描画サイズと画像のピクセルサイズの比率
    final scaleW = iw / sw;
    final scaleH = ih / sh;

    // 画面上のクロップ矩形を、プレビュー矩形左上を原点としたローカル座標に変換
    final sx1 = screenCropRect.left - previewRectOnScreen.left;
    final sy1 = screenCropRect.top - previewRectOnScreen.top;
    final sx2 = screenCropRect.right - previewRectOnScreen.left;
    final sy2 = screenCropRect.bottom - previewRectOnScreen.top;

    // 画像ピクセルに変換 (Containなので単純な比率計算)
    final ix1 = sx1 * scaleW;
    final iy1 = sy1 * scaleH;
    final ix2 = sx2 * scaleW;
    final iy2 = sy2 * scaleH;

    // 枠が撮影画像の外にはみ出していた場合に備え、クランプ
    final x1 = ix1.clamp(0.0, iw);
    final y1 = iy1.clamp(0.0, ih);
    final x2 = ix2.clamp(0.0, iw);
    final y2 = iy2.clamp(0.0, ih);

    final left = math.min(x1, x2);
    final top = math.min(y1, y2);
    final right = math.max(x1, x2);
    final bottom = math.max(y1, y2);

    return Rect.fromLTRB(left, top, right, bottom);
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

  // 画像をプロジェクトフォルダに保存する関数 (省略)
  Future<String?> _saveImageToProjectFolder(XFile xfile) async {
    try {
      if (widget.projectFolderPath.isEmpty) throw Exception("プロジェクトフォルダパスが設定されていません。");
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
      final originalExtension = p.extension(xfile.path);
      final fileName = '${fileNamePrefix}_$timestamp$originalExtension';
      final targetFilePath = p.join(targetDir.path, fileName);
      final file = File(xfile.path);
      await file.copy(targetFilePath);
      await MediaScanner.loadMedia(path: targetFilePath);
      return targetFilePath;
    } catch (e) {
      debugPrint('Error saving image to project folder: $e');
      if (mounted) showCustomSnackBar(context, '画像の保存に失敗しました: $e', isError: true);
      return null;
    }
  }
  
  // 画像のクロップロジック (Contain座標変換ロジック)
  Future<Uint8List?> _cropImageBytes(XFile xfile) async {
    final rawBytes = await xfile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(rawBytes);
    if (originalImage == null) return null;
    
    if (_cropRectOnScreen == Rect.zero || _previewRectOnScreen == Rect.zero) {
        debugPrint('Warning: Crop or Preview rect is zero. Cannot crop accurately.');
        return Uint8List.fromList(img.encodeJpg(originalImage, quality: 90));
    }

    final imageSize = ui.Size(originalImage.width.toDouble(), originalImage.height.toDouble());

    // 画面クロップ→画像ピクセルの矩形に変換 (Contain補正)
    final cropOnImage = _mapScreenCropToImagePixels(
      imageSize: imageSize,
      previewRectOnScreen: _previewRectOnScreen,
      screenCropRect: _cropRectOnScreen,
    );

    final cropX = cropOnImage.left.round();
    final cropY = cropOnImage.top.round();
    final cropW = (cropOnImage.width).round().clamp(1, originalImage.width - cropX);
    final cropH = (cropOnImage.height).round().clamp(1, originalImage.height - cropY);

    final croppedImage = img.copyCrop(
      originalImage,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );
    
    return Uint8List.fromList(img.encodeJpg(croppedImage, quality: 90));
  }


  // ★ 撮影アクション
  Future<void> _onShutter() async {
    if (_isBusy) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _isBusy = true;
      _lastError = null;
    });

    try {
      final XFile xfile = await controller.takePicture();
      final savedPath = await _saveImageToProjectFolder(xfile);
      if (savedPath == null) return;

      final croppedBytes = await _cropImageBytes(xfile);

      if (croppedBytes == null) {
        if (mounted) showCustomSnackBar(context, '画像クロップ中にエラーが発生しました。', isError: true);
        return;
      }
      
      final result = await widget.aiService(
        croppedBytes,
        isProductList: widget.isProductListOcr,
        company: widget.companyForGpt ?? '',
      );

      if (result != null) {
        _allGptResults.add(result);
        _capturedImageCount++;
        if (mounted) showCustomSnackBar(context, '画像 #${_capturedImageCount} のOCRが完了しました。');
      } else {
         if (mounted) showCustomSnackBar(context, '画像 #${_capturedImageCount + 1} のOCR処理に失敗しました。', isError: true);
      }

    } catch (e, s) {
      debugPrint('Error taking picture/OCR: $e\n$s');
      if (mounted) {
         setState(() => _lastError = '処理エラー: $e');
         showCustomSnackBar(context, '処理中に予期せぬエラーが発生しました。', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }
  
  // --- UIウィジェット ---
  
  Widget _buildCameraPreview() {
    final controller = _controller;
    final previewSize = controller?.value.previewSize;
    if (controller == null || !controller.value.isInitialized || previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Contain表示 (ズームなし)
    return Positioned.fill(
      child: Center(
        // ★ 修正: このContainerにKeyを付けて、表示サイズを取得する
        child: Container(
          key: _previewKey,
          constraints: BoxConstraints(
            // 画面サイズを最大制約として、Contain相当に表示させる
            maxWidth: MediaQuery.of(context).size.width,
            maxHeight: MediaQuery.of(context).size.height,
          ),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
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

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 完了ボタン
            ElevatedButton.icon(
              onPressed: _isBusy ? null : () {
                Navigator.pop(context, _allGptResults);
              },
              icon: const Icon(Icons.check, size: 20),
              label: Text('完了 (${_allGptResults.length}件)', style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            
            const SizedBox(width: 32),
            
            // シャッターボタン
            GestureDetector(
              onTap: _isBusy ? null : _onShutter,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isBusy ? Colors.white24 : Colors.white,
                    width: 5,
                  ),
                ),
                child: Center(
                  child: _isBusy 
                    ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.blue))
                    : Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snap) {
          final isInitialized = _controller?.value.isInitialized ?? false;
          
          if (!isInitialized) {
             return Center(
               child: snap.connectionState == ConnectionState.waiting
                   ? const CircularProgressIndicator()
                   : Text(_lastError ?? 'カメラ初期化に失敗しました。', style: const TextStyle(color: Colors.white)),
             );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // LayoutBuilder内で、画面レイアウト確定時に矩形を更新
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // プレビュー表示サイズを取得
                final box = _previewKey.currentContext?.findRenderObject() as RenderBox?;
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
                final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
                final newCropRect = _computeCropRectOnScreen(screenSize);
                if (_cropRectOnScreen != newCropRect) {
                   setState(() {
                       _cropRectOnScreen = newCropRect;
                   });
                }
              });
              
              return Stack(
                children: [
                  // 1. カメラプレビュー（Contain/ズームなし）
                  _buildCameraPreview(),

                  // 2. トリミング枠オーバーレイ (全画面を覆う)
                  Positioned.fill(child: _buildCropOverlay()),
                  
                  // 3. UI要素
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: _isBusy ? null : () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.4),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // エラーメッセージ
                  if (_lastError != null)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.red.withOpacity(0.7),
                          child: Text(_lastError!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                    ),

                  // 下部バー（シャッター/完了）
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildBottomBar(),
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
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + Offset(0, -cl), corner);
    // 右下
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + Offset(-cl, 0), corner);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + Offset(0, -cl), corner);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.maskOpacity != maskOpacity;
    }
}