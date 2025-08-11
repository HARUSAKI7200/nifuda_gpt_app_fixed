import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../utils/ocr_masker.dart';
import '../widgets/custom_snackbar.dart';

class ProductListMaskPreviewPage extends StatefulWidget {
  final img.Image originalImage; // ★修正点: バイト列ではなくImageオブジェクトを受け取る
  final Uint8List previewImageBytes;
  final String maskTemplate;
  final int imageIndex;
  final int totalImages;

  const ProductListMaskPreviewPage({
    super.key,
    required this.originalImage, // ★修正点
    required this.previewImageBytes,
    required this.maskTemplate,
    required this.imageIndex,
    required this.totalImages,
  });

  @override
  State<ProductListMaskPreviewPage> createState() =>
      _ProductListMaskPreviewPageState();
}

class _ProductListMaskPreviewPageState extends State<ProductListMaskPreviewPage> {
  final List<Rect> _maskRects = [];
  Rect? _currentDrawingRect;
  final GlobalKey _imageKey = GlobalKey();
  Size? _imageRenderSize;
  Size? _actualImageSize;
  bool _isLoading = false;

  late img.Image _maskedImage; // ★修正点: マスク処理後のImageオブジェクトを保持

  @override
  void initState() {
    super.initState();
    // 最初にオリジナル画像をコピーして、マスク処理用のオブジェクトを作成
    _maskedImage = img.copy(widget.originalImage);
    if (widget.maskTemplate != 'dynamic') {
      _applyFixedMask();
    } else {
      _getActualImageSize();
    }
  }

  // ★修正点: applyMaskToImageの引数をImageオブジェクトに変更
  Future<void> _applyFixedMask() async {
    setState(() => _isLoading = true);
    try {
      _maskedImage = await applyMaskToImage(img.copy(_maskedImage), // コピーを渡す
          template: widget.maskTemplate);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, 'マスク処理エラー: $e', isError: true, showAtTop: true);
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getActualImageSize() async {
    // 実際の画像サイズは、既にデコードされているoriginalImageから取得できる
    if (mounted) {
      setState(() {
        _actualImageSize =
            Size(widget.originalImage.width.toDouble(), widget.originalImage.height.toDouble());
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
    if (_currentDrawingRect!.width.abs() < 10 || _currentDrawingRect!.height.abs() < 10) {
       setState(() {
        _currentDrawingRect = null;
      });
      return;
    }
    setState(() {
      _maskRects.add(Rect.fromLTRB(
          _currentDrawingRect!.left < _currentDrawingRect!.right ? _currentDrawingRect!.left : _currentDrawingRect!.right,
          _currentDrawingRect!.top < _currentDrawingRect!.bottom ? _currentDrawingRect!.top : _currentDrawingRect!.bottom,
          _currentDrawingRect!.left > _currentDrawingRect!.right ? _currentDrawingRect!.left : _currentDrawingRect!.right,
          _currentDrawingRect!.top > _currentDrawingRect!.bottom ? _currentDrawingRect!.bottom : _currentDrawingRect!.top
      ));
      _currentDrawingRect = null;
    });
  }

  // 動的マスクを適用して画像を返す
  Future<void> _confirmDynamicMask() async {
    if (_actualImageSize == null || _imageRenderSize == null) return;
    setState(() => _isLoading = true);

    try {
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

      _maskedImage = await applyMaskToImage(
        img.copy(widget.originalImage), // ここでもコピーを渡す
        template: 'dynamic',
        dynamicMaskRects: actualMaskRects,
      );

      if (mounted) {
        Navigator.pop(context, _maskedImage); // 最終的なImageオブジェクトを返す
      }
    } catch(e) {
      if (mounted) {
        showCustomSnackBar(context, '動的マスクの適用に失敗: $e', isError: true, showAtTop: true);
      }
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
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
                         // ★修正点: 固定マスクの場合は既に処理済みなので、そのImageオブジェクトを返す
                        Navigator.pop(context, _maskedImage);
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
    return FutureBuilder(
      future: null,
      builder: (context, snapshot) {
        if (_isLoading) {
          return const CircularProgressIndicator();
        }
        // ここでは_maskedImageが既にセットされている前提
        return InteractiveViewer(
          child: Image.memory(Uint8List.fromList(img.encodeJpg(_maskedImage))),
        );
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
          foregroundPainter: MaskPainter(
            rects: _maskRects,
            currentDrawingRect: _currentDrawingRect,
          ),
          child: Image.memory(widget.previewImageBytes),
        ),
      ),
    );
  }
}

class MaskPainter extends CustomPainter {
  final List<Rect> rects;
  final Rect? currentDrawingRect;

  MaskPainter({required this.rects, this.currentDrawingRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
      
    for (final rect in rects) {
      canvas.drawRect(rect, paint);
    }
    
    if (currentDrawingRect != null) {
      final drawingPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;
      canvas.drawRect(currentDrawingRect!, drawingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    return oldDelegate.rects != rects || oldDelegate.currentDrawingRect != currentDrawingRect;
  }
}