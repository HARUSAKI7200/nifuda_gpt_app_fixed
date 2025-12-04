// lib/pages/camera_capture_page.dart

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:media_scanner/media_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/custom_snackbar.dart';
import '../utils/keyword_detector.dart'; // 修正したKeywordDetector
import '../utils/ocr_masker.dart';

// --- 設定値 ---
class _Config {
  // 自動マスクの不透明度
  static const double maskOpacity = 0.55;
}

// AIサービスの型定義
typedef AiServiceFunction = Future<Map<String, dynamic>?> Function(
  Uint8List imageBytes, {
  required bool isProductList,
  required String company,
  http.Client? client,
});

// 処理タスクを管理するクラス
class _CaptureTask {
  final XFile rawFile;
  final int index;
  _CaptureTask(this.rawFile, this.index);
}

class CameraCapturePage extends StatefulWidget {
  final String overlayText;
  final bool isProductListOcr;
  final String? companyForGpt;
  final String projectFolderPath;
  final AiServiceFunction aiService;
  final String? caseNumber;

  // 互換性のため不要なパラメータも残していますが、内部では使用しません
  const CameraCapturePage({
    super.key,
    this.overlayText = '文字全体が入るように撮影してください',
    double overlayWidthRatio = 0.9, 
    double overlayHeightRatio = 0.4,
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

  // 撮影・処理管理用
  final Queue<_CaptureTask> _processingQueue = Queue<_CaptureTask>();
  bool _isProcessing = false; // バックグラウンド処理が走っているか
  
  int _capturedCount = 0; // 撮影した枚数
  int _processedCount = 0; // 処理（AI送信まで）完了した枚数
  final List<Map<String, dynamic>> _okResults = []; // 成功したOCR結果リスト
  
  // エラーハンドリング用
  String? _lastError;
  bool _isFinishing = false; // 終了処理中かどうか

  // 黒塗り対象キーワード
  final List<String> _redactionKeywords = [
    '東芝', '東芝エネルギーシステムズ', '東芝インフラシステムズ', '東芝エレベータ',
    '東芝プラントシステム', '東芝インフラテクノサービス', '東芝システムテクノロジー',
    '東芝ITコントロールシステム', '東芝EIコントロールシステム', '東芝ディーエムエス',
    'TMEIC', '東芝三菱電機産業システム',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // カメラ画面は縦固定
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _initializeControllerFuture = _initCamera();
  }

  @override
  void dispose() {
    // 画面の向きの固定を解除
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
    if (!await Permission.camera.request().isGranted) {
      if (mounted) showCustomSnackBar(context, 'カメラ権限が必要です。', isError: true);
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw 'カメラが見つかりません';
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
      setState(() => _lastError = null);
    } catch (e) {
      if (mounted) {
        setState(() => _lastError = 'カメラ初期化エラー: $e');
      }
    }
  }

  // --- 撮影アクション ---
  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isFinishing) return;

    try {
      // 1. 撮影（非同期でサクッと終わらせる）
      final XFile xfile = await controller.takePicture();
      
      setState(() {
        _capturedCount++;
        // キューに追加
        _processingQueue.add(_CaptureTask(xfile, _capturedCount));
      });

      // 2. バックグラウンド処理を開始（既に動いていれば無視される）
      _processQueue();

    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) showCustomSnackBar(context, '撮影エラー: $e', isError: true);
    }
  }

  // --- バックグラウンド処理ループ ---
  Future<void> _processQueue() async {
    if (_isProcessing) return; // 二重起動防止
    
    _isProcessing = true; // ロック

    while (_processingQueue.isNotEmpty) {
      if (!mounted) break;

      final task = _processingQueue.removeFirst();
      
      try {
        final Uint8List rawBytes = await task.rawFile.readAsBytes();
        
        // 一時ファイル作成 (ML Kit用)
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/temp_ocr_${task.index}.jpg';
        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(rawBytes);

        // A. 解析 (自動トリミング枠 & 黒塗り枠の検出)
        final AnalysisResult analysis = await KeywordDetector.analyzeImageForAutoCropAndRedaction(
          tempPath, 
          _redactionKeywords
        );

        // B. 画像処理 (デコード -> 黒塗り -> クロップ -> エンコード)
        final img.Image? originalImage = img.decodeImage(rawBytes);
        
        Uint8List finalBytes = rawBytes;

        if (originalImage != null) {
          // 1. 黒塗り適用 (元の画像座標で行う)
          img.Image processedImage = originalImage;
          if (analysis.redactionRects.isNotEmpty) {
             processedImage = applyMaskToImage(
               processedImage,
               template: 'dynamic',
               dynamicMaskRects: analysis.redactionRects,
             );
          }

          // 2. 自動トリミング (Content Rectがあれば)
          if (analysis.contentRect != Rect.zero) {
             // 座標のクランプ処理
             int x = analysis.contentRect.left.toInt().clamp(0, processedImage.width - 1);
             int y = analysis.contentRect.top.toInt().clamp(0, processedImage.height - 1);
             int w = analysis.contentRect.width.toInt();
             int h = analysis.contentRect.height.toInt();
             
             // はみ出し防止
             if (x + w > processedImage.width) w = processedImage.width - x;
             if (y + h > processedImage.height) h = processedImage.height - y;

             if (w > 0 && h > 0) {
                processedImage = img.copyCrop(
                  processedImage,
                  x: x, 
                  y: y, 
                  width: w, 
                  height: h
                );
             }
          }

          // 3. エンコード
          finalBytes = Uint8List.fromList(img.encodeJpg(processedImage, quality: 90));
        }

        // 一時ファイル削除
        if (await tempFile.exists()) await tempFile.delete();

        // C. 画像保存 (プロジェクトフォルダへ)
        // 拡張子は .jpg で統一
        await _saveImageToProjectFolder(finalBytes, '.jpg');

        // D. AI送信
        final result = await widget.aiService(
          finalBytes,
          isProductList: widget.isProductListOcr,
          company: widget.companyForGpt ?? '',
        );

        if (result != null) {
          _okResults.add(result);
        }

      } catch (e) {
        debugPrint('Processing error (Task ${task.index}): $e');
        // エラーでもカウントは進める（あるいはエラーリストに入れるなど）
      } finally {
        if (mounted) {
          setState(() {
            _processedCount++;
          });
        }
      }
    }

    _isProcessing = false; // ロック解除

    // 終了待機中だった場合、すべて終わったら画面を閉じる
    if (_isFinishing && _processingQueue.isEmpty && mounted) {
      Navigator.pop(context, _okResults);
    }
  }

  // --- 終了アクション ---
  void _onFinish() {
    if (_capturedCount == 0) {
      Navigator.pop(context, null);
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    if (_processingQueue.isEmpty && !_isProcessing) {
      // 処理待ちがなければ即終了
      Navigator.pop(context, _okResults);
    } else {
      // 処理中のものがあればダイアログを出して待機
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('残りの画像を処理中...\nそのままお待ちください。'),
            ],
          ),
        ),
      );
      // _processQueue の finally ブロックで Navigator.pop が呼ばれるのを待つ
    }
  }

  Future<void> _saveImageToProjectFolder(Uint8List bytes, String ext) async {
    try {
      if (widget.projectFolderPath.isEmpty) return;
      String subfolder = widget.isProductListOcr ? "製品リスト画像" : "荷札画像/${widget.caseNumber ?? 'Unknown'}";
      String prefix = widget.isProductListOcr ? "product_list" : "nifuda_${widget.caseNumber?.replaceAll('#', 'Case_') ?? ''}";
      
      final targetDir = Directory(p.join(widget.projectFolderPath, subfolder));
      if (!await targetDir.exists()) await targetDir.create(recursive: true);
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = p.join(targetDir.path, '${prefix}_$timestamp$ext');
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await MediaScanner.loadMedia(path: filePath);
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.caseNumber ?? ''} 連続撮影'),
        backgroundColor: Colors.black54,
        actions: [
          // 処理状況インジケータ
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'AI処理: $_processedCount / $_capturedCount',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
              ),
            ),
          )
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_lastError != null) {
            return Center(child: Text(_lastError!, style: const TextStyle(color: Colors.white)));
          }

          return Stack(
            children: [
              // カメラプレビュー
              Center(child: CameraPreview(_controller!)),
              
              // ガイド表示
              IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        "文字が読めるように撮影してください\n自動でトリミングされます",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 16, 
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 下部操作バー
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 撮影ボタン
                      FloatingActionButton.large(
                        heroTag: 'shutter',
                        backgroundColor: _isFinishing ? Colors.grey : Colors.white,
                        onPressed: _takePicture,
                        child: const Icon(Icons.camera, size: 50, color: Colors.black),
                      ),
                      // 完了ボタン
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text('完了 (${_okResults.length}件)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _onFinish,
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}