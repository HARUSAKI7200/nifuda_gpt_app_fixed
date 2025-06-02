// lib/pages/camera_capture_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:media_scanner/media_scanner.dart';

import '../utils/gpt_service.dart';
import '../widgets/custom_snackbar.dart';

class CameraCapturePage extends StatefulWidget {
  final String overlayText;
  final double overlayWidthRatio;
  final double overlayHeightRatio;
  final bool isProductListOcr;
  final String? companyForGpt;
  final String projectFolderPath; // 追加

  const CameraCapturePage({
    super.key,
    this.overlayText = '枠内に対象を収めてください',
    this.overlayWidthRatio = 0.9,
    this.overlayHeightRatio = 0.4,
    required this.isProductListOcr,
    this.companyForGpt,
    required this.projectFolderPath, // 追加
  });

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  bool _isProcessingImage = false;

  final List<Future<Map<String, dynamic>?>> _gptResultFutures = [];
  int _requestedImageCount = 0;
  int _respondedImageCount = 0;
  OverlayEntry? _flashOverlay;

  Rect _cameraPreviewAreaOnScreen = Rect.zero;
  Rect _overlayRectOnScreen = Rect.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _flashOverlay?.remove();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _errorMessage = '利用可能なカメラが見つかりません。');
        return;
      }
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } on CameraException catch (e) {
      if (mounted) setState(() => _errorMessage = 'カメラ初期化エラー: ${e.description}');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '予期せぬカメラエラー: $e');
    }
  }

  void _showFlashEffect() {
    _flashOverlay?.remove();
    _flashOverlay = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(child: Container(color: Colors.white.withOpacity(0.5))),
      ),
    );
    Overlay.of(context).insert(_flashOverlay!);
    Future.delayed(const Duration(milliseconds: 120), () {
      _flashOverlay?.remove();
      _flashOverlay = null;
    });
  }

  Future<String?> _saveCroppedImage(Uint8List imageBytes, String fileName) async {
    if (!Platform.isAndroid) {
      debugPrint("この画像保存方法はAndroid専用です。");
      return null;
    }
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      if (!await Permission.manageExternalStorage.request().isGranted) {
        throw Exception('ストレージへのアクセス権限がありません。');
      }
    }
    try {
      // 保存パスを projectFolderPath/荷札画像 に変更
      final String albumPath = p.join(widget.projectFolderPath, "荷札画像");
      final Directory albumDir = Directory(albumPath);
      if (!await albumDir.exists()) {
        await albumDir.create(recursive: true);
      }
      final File file = File(p.join(albumDir.path, fileName));
      await file.writeAsBytes(imageBytes);
      await MediaScanner.loadMedia(path: file.path);
      // メッセージ用にパスを短縮
      return p.join(p.basename(widget.projectFolderPath), "荷札画像", fileName);
    } catch (e) {
      debugPrint('画像保存エラー: $e');
      throw Exception('画像保存に失敗しました: $e');
    }
  }

  Future<void> _takeAndProcessImage(BuildContext layoutContext) async {
    if (!_isCameraInitialized || _controller == null || _controller!.value.isTakingPicture || _isProcessingImage || !_controller!.value.isInitialized) {
      return;
    }
    if (_cameraPreviewAreaOnScreen.isEmpty || _overlayRectOnScreen.isEmpty) {
         if(mounted) showTopSnackBar(layoutContext, 'レイアウト計算待機中。');
        return;
    }

    if (mounted) setState(() => _isProcessingImage = true);
    _showFlashEffect();

    try {
      final XFile imageFile = await _controller!.takePicture();
      final Uint8List originalImageBytes = await imageFile.readAsBytes();
      
      img.Image? originalImage = img.decodeImage(originalImageBytes);
      if (originalImage == null) throw Exception("画像デコード失敗");
      
      final img.Image orientedImage = img.bakeOrientation(originalImage);
      
      final int imgW = orientedImage.width;
      final int imgH = orientedImage.height;

      final double scaleX = imgW / _cameraPreviewAreaOnScreen.width;
      final double scaleY = imgH / _cameraPreviewAreaOnScreen.height;

      final double overlayLocalX = _overlayRectOnScreen.left - _cameraPreviewAreaOnScreen.left;
      final double overlayLocalY = _overlayRectOnScreen.top - _cameraPreviewAreaOnScreen.top;

      int cropX = (overlayLocalX * scaleX).round();
      int cropY = (overlayLocalY * scaleY).round();
      int cropW = (_overlayRectOnScreen.width * scaleX).round();
      int cropH = (_overlayRectOnScreen.height * scaleY).round();
      
      final int finalCropX = cropX.clamp(0, imgW - cropW < 0 ? imgW : imgW - cropW).round();
      final int finalCropY = cropY.clamp(0, imgH - cropH < 0 ? imgH : imgH - cropH).round();
      final int finalCropW = cropW.clamp(1, imgW - finalCropX).round();
      final int finalCropH = cropH.clamp(1, imgH - finalCropY).round();

      if (finalCropW <= 0 || finalCropH <= 0) {
        debugPrint("--- Invalid Crop Calculation ---");
        debugPrint("Raw Image: ${imgW}x$imgH");
        debugPrint("Camera Preview Rect on Screen: $_cameraPreviewAreaOnScreen");
        debugPrint("Overlay Rect on Screen: $_overlayRectOnScreen");
        debugPrint("Scale factors: scaleX=$scaleX, scaleY=$scaleY");
        debugPrint("Overlay Local Coords (relative to cam preview): X=${overlayLocalX.round()}, Y=${overlayLocalY.round()}");
        debugPrint("Calculated Crop Box (img coords): x=$cropX, y=$cropY, w=$cropW, h=$cropH");
        throw Exception("Invalid crop dimensions after clamp: W=$finalCropW, H=$finalCropH.");
      }
      
      debugPrint("--- Cropping Parameters ---");
      debugPrint("Original Image (oriented): ${imgW}x$imgH");
      debugPrint("Camera Preview Rect on Screen: $_cameraPreviewAreaOnScreen");
      debugPrint("Overlay Rect on Screen: $_overlayRectOnScreen");
      debugPrint("Scale factors (img_px / screen_preview_px): scaleX=$scaleX, scaleY=$scaleY");
      debugPrint("Overlay Local Coords (relative to cam preview): X=${overlayLocalX.round()}, Y=${overlayLocalY.round()}");
      debugPrint("Calculated Crop Box (img coords): x=$cropX, y=$cropY, w=$cropW, h=$cropH");
      debugPrint("Final Clamped Crop Box (img coords): x=$finalCropX, y=$finalCropY, w=$finalCropW, h=$finalCropH");
      debugPrint("--------------------------");

      final img.Image croppedImage = img.copyCrop(
          orientedImage,
          x: finalCropX,
          y: finalCropY,
          width: finalCropW,
          height: finalCropH,
      );
      
      final Uint8List bytesForProcessing = Uint8List.fromList(img.encodeJpg(croppedImage));

      if(mounted) setState(() => _requestedImageCount++);

      final gptFuture = sendImageToGPT(
        bytesForProcessing,
        isProductList: widget.isProductListOcr,
        company: widget.isProductListOcr ? (widget.companyForGpt ?? 'none') : 'none',
      ).then<Map<String, dynamic>?>((result) {
        if (mounted) setState(() => _respondedImageCount++);
        return result;
      }).catchError((error) {
        if (mounted) setState(() => _respondedImageCount++);
        debugPrint("GPT処理エラー: $error");
        return null;
      });
      _gptResultFutures.add(gptFuture);
      
      final String fileName = 'nifuda_cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _saveCroppedImage(bytesForProcessing, fileName).then((savedPath) {
          if (savedPath != null && mounted) {
              showTopSnackBar(layoutContext, '画像を保存しました: $savedPath');
          }
      }).catchError((e) {
          if (mounted) {
              showTopSnackBar(layoutContext, '画像保存エラー: ${e.toString()}', isError: true);
          }
      });
      
    } catch (e, s) {
      debugPrint('撮影または処理エラー: $e');
      debugPrintStack(stackTrace: s);
      if (mounted) showTopSnackBar(layoutContext, '撮影または処理に失敗: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }

  Future<void> _finishCapturingAndPop() async {
    if (_requestedImageCount == 0) {
        Navigator.pop(context, <Map<String, dynamic>>[]);
        return;
    }
    if (_requestedImageCount != _respondedImageCount) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('処理が完了していません'),
          content: Text('$_requestedImageCount件中、$_respondedImageCount件の処理のみ完了しています。このまま終了しますか？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('待機')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('終了')),
          ],
        )
      );
      if(proceed != true) return;
    }
    if (mounted) setState(() => _isProcessingImage = true);
    List<Map<String, dynamic>> validResults = [];
    final allRawResults = await Future.wait(_gptResultFutures);
    for (final result in allRawResults) {
        if (result != null) {
            validResults.add(result);
        }
    }
    if (mounted) {
      Navigator.pop(context, validResults);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double buttonBottomPadding = 90.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.isProductListOcr ? '製品リスト連続撮影' : '荷札連続撮影')),
      body: Builder( 
        builder: (layoutContext) { 
          return Stack(
            children: [
              _buildCameraPreview(layoutContext), 
              if (_isProcessingImage && _requestedImageCount != _respondedImageCount)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Text('画像処理中... ($_respondedImageCount / $_requestedImageCount)', style: const TextStyle(color: Colors.white, fontSize: 17)),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: buttonBottomPadding,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Text('結果: $_respondedImageCount / $_requestedImageCount 枚', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera_enhance_rounded),
                              label: const Text('撮影＆送信'),
                              onPressed: _isProcessingImage ? null : () => _takeAndProcessImage(layoutContext),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline_rounded),
                              label: const Text('撮影終了'),
                              onPressed: _finishCapturingAndPop,
                               style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext layoutContext) {
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 18)));
    }
    if (!_isCameraInitialized || _controller == null || !_controller!.value.isInitialized || _controller!.value.previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final cameraPreviewWidth = _controller!.value.previewSize!.height;
        final cameraPreviewHeight = _controller!.value.previewSize!.width;
        final cameraAspectRatio = cameraPreviewWidth / cameraPreviewHeight;

        final FittedSizes fittedSizes = applyBoxFit(
          BoxFit.contain,
          Size(cameraPreviewWidth, cameraPreviewHeight),
          Size(screenWidth, screenHeight)
        );

        _cameraPreviewAreaOnScreen = Rect.fromLTWH(
          (screenWidth - fittedSizes.destination.width) / 2,
          (screenHeight - fittedSizes.destination.height) / 2,
          fittedSizes.destination.width,
          fittedSizes.destination.height
        );
        
        final actualOverlayWidth = _cameraPreviewAreaOnScreen.width * widget.overlayWidthRatio;
        final actualOverlayHeight = _cameraPreviewAreaOnScreen.height * widget.overlayHeightRatio;

        _overlayRectOnScreen = Rect.fromLTWH(
          _cameraPreviewAreaOnScreen.left + (_cameraPreviewAreaOnScreen.width - actualOverlayWidth) / 2,
          _cameraPreviewAreaOnScreen.top + (_cameraPreviewAreaOnScreen.height - actualOverlayHeight) / 2,
          actualOverlayWidth,
          actualOverlayHeight
        );

        return Stack(
            alignment: Alignment.topLeft,
            children: [
              Positioned.fromRect(
                rect: _cameraPreviewAreaOnScreen,
                child: CameraPreview(_controller!),
              ),
              Positioned.fromRect(
                rect: _overlayRectOnScreen,
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 2.5)),
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black.withOpacity(0.6),
                      child: Text(widget.overlayText, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ),
              ),
            ],
          );
      }
    );
  }
}