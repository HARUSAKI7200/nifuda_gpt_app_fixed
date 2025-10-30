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
import 'package:http/http.dart' as http;

import '../widgets/custom_snackbar.dart';

// ★★★ AIサービスを関数として受け取るための型定義（変更なし） ★★★
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
  final String? caseNumber; // ★ 追加: Case No. (荷札画像保存用)

  const CameraCapturePage({
    super.key,
    this.overlayText = '枠内に対象を収めてください',
    this.overlayWidthRatio = 0.9,
    this.overlayHeightRatio = 0.4,
    required this.isProductListOcr,
    this.companyForGpt,
    required this.projectFolderPath,
    required this.aiService,
    this.caseNumber, // ★ 追加
  });

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  int _capturedImageCount = 0;
  final List<Map<String, dynamic>> _allGptResults = [];
  final List<String> _capturedFilePaths = []; // 撮影したファイルのパスを保持

  // カメラプレビューとオーバーレイのサイズを計算するためのグローバルキー
  final GlobalKey _cameraPreviewKey = GlobalKey();
  Rect _cameraPreviewAreaOnScreen = Rect.zero;
  Rect _overlayRectOnScreen = Rect.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
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
      _initializeController(cameraController.description);
    }
  }

  Future<void> _initializeCamera() async {
    // 権限チェック
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) showCustomSnackBar(context, 'カメラのアクセス権限が拒否されました。', isError: true);
      if (mounted) Navigator.pop(context);
      return;
    }
    
    // カメラリスト取得
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      if (mounted) showCustomSnackBar(context, '利用可能なカメラが見つかりませんでした。', isError: true);
      if (mounted) Navigator.pop(context);
      return;
    }
    
    // バックカメラを優先的に選択
    CameraDescription selectedCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    await _initializeController(selectedCamera);
  }
  
  Future<void> _initializeController(CameraDescription cameraDescription) async {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller!.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await _controller!.initialize();
      // Androidのバグ回避: フォーカスモードをAutoに設定
      if (Platform.isAndroid) {
         await _controller!.setFocusMode(FocusMode.auto);
      }
      
      // 画面上のカメラプレビューエリアのサイズを計算 (UIビルド後に実行)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_cameraPreviewKey.currentContext != null) {
          final renderBox = _cameraPreviewKey.currentContext!.findRenderObject() as RenderBox;
          final offset = renderBox.localToGlobal(Offset.zero);
          _cameraPreviewAreaOnScreen = offset & renderBox.size;
          setState(() {});
        }
      });
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } on CameraException catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) showCustomSnackBar(context, 'カメラの初期化に失敗しました: ${e.code}', isError: true);
      _isCameraInitialized = false;
    }
  }

  // ★ 追加: 画像をプロジェクトフォルダに保存する関数 (Case No.対応)
  Future<String?> _saveImageToProjectFolder(XFile xfile) async {
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
        // 荷札画像の場合、Case No.ごとのフォルダを作成 (3-2)
        final caseNo = widget.caseNumber ?? 'UnknownCase';
        subfolder = "荷札画像/$caseNo"; 
        fileNamePrefix = "nifuda_${caseNo.replaceAll('#', 'Case_')}";
      }

      final targetDirPath = p.join(widget.projectFolderPath, subfolder);
      final targetDir = Directory(targetDirPath);

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final timestamp = _formatTimestampForFilename(DateTime.now());
      final originalExtension = p.extension(xfile.path);
      final fileName = '${fileNamePrefix}_$timestamp$originalExtension';
      final targetFilePath = p.join(targetDir.path, fileName);
      
      final file = File(xfile.path);
      await file.copy(targetFilePath);
      
      // ギャラリーを更新
      await MediaScanner.loadMedia(path: targetFilePath);

      return targetFilePath;

    } catch (e) {
      debugPrint('Error saving image to project folder: $e');
      if (mounted) showCustomSnackBar(context, '画像の保存に失敗しました: $e', isError: true);
      return null;
    }
  }

  // ★ 撮影ボタンのアクション
  Future<void> _onCapturePressed() async {
    if (!_controller!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. 画像の撮影
      final XFile xfile = await _controller!.takePicture();
      
      // 2. 撮影した画像をプロジェクトフォルダに保存
      final savedPath = await _saveImageToProjectFolder(xfile);
      if (savedPath == null) return;
      _capturedFilePaths.add(savedPath);

      // 3. 画像のクロップ
      final rawBytes = await xfile.readAsBytes();
      final croppedBytes = _cropImageBytes(rawBytes);

      if (croppedBytes == null) {
        if (mounted) showCustomSnackBar(context, '画像クロップ中にエラーが発生しました。', isError: true);
        return;
      }
      
      // 4. OCR処理の実行
      final result = await widget.aiService(
        croppedBytes,
        isProductList: widget.isProductListOcr,
        company: widget.companyForGpt ?? '',
      );

      if (result != null) {
        _allGptResults.add(result);
        _capturedImageCount++;
        if (mounted) {
           showCustomSnackBar(context, '画像 #${_capturedImageCount} のOCRが完了しました。');
        }
      } else {
         if (mounted) {
           showCustomSnackBar(context, '画像 #${_capturedImageCount + 1} のOCR処理に失敗しました。', isError: true);
        }
      }

    } on CameraException catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) showCustomSnackBar(context, '撮影に失敗しました: ${e.code}', isError: true);
    } catch (e) {
      debugPrint('OCR processing error: $e');
      if (mounted) showCustomSnackBar(context, 'OCR処理中に予期せぬエラーが発生しました: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ★ 画像のクロップロジック
  Uint8List? _cropImageBytes(Uint8List rawBytes) {
    // 画面上のカメラプレビューの描画エリアと、オーバーレイの描画エリアが正しく取得されていることを確認
    if (_overlayRectOnScreen == Rect.zero || _cameraPreviewAreaOnScreen == Rect.zero) {
        debugPrint('Warning: Overlay or Preview rect is zero. Cannot crop.');
        return rawBytes; // クロップ情報がない場合はそのまま返す
    }
    
    try {
      final img.Image? originalImage = img.decodeImage(rawBytes);
      if (originalImage == null) return null;

      // 画面上の座標を画像ピクセル座標に変換
      final double widthRatio = originalImage.width / _cameraPreviewAreaOnScreen.width;
      final double heightRatio = originalImage.height / _cameraPreviewAreaOnScreen.height;
      
      // クロップ領域の計算
      final x = ((_overlayRectOnScreen.left - _cameraPreviewAreaOnScreen.left) * widthRatio).round();
      final y = ((_overlayRectOnScreen.top - _cameraPreviewAreaOnScreen.top) * heightRatio).round();
      final width = (_overlayRectOnScreen.width * widthRatio).round();
      final height = (_overlayRectOnScreen.height * heightRatio).round();
      
      // クロップを実行
      final img.Image croppedImage = img.copyCrop(
        originalImage, 
        x: x.clamp(0, originalImage.width), 
        y: y.clamp(0, originalImage.height), 
        width: width.clamp(0, originalImage.width - x), 
        height: height.clamp(0, originalImage.height - y),
      );
      
      // JPEGとしてエンコードして返却
      return Uint8List.fromList(img.encodeJpg(croppedImage, quality: 90));

    } catch (e, s) {
      debugPrint('Image cropping error: $e\n$s');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // カメラプレビューが利用可能なエリア全体を覆う
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // カメラの縦横比に合わせたプレビューサイズを計算
    final double cameraAspectRatio = _controller!.value.aspectRatio;
    double previewWidth = screenWidth;
    double previewHeight = previewWidth / cameraAspectRatio;

    if (previewHeight < screenHeight) {
      previewHeight = screenHeight;
      previewWidth = previewHeight * cameraAspectRatio;
    }
    
    // プレビューエリアの中心を計算
    final Size previewSize = Size(previewWidth, previewHeight);
    final Offset previewOffset = Offset((screenWidth - previewWidth) / 2, (screenHeight - previewHeight) / 2);


    return Scaffold(
      body: Stack(
        children: [
          // 1. カメラプレビューエリア
          Positioned.fromRect(
            rect: previewOffset & previewSize,
            child: SizedBox.expand(
              key: _cameraPreviewKey, // このSizedBoxのサイズを取得するためにキーを使用
              child: CameraPreview(_controller!),
            ),
          ),
          
          // 2. オーバーレイとボタンエリア (SafeAreaで上部を考慮)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // カメラプレビューの画面上の位置を計算 (この時点で _cameraPreviewAreaOnScreen は更新されているはず)
                final actualPreviewWidth = _cameraPreviewAreaOnScreen.width;
                final actualPreviewHeight = _cameraPreviewAreaOnScreen.height;
                
                // オーバーレイのサイズと位置を計算
                final actualOverlayWidth = actualPreviewWidth * widget.overlayWidthRatio;
                final actualOverlayHeight = actualPreviewHeight * widget.overlayHeightRatio;

                _overlayRectOnScreen = Rect.fromLTWH(
                  _cameraPreviewAreaOnScreen.left + (actualPreviewWidth - actualOverlayWidth) / 2,
                  _cameraPreviewAreaOnScreen.top + (actualPreviewHeight - actualOverlayHeight) / 2,
                  actualOverlayWidth,
                  actualOverlayHeight
                );

                return Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      // オーバーレイ描画
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
                      
                      // 撮影・完了ボタン
                      Positioned(
                        bottom: 32,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 完了ボタン
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : () {
                                // 撮影済みの結果を返却
                                Navigator.pop(context, _allGptResults);
                              },
                              icon: const Icon(Icons.check),
                              label: Text('完了 (${_allGptResults.length}件)', style: const TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            
                            // 撮影ボタン
                            FloatingActionButton(
                              onPressed: _onCapturePressed,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              child: _isProcessing 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                                : const Icon(Icons.camera),
                            ),
                          ],
                        ),
                      ),
                      
                      // 戻るボタン (AppBar風)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  );
              }
            ),
          ),
        ],
      ),
    );
  }
}

// 既存の _formatTimestampForFilename 関数を再定義 (home_actions.dartからのコピー)
String _formatTimestampForFilename(DateTime dateTime) {
  return '${dateTime.year.toString().padLeft(4, '0')}'
      '${dateTime.month.toString().padLeft(2, '0')}'
      '${dateTime.day.toString().padLeft(2, '0')}'
      '${dateTime.hour.toString().padLeft(2, '0')}'
      '${dateTime.minute.toString().padLeft(2, '0')}'
      '${dateTime.second.toString().padLeft(2, '0')}';
}