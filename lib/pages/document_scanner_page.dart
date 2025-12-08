// lib/pages/document_scanner_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:image/image.dart' as img_lib;

import '../utils/document_scanner_util.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/ocr_masker.dart';
import '../utils/keyword_detector.dart';

class DocumentScannerPage extends StatefulWidget {
  final int maxPages;
  final String maskTemplate; // 'T社', '動的マスク処理', 'マスク処理なし'

  const DocumentScannerPage({
    super.key, 
    this.maxPages = 100,
    required this.maskTemplate,
  });

  @override
  State<DocumentScannerPage> createState() => _DocumentScannerPageState();
}

class _DocumentScannerPageState extends State<DocumentScannerPage> with WidgetsBindingObserver {
  CameraController? _controller;
  final List<String> _capturedImages = [];
  
  bool _isProcessing = false; // 検出処理中フラグ
  bool _isCapturing = false;  // 撮影・保存処理中フラグ
  
  List<Point<double>>? _detectedQuad; // 正規化された検出座標(0.0-1.0)
  
  Timer? _stabilityTimer;
  int _stabilityCounter = 0;
  static const int _stabilityThreshold = 5; // 安定判定フレーム数

  // バックグラウンド処理用のキュー（撮影後の処理待ち数）
  int _backgroundProcessingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller?.dispose();
    _stabilityTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      if (Platform.isAndroid) {
        await _controller!.setFocusMode(FocusMode.auto);
      }
      
      if (mounted) {
        setState(() {});
        _startImageStream();
      }
    } catch (e) {
      print('Camera init error: $e');
    }
  }

  void _startImageStream() {
    int frameCount = 0;
    _controller?.startImageStream((CameraImage image) {
      frameCount++;
      // 5フレームに1回検出処理
      if (frameCount % 5 != 0) return;
      if (_isProcessing || _isCapturing) return;

      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!mounted) return;
    _isProcessing = true;
    try {
      Uint8List bytes;
      int width, height;

      if (Platform.isAndroid && image.format.group == ImageFormatGroup.yuv420) {
        bytes = image.planes[0].bytes;
        width = image.width;
        height = image.height;
      } else if (Platform.isIOS && image.format.group == ImageFormatGroup.bgra8888) {
        bytes = image.planes[0].bytes;
        width = image.width;
        height = image.height;
      } else {
        _isProcessing = false;
        return;
      }

      // Isolateで検出を実行
      final normalizedPoints = await compute(_detectQuadInIsolate, _DetectRequest(bytes, width, height));

      if (mounted) {
        setState(() {
          _detectedQuad = normalizedPoints; // 描画用に保存
          if (normalizedPoints != null) {
            _stabilityCounter++;
          } else {
            _stabilityCounter = 0;
          }
        });

        // 自動撮影ロジックを有効にする場合は以下をコメントイン
        // if (_stabilityCounter >= _stabilityThreshold && !_isCapturing) {
        //   _captureDocument();
        // }
      }
    } catch (e) {
      print("Detection error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // 撮影実行
  Future<void> _captureDocument() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;
    
    setState(() {
      _isCapturing = true;
      _backgroundProcessingCount++; // 処理中カウントアップ
    });
    HapticFeedback.mediumImpact();

    try {
      // 1. 撮影 (高画質)
      final XFile rawFile = await _controller!.takePicture();
      final rawBytes = await rawFile.readAsBytes();

      // 2. 非同期で画像処理（切り抜き・マスク）を実行してリストに追加
      final processedPath = await _processImageInBackground(rawBytes, widget.maskTemplate);

      if (mounted && processedPath != null) {
        setState(() {
          _capturedImages.add(processedPath);
          _stabilityCounter = 0;
          _backgroundProcessingCount--;
        });
        showCustomSnackBar(context, '保存しました (${_capturedImages.length}枚目)', showAtTop: true, durationSeconds: 1);
      } else {
        setState(() => _backgroundProcessingCount--);
      }

    } catch (e) {
      print('Capture error: $e');
      setState(() => _backgroundProcessingCount--);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // バックグラウンドでの画像処理 (切り抜き + マスク)
  Future<String?> _processImageInBackground(Uint8List rawBytes, String template) async {
    try {
      // A. 輪郭検出
      final List<cv.Point>? contours = await DocumentScannerUtil.detectContour(rawBytes);
      
      Uint8List targetBytes = rawBytes;
      
      // B. 透視変換 (切り抜き)
      if (contours != null) {
        final warped = await DocumentScannerUtil.perspectiveTransform(rawBytes, contours);
        if (warped != null) {
          targetBytes = warped;
        }
      }

      // C. マスク処理の適用 (ocr_masker.dart 使用)
      // 画像デコード
      img_lib.Image? imageObj = img_lib.decodeImage(targetBytes);
      if (imageObj == null) return null;

      // テンプレート判定
      String internalTemplateName = 'none';
      if (template == 'T社') internalTemplateName = 't';
      else if (template == '動的マスク処理') internalTemplateName = 'dynamic';

      // マスク適用
      if (internalTemplateName == 't') {
        // T社定型マスク
        imageObj = applyMaskToImage(imageObj, template: 't');
      } else if (internalTemplateName == 'dynamic') {
        // 動的マスク (ML Kitでキーワード検出 -> マスク)
        final tempDir = await getTemporaryDirectory();
        final tempOcrPath = '${tempDir.path}/temp_ocr_analysis_${DateTime.now().microsecondsSinceEpoch}.jpg';
        await File(tempOcrPath).writeAsBytes(targetBytes);
        
        final defaultKeywords = [
          '東芝', '東芝エネルギーシステムズ', '東芝インフラシステムズ', '東芝エレベータ',
          '東芝プラントシステム', '東芝インフラテクノサービス', '東芝システムテクノロジー',
          '東芝ITコントロールシステム', '東芝EIコントロールシステム', '東芝ディーエムエス',
          'TMEIC', '東芝三菱電機産業システム',
        ];
        
        final rects = await KeywordDetector.detectKeywords(tempOcrPath, defaultKeywords);
        
        if (rects.isNotEmpty) {
           imageObj = applyMaskToImage(imageObj, template: 'dynamic', dynamicMaskRects: rects);
        }
        File(tempOcrPath).delete().ignore();
      }

      // D. 保存
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = '${tempDir.path}/scan_processed_$timestamp.jpg';
      
      // JPEGエンコード (画質100)
      await File(savedPath).writeAsBytes(img_lib.encodeJpg(imageObj, quality: 100));
      
      return savedPath;

    } catch (e) {
      print("Background processing error: $e");
      return null;
    }
  }

  void _onDone() {
    if (_backgroundProcessingCount > 0) {
      showCustomSnackBar(context, '処理中の画像があります。少々お待ちください...', isError: true);
      return;
    }
    Navigator.pop(context, _capturedImages);
  }

  void _onRetake() {
    if (_capturedImages.isNotEmpty) {
      setState(() {
        final removed = _capturedImages.removeLast();
        File(removed).delete().ignore();
      });
      showCustomSnackBar(context, '1枚削除しました。残り: ${_capturedImages.length}枚', showAtTop: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. カメラプレビュー
          CameraPreview(_controller!),

          // 2. 検出枠の描画
          if (_detectedQuad != null)
            CustomPaint(
              painter: QuadPainter(
                points: _detectedQuad!,
                color: Colors.blueAccent,
                strokeWidth: 3.0,
              ),
              child: Container(),
            ),

          // 3. UIオーバーレイ
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 上部バー
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.black45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context, null),
                      ),
                      Text(
                        '${_capturedImages.length} 枚',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 48), 
                    ],
                  ),
                ),

                // 下部コントロール
                Container(
                  padding: const EdgeInsets.only(bottom: 30, top: 20),
                  color: Colors.black38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 戻る (Retake)
                      IconButton(
                        icon: const Icon(Icons.undo, color: Colors.white, size: 32),
                        onPressed: _capturedImages.isNotEmpty ? _onRetake : null,
                        tooltip: "直前を削除",
                      ),

                      // シャッターボタン
                      GestureDetector(
                        onTap: _captureDocument,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: Colors.transparent,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: _isCapturing
                                ? const CircularProgressIndicator(color: Colors.blue)
                                : null,
                          ),
                        ),
                      ),
                      
                      // 完了ボタン
                      ElevatedButton.icon(
                        onPressed: _capturedImages.isNotEmpty ? _onDone : null,
                        icon: const Icon(Icons.check),
                        label: const Text("完了"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_backgroundProcessingCount > 0 && !_isCapturing)
             Positioned(
               top: 100, left: 0, right: 0,
               child: Center(
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                   child: const Text("処理中...", style: TextStyle(color: Colors.white)),
                 ),
               ),
             ),
        ],
      ),
    );
  }
}

// 検出枠を描画するPainter
class QuadPainter extends CustomPainter {
  final List<Point<double>> points;
  final Color color;
  final double strokeWidth;

  QuadPainter({required this.points, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length != 4) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // 正規化座標(0.0-1.0)を画面サイズに展開
    path.moveTo(points[0].x * size.width, points[0].y * size.height);
    path.lineTo(points[1].x * size.width, points[1].y * size.height);
    path.lineTo(points[2].x * size.width, points[2].y * size.height);
    path.lineTo(points[3].x * size.width, points[3].y * size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant QuadPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _DetectRequest {
  final Uint8List bytes;
  final int width;
  final int height;
  _DetectRequest(this.bytes, this.width, this.height);
}

// Isolate関数
Future<List<Point<double>>?> _detectQuadInIsolate(_DetectRequest req) async {
  // Mat.fromList(rows, cols, type, data)
  final mat = cv.Mat.fromList(req.height, req.width, cv.MatType.CV_8UC1, req.bytes);
  
  try {
    final resized = cv.resize(mat, (0, 0), fx: 0.5, fy: 0.5);
    final blurred = cv.gaussianBlur(resized, (5, 5), 0);
    final edges = cv.canny(blurred, 75, 200);
    
    final (contours, _) = cv.findContours(edges, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);
    
    // VecVecPoint -> List変換 & ソート
    final List<cv.VecPoint> contoursList = [];
    for (int i = 0; i < contours.length; i++) {
        contoursList.add(contours[i]);
    }
    contoursList.sort((a, b) => cv.contourArea(b).compareTo(cv.contourArea(a)));

    for (final c in contoursList) {
      final peri = cv.arcLength(c, true);
      final approx = cv.approxPolyDP(c, 0.02 * peri, true);

      if (approx.length == 4 && cv.contourArea(approx) > 1000) {
        final points = <Point<double>>[];
        
        for(var i=0; i<approx.length; i++) {
           final p = approx[i];
           double originalX = p.x * 2.0; 
           double originalY = p.y * 2.0;
           points.add(Point<double>(originalX / req.width, originalY / req.height));
        }
        
        // ソート: 左上, 右上, 右下, 左下
        points.sort((a, b) => a.y.compareTo(b.y));
        final top = points.sublist(0, 2)..sort((a, b) => a.x.compareTo(b.x));
        final bottom = points.sublist(2, 4)..sort((a, b) => b.x.compareTo(a.x)); // 右下, 左下

        return [...top, ...bottom];
      }
    }
    return null;
  } catch (e) {
    return null;
  } finally {
    mat.dispose();
  }
}