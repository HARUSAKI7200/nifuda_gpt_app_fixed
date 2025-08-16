// lib/pages/product_list_mask_preview_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../utils/ocr_masker.dart';
import '../widgets/custom_snackbar.dart';

class ProductListMaskPreviewPage extends StatefulWidget {
  final Uint8List previewImageBytes;
  final String maskTemplate;
  final int imageIndex;
  final int totalImages;

  const ProductListMaskPreviewPage({
    super.key,
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
  late img.Image _editableImage;
  late Uint8List _displayImageBytes;
  Rect? _currentDrawingRect;
  final GlobalKey _imageKey = GlobalKey();
  bool _isLoading = false;
  final List<img.Image> _undoStack = [];

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  void _initializeImage() {
    setState(() => _isLoading = true);
    try {
      _editableImage = img.decodeImage(widget.previewImageBytes)!;
      // T社用の固定マスクは初期状態で適用
      if (widget.maskTemplate == 't') {
        _editableImage = applyMaskToImage(_editableImage, template: 't');
      }
      _updateDisplayImage();
    } catch (e) {
      if (mounted) showCustomSnackBar(context, '画像初期化エラー: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateDisplayImage() {
    setState(() {
      // 編集された画像を品質80%のJPEGに再エンコードして表示用データとする
      _displayImageBytes = Uint8List.fromList(img.encodeJpg(_editableImage, quality: 80));
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.maskTemplate != 'dynamic') return;
    final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _currentDrawingRect = Rect.fromPoints(localPosition, localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.maskTemplate != 'dynamic' || _currentDrawingRect == null) return;
    final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _currentDrawingRect = Rect.fromPoints(_currentDrawingRect!.topLeft, localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.maskTemplate != 'dynamic' || _currentDrawingRect == null) return;
    // 小さすぎる範囲は無視
    if (_currentDrawingRect!.width.abs() < 10 || _currentDrawingRect!.height.abs() < 10) {
      setState(() { _currentDrawingRect = null; });
      return;
    }

    // Undo(元に戻す)用に現在の画像状態を保存
    _undoStack.add(img.Image.from(_editableImage));

    // 矩形を正規化（始点と終点が逆でもOKなように）
    final rect = Rect.fromLTRB(
        _currentDrawingRect!.left < _currentDrawingRect!.right ? _currentDrawingRect!.left : _currentDrawingRect!.right,
        _currentDrawingRect!.top < _currentDrawingRect!.bottom ? _currentDrawingRect!.top : _currentDrawingRect!.bottom,
        _currentDrawingRect!.left > _currentDrawingRect!.right ? _currentDrawingRect!.left : _currentDrawingRect!.right,
        _currentDrawingRect!.top > _currentDrawingRect!.bottom ? _currentDrawingRect!.bottom : _currentDrawingRect!.top
    );

    // 編集中の画像データに直接黒い四角を描画する
    img.fillRect(
      _editableImage,
      x1: rect.left.toInt(),
      y1: rect.top.toInt(),
      x2: rect.right.toInt(),
      y2: rect.bottom.toInt(),
      color: img.ColorRgb8(0, 0, 0),
    );

    setState(() {
      _currentDrawingRect = null; // 描画中矩形をクリア
    });
    _updateDisplayImage(); // 表示を更新
  }
  
  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _editableImage = _undoStack.removeLast();
    });
    _updateDisplayImage();
  }

  void _reset() {
    setState(() {
      _undoStack.clear();
      // 元のプレビュー画像からリセット
      _editableImage = img.decodeImage(widget.previewImageBytes)!;
      // T社テンプレートの場合は固定マスクを再適用
      if (widget.maskTemplate == 't') {
          _editableImage = applyMaskToImage(_editableImage, template: 't');
      }
    });
    _updateDisplayImage();
  }

  /// 確定して、マスク処理済みの画像データを前の画面に返す
  void _confirmAndPop() {
    Navigator.pop(context, _displayImageBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('マスクプレビュー (${widget.imageIndex} / ${widget.totalImages})'),
        actions: widget.maskTemplate == 'dynamic'
            ? [
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: '最後のマスクを取り消し',
                  onPressed: _undoStack.isEmpty ? null : _undo,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  tooltip: '全てのマスクを消去',
                  onPressed: _undoStack.isEmpty ? null : _reset,
                ),
              ]
            : null,
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
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('この画像を破棄'),
                      onPressed: () => Navigator.pop(context, null),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('この内容で送信'),
                      onPressed: _confirmAndPop,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
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
    // 描画中の矩形のみをリアルタイムで表示するPainter
    final painter = MaskPainter(currentDrawingRect: _currentDrawingRect);
    // マスクが焼き付けられた最新の画像データを表示
    final imageWidget = Image.memory(_displayImageBytes, key: _imageKey, gaplessPlayback: true);

    return GestureDetector(
      onPanStart: widget.maskTemplate == 'dynamic' ? _onPanStart : null,
      onPanUpdate: widget.maskTemplate == 'dynamic' ? _onPanUpdate : null,
      onPanEnd: widget.maskTemplate == 'dynamic' ? _onPanEnd : null,
      child: InteractiveViewer(
        maxScale: 5.0,
        child: CustomPaint(
          foregroundPainter: painter,
          child: imageWidget,
        ),
      ),
    );
  }
}

/// 描画中の半透明マスクを描画するためだけのシンプルなPainter
class MaskPainter extends CustomPainter {
  final Rect? currentDrawingRect;

  const MaskPainter({this.currentDrawingRect});

  @override
  void paint(Canvas canvas, Size size) {
    if (currentDrawingRect != null) {
      final drawingPaint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRect(currentDrawingRect!, drawingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    return oldDelegate.currentDrawingRect != currentDrawingRect;
  }
}