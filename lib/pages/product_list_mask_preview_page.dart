// lib/pages/product_list_mask_preview_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui; // ImageInfoを取得するために必要
import 'package:flutter/material.dart';
import '../utils/ocr_masker.dart';
import '../widgets/custom_snackbar.dart';

class ProductListMaskPreviewPage extends StatefulWidget {
  final Uint8List originalImageBytes;
  final String maskTemplate;
  final int imageIndex;
  final int totalImages;

  const ProductListMaskPreviewPage({
    super.key,
    required this.originalImageBytes,
    required this.maskTemplate,
    required this.imageIndex,
    required this.totalImages,
  });

  @override
  State<ProductListMaskPreviewPage> createState() =>
      _ProductListMaskPreviewPageState();
}

class _ProductListMaskPreviewPageState extends State<ProductListMaskPreviewPage> {
  // 動的マスク用の状態
  final List<Rect> _maskRects = [];
  Rect? _currentDrawingRect;
  final GlobalKey _imageKey = GlobalKey();
  Size? _imageRenderSize;
  Size? _actualImageSize;
  bool _isLoading = false;

  // 固定マスク用の状態
  Future<Uint8List>? _fixedMaskingFuture;
  Uint8List? _fixedMaskedImageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.maskTemplate != 'dynamic') {
      _fixedMaskingFuture = _applyFixedMask();
    } else {
      // 動的マスクの場合、画像の実際のサイズを取得する
      _getActualImageSize();
    }
  }

  Future<Uint8List> _applyFixedMask() async {
    setState(() => _isLoading = true);
    try {
      final bytes = await applyMaskToImage(widget.originalImageBytes,
          template: widget.maskTemplate);
      if (mounted) setState(() => _fixedMaskedImageBytes = bytes);
      return bytes;
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'マスク処理エラー: $e', isError: true);
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getActualImageSize() async {
    final image = Image.memory(widget.originalImageBytes);
    final completer = Completer<ui.Image>();
    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, _) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    }));
    final ui.Image imageInfo = await completer.future;
    if (mounted) {
      setState(() {
        _actualImageSize =
            Size(imageInfo.width.toDouble(), imageInfo.height.toDouble());
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.maskTemplate != 'dynamic') return;
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    _imageRenderSize = renderBox.size;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _currentDrawingRect = Rect.fromPoints(localPosition, localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.maskTemplate != 'dynamic' || _currentDrawingRect == null) return;
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _currentDrawingRect = Rect.fromPoints(_currentDrawingRect!.topLeft, localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.maskTemplate != 'dynamic' || _currentDrawingRect == null) return;
    // 面積が小さすぎる矩形は無視
    if (_currentDrawingRect!.width.abs() < 10 || _currentDrawingRect!.height.abs() < 10) {
       setState(() {
        _currentDrawingRect = null;
      });
      return;
    }
    setState(() {
      // 正規化された矩形を保存
      _maskRects.add(Rect.fromLTRB(
          _currentDrawingRect!.left < _currentDrawingRect!.right ? _currentDrawingRect!.left : _currentDrawingRect!.right,
          _currentDrawingRect!.top < _currentDrawingRect!.bottom ? _currentDrawingRect!.top : _currentDrawingRect!.bottom,
          _currentDrawingRect!.left > _currentDrawingRect!.right ? _currentDrawingRect!.left : _currentDrawingRect!.right,
          _currentDrawingRect!.top > _currentDrawingRect!.bottom ? _currentDrawingRect!.top : _currentDrawingRect!.bottom
      ));
      _currentDrawingRect = null;
    });
  }

  // 動的マスクを適用して画像を返す
  Future<void> _confirmDynamicMask() async {
    if (_actualImageSize == null || _imageRenderSize == null) return;
    setState(() => _isLoading = true);

    try {
      // 画面上の描画座標を、実際の画像座標に変換
      final double scaleX = _actualImageSize!.width / _imageRenderSize!.width;
      final double scaleY = _actualImageSize!.height / _imageRenderSize!.height;

      final List<Rect> actualMaskRects = _maskRects.map((rect) {
        return Rect.fromLTRB(
          rect.left * scaleX,
          rect.top * scaleY,
          rect.right * scaleX,
          rect.bottom * scaleY,
        );
      }).toList();

      final maskedBytes = await applyMaskToImage(
        widget.originalImageBytes,
        template: 'dynamic',
        dynamicMaskRects: actualMaskRects,
      );

      if (mounted) {
        Navigator.pop(context, maskedBytes);
      }
    } catch(e) {
      if (mounted) {
        showTopSnackBar(context, '動的マスクの適用に失敗: $e', isError: true);
      }
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
    // ★ 変更点：手動での下部パディング計算を削除
    // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
    // final double buttonBottomPosition = 15.0 + 60.0 + 10.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text('マスクプレビュー (${widget.imageIndex} / ${widget.totalImages})'),
        actions: widget.maskTemplate == 'dynamic' ? [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '最後のマスクを取り消し',
            onPressed: _maskRects.isEmpty ? null : () => setState(() => _maskRects.removeLast()),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
             tooltip: '全てのマスクを消去',
            onPressed: _maskRects.isEmpty ? null : () => setState(() => _maskRects.clear()),
          ),
        ] : null,
      ),
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
      // ★ 変更点：body全体をSafeAreaでラップ
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: _isLoading
                    ? const CircularProgressIndicator()
                    : widget.maskTemplate == 'dynamic'
                        ? _buildDynamicMaskEditor()
                        : _buildFixedMaskViewer(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('この画像を破棄'),
                    onPressed: () => Navigator.pop(context, null),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('この内容で送信'),
                    onPressed: _isLoading ? null : () {
                      if (widget.maskTemplate == 'dynamic') {
                        _confirmDynamicMask();
                      } else {
                        if (_fixedMaskedImageBytes != null) {
                          Navigator.pop(context, _fixedMaskedImageBytes);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // 固定マスク表示用Widget
  Widget _buildFixedMaskViewer() {
    return FutureBuilder<Uint8List>(
      future: _fixedMaskingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return const Text('マスク処理に失敗しました', style: TextStyle(color: Colors.red));
        }
        if (snapshot.hasData) {
          return InteractiveViewer(
            child: Image.memory(snapshot.data!),
          );
        }
        return const Text('画像を読み込めません');
      },
    );
  }

  // 動的マスク編集用Widget
  Widget _buildDynamicMaskEditor() {
    if (_actualImageSize == null) {
      return const CircularProgressIndicator();
    }
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: InteractiveViewer(
        maxScale: 5.0,
        child: CustomPaint(
          key: _imageKey,
          // 前景にマスク矩形を描画
          foregroundPainter: MaskPainter(
            rects: _maskRects,
            currentDrawingRect: _currentDrawingRect,
          ),
          // 背景に元画像を表示
          child: Image.memory(widget.originalImageBytes),
        ),
      ),
    );
  }
}

// マスク描画用のCustomPainter
class MaskPainter extends CustomPainter {
  final List<Rect> rects;
  final Rect? currentDrawingRect;

  MaskPainter({required this.rects, this.currentDrawingRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
      
    // 確定したマスク領域を描画
    for (final rect in rects) {
      canvas.drawRect(rect, paint);
    }
    
    // 現在ドラッグ中のマスク領域を描画
    if (currentDrawingRect != null) {
      final drawingPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;
      canvas.drawRect(currentDrawingRect!, drawingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    // 矩形リストか描画中矩形が変更されたら再描画
    return oldDelegate.rects != rects || oldDelegate.currentDrawingRect != currentDrawingRect;
  }
}