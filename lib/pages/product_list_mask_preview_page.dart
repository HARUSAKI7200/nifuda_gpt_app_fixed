// lib/pages/product_list_mask_preview_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../utils/ocr_masker.dart';
import '../widgets/custom_snackbar.dart';

class ProductListMaskPreviewPage extends StatefulWidget {
  final String originalImagePath;
  final Uint8List previewImageBytes;
  final String maskTemplate;
  final int imageIndex;
  final int totalImages;

  const ProductListMaskPreviewPage({
    super.key,
    required this.originalImagePath,
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
  
  // ★★★ 変更点：プレビューへのマスク適用処理を削除 ★★★
  late img.Image _previewImage;

  @override
  void initState() {
    super.initState();
    _previewImage = img.decodeImage(widget.previewImageBytes)!;
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
       setState(() { _currentDrawingRect = null; });
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

  void _confirmAndPop() {
    Navigator.pop(context, {
      'path': widget.originalImagePath,
      'rects': _maskRects,
      'template': widget.maskTemplate,
      'previewSize': Size(_previewImage.width.toDouble(), _previewImage.height.toDouble()),
    });
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
                  child: _buildEditor(),
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
                    onPressed: _confirmAndPop,
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

  Widget _buildEditor() {
    final painter = widget.maskTemplate == 'dynamic' 
      ? MaskPainter(rects: _maskRects, currentDrawingRect: _currentDrawingRect)
      : MaskPainter(rects: const [], currentDrawingRect: null);

    // ★★★ 変更点：常にオリジナルのプレビュー画像を表示 ★★★
    final imageWidget = Image.memory(widget.previewImageBytes);

    return GestureDetector(
      onPanStart: widget.maskTemplate == 'dynamic' ? _onPanStart : null,
      onPanUpdate: widget.maskTemplate == 'dynamic' ? _onPanUpdate : null,
      onPanEnd: widget.maskTemplate == 'dynamic' ? _onPanEnd : null,
      child: InteractiveViewer(
        maxScale: 5.0,
        child: CustomPaint(
          key: _imageKey,
          foregroundPainter: painter,
          child: LayoutBuilder( 
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
                  if(renderBox != null && renderBox.hasSize){
                    _imageRenderSize = renderBox.size;
                  }
                }
              });
              return imageWidget;
            },
          ),
        ),
      ),
    );
  }
}

class MaskPainter extends CustomPainter {
  final List<Rect> rects;
  final Rect? currentDrawingRect;

  const MaskPainter({required this.rects, this.currentDrawingRect});

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