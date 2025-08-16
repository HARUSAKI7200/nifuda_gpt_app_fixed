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
  // 確定したマスク（黒塗り）のリスト
  final List<Rect> _maskRects = [];
  // 現在ドラッグして描画中のマスク
  Rect? _currentDrawingRect;
  final GlobalKey _imageKey = GlobalKey();
  bool _isLoading = false;

  late img.Image _originalPreviewImage;
  // 表示用の画像データ（T社固定マスクの場合のみ変更される）
  late Uint8List _displayImageBytes;

  @override
  void initState() {
    super.initState();
    // 初期状態では、渡されたプレビュー画像をそのまま表示用データとする
    _displayImageBytes = widget.previewImageBytes;
    _originalPreviewImage = img.decodeImage(widget.previewImageBytes)!;

    // T社用の固定マスクの場合は、最初に画像を加工する
    if (widget.maskTemplate == 't') {
      _applyFixedMaskToPreview();
    }
  }

  /// T社用の固定マスクをプレビュー画像に焼き付ける処理
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

  /// 描画開始：ドラッグ開始地点を記録
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

  /// 描画中：ドラッグに合わせて描画範囲を更新
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

  /// ★★★ 変更点：描画終了時の処理を簡略化 ★★★
  /// 描画した範囲を確定済みリストに追加し、UIを更新するだけ。
  void _onPanEnd(DragEndDetails details) {
    if (widget.maskTemplate != 'dynamic' || _currentDrawingRect == null) return;
    // 小さすぎる範囲は無視
    if (_currentDrawingRect!.width.abs() < 10 || _currentDrawingRect!.height.abs() < 10) {
       setState(() { _currentDrawingRect = null; });
      return;
    }
    setState(() {
      // 矩形を正規化（始点と終点が逆でもOKなように）してリストに追加
      _maskRects.add(Rect.fromLTRB(
          _currentDrawingRect!.left < _currentDrawingRect!.right ? _currentDrawingRect!.left : _currentDrawingRect!.right,
          _currentDrawingRect!.top < _currentDrawingRect!.bottom ? _currentDrawingRect!.top : _currentDrawingRect!.bottom,
          _currentDrawingRect!.left > _currentDrawingRect!.right ? _currentDrawingRect!.left : _currentDrawingRect!.right,
          _currentDrawingRect!.top > _currentDrawingRect!.bottom ? _currentDrawingRect!.bottom : _currentDrawingRect!.top
      ));
      // 描画中矩形をクリア
      _currentDrawingRect = null;
      // これで自動的に`build`が呼ばれ、`MaskPainter`が新しいマスクを描画する
    });
  }

  /// 確定して前の画面に結果を返す
  void _confirmAndPop() {
    Navigator.pop(context, {
      'path': widget.originalImagePath,
      'rects': _maskRects, // ユーザーが描画したマスク範囲のリスト
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
              // ★★★ 変更点：リストから要素を消してUIを更新するだけ ★★★
              setState(() => _maskRects.removeLast());
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
             tooltip: '全てのマスクを消去',
            onPressed: _maskRects.isEmpty ? null : () {
              // ★★★ 変更点：リストを空にしてUIを更新するだけ ★★★
              setState(() => _maskRects.clear());
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
    // ★★★ 変更点：Painterに「確定済みマスク」と「描画中マスク」の両方を渡す ★★★
    final painter = MaskPainter(
      rects: _maskRects, 
      currentDrawingRect: _currentDrawingRect
    );

    // ★★★ 変更点：画像自体は変更せず、その上にPainterで描画する構成 ★★★
    final imageWidget = Image.memory(_displayImageBytes);

    return GestureDetector(
      onPanStart: widget.maskTemplate == 'dynamic' ? _onPanStart : null,
      onPanUpdate: widget.maskTemplate == 'dynamic' ? _onPanUpdate : null,
      onPanEnd: widget.maskTemplate == 'dynamic' ? _onPanEnd : null,
      child: InteractiveViewer(
        maxScale: 5.0,
        child: CustomPaint(
          key: _imageKey,
          // foregroundPainterを使うことで、画像の「上」に描画する
          foregroundPainter: painter,
          child: imageWidget,
        ),
      ),
    );
  }
}

/// ★★★ 変更点：マスク描画ロジックをここに集約 ★★★
class MaskPainter extends CustomPainter {
  final List<Rect> rects;
  final Rect? currentDrawingRect;

  const MaskPainter({required this.rects, this.currentDrawingRect});

  @override
  void paint(Canvas canvas, Size size) {
    // 確定したマスクは不透明の黒で描画
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (final rect in rects) {
      canvas.drawRect(rect, paint);
    }

    // 描画中のマスクがあれば、半透明の黒で描画
    if (currentDrawingRect != null) {
      final drawingPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
      canvas.drawRect(currentDrawingRect!, drawingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    // 描画データが変更されたら再描画する
    return oldDelegate.rects != rects || oldDelegate.currentDrawingRect != currentDrawingRect;
  }
}