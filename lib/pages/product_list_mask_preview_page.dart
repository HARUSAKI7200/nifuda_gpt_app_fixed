// lib/pages/product_list_mask_preview_page.dart
import 'dart:async';
import 'dart:typed_data';
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
  bool _isLoading = false;

  late img.Image _originalPreviewImage;
  Uint8List? _displayImageBytes;

  @override
  void initState() {
    super.initState();
    _displayImageBytes = widget.previewImageBytes;
    _originalPreviewImage = img.decodeImage(widget.previewImageBytes)!;

    if (widget.maskTemplate == 't') {
      _applyFixedMaskToPreview();
    }
  }

  void _applyFixedMaskToPreview() {
    setState(() => _isLoading = true);
    try {
      final maskedPreviewImage = applyMaskToImage(
        img.Image.from(_originalPreviewImage), // 元画像のコピーを渡す
        template: widget.maskTemplate,
      );
      setState(() {
        _displayImageBytes = Uint8List.fromList(img.encodeJpg(maskedPreviewImage));
      });
    } catch (e) {
      if (mounted) showCustomSnackBar(context, 'プレビューへのマスク処理エラー: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ★★★ 変更点：try-catch-finally を追加して安定性を向上 ★★★
  void _applyDynamicMasksToPreview() {
    setState(() => _isLoading = true);
    try {
      // 元のプレビュー画像のコピーに対して処理を行う
      img.Image newImage = img.Image.from(_originalPreviewImage);

      // `applyMaskToImage` を呼び出してマスクを適用
      newImage = applyMaskToImage(
        newImage,
        template: 'dynamic', // 'dynamic' テンプレートを明示
        dynamicMaskRects: _maskRects,
      );

      // 表示用のバイト列を更新
      setState(() {
        _displayImageBytes = Uint8List.fromList(img.encodeJpg(newImage));
      });
    } catch (e) {
      if (mounted) showCustomSnackBar(context, 'プレビューへのマスク処理エラー: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _onPanStart(DragStartDetails details) {
    if (widget.maskTemplate != 'dynamic') return;
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
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
      _applyDynamicMasksToPreview();
    });
  }

  void _confirmAndPop() {
    Navigator.pop(context, {
      'path': widget.originalImagePath,
      'rects': _maskRects,
      'template': widget.maskTemplate,
      'previewSize': Size(_originalPreviewImage.width.toDouble(), _originalPreviewImage.height.toDouble()),
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
            onPressed: _maskRects.isEmpty ? null : () {
              setState(() => _maskRects.removeLast());
              _applyDynamicMasksToPreview();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
             tooltip: '全てのマスクを消去',
            onPressed: _maskRects.isEmpty ? null : () {
              setState(() => _maskRects.clear());
              _applyDynamicMasksToPreview();
            },
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
                      : _buildEditor(),
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
      ? MaskPainter(rects: const [], currentDrawingRect: _currentDrawingRect)
      : MaskPainter(rects: const [], currentDrawingRect: null);

    final imageWidget = _displayImageBytes != null
        ? Image.memory(_displayImageBytes!, key: ValueKey(_displayImageBytes!.length))
        : const Center(child: Text("画像がありません"));


    return GestureDetector(
      onPanStart: widget.maskTemplate == 'dynamic' ? _onPanStart : null,
      onPanUpdate: widget.maskTemplate == 'dynamic' ? _onPanUpdate : null,
      onPanEnd: widget.maskTemplate == 'dynamic' ? _onPanEnd : null,
      child: InteractiveViewer(
        maxScale: 5.0,
        child: CustomPaint(
          key: _imageKey,
          foregroundPainter: painter,
          child: imageWidget,
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