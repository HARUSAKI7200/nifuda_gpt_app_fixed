// lib/pages/product_list_mask_preview_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
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

// 戻り値の型定義: 1枚目の画像バイトと、適用された動的マスクのリスト
typedef MaskPreviewResult = ({Uint8List imageBytes, List<Rect> dynamicMasks});


class _ProductListMaskPreviewPageState extends State<ProductListMaskPreviewPage> {
  late img.Image _editableImage;
  late Uint8List _displayImageBytes;
  Rect? _currentDrawingRect;
  final GlobalKey _imageContainerKey = GlobalKey();
  bool _isLoading = false;
  final List<img.Image> _undoStack = [];
  img.Image? _initialImageState;
  
  // 動的マスクのRect情報を保持するリスト
  final List<Rect> _dynamicMaskRects = [];

  // ★ 追加: 画像が変更されたかどうかのフラグ
  bool _hasModified = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  void _initializeImage() {
    setState(() => _isLoading = true);
    try {
      final decodedImage = img.decodeImage(widget.previewImageBytes)!;
      // Undo用に初期状態を保存
      _initialImageState = img.Image.from(decodedImage); 
      _editableImage = decodedImage;

      // テンプレート指定があれば初期状態で適用（これは自動変更なので_hasModifiedはfalseのままでよい、またはtrueにするか仕様次第）
      // 今回は「ユーザーの手動変更」のみを検知して最適化するため、テンプレート適用は「初期状態」とみなす
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
      // ★ 修正: PNGエンコードに変更 (画質劣化なし)
      _displayImageBytes = Uint8List.fromList(img.encodePng(_editableImage));
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.maskTemplate != 'dynamic') return;
    setState(() {
      // ローカル座標で描画開始
      _currentDrawingRect = Rect.fromPoints(details.localPosition, details.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.maskTemplate != 'dynamic' || _currentDrawingRect == null) return;
    setState(() {
      _currentDrawingRect =
          Rect.fromPoints(_currentDrawingRect!.topLeft, details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.maskTemplate != 'dynamic' || _currentDrawingRect == null) return;

    // 描画が小さすぎる場合はキャンセル
    if (_currentDrawingRect!.width.abs() < 5 || _currentDrawingRect!.height.abs() < 5) {
      setState(() => _currentDrawingRect = null);
      return;
    }

    final RenderBox? containerBox =
        _imageContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (containerBox == null) return;

    final Size containerSize = containerBox.size;
    final Size imagePixelSize = Size(_editableImage.width.toDouble(), _editableImage.height.toDouble());

    // 表示サイズ計算
    final FittedSizes fittedSizes = applyBoxFit(BoxFit.contain, imagePixelSize, containerSize);
    final Size imageDisplaySize = fittedSizes.destination;
    final Rect imageDisplayRect = Rect.fromLTWH(
      (containerSize.width - imageDisplaySize.width) / 2,
      (containerSize.height - imageDisplaySize.height) / 2,
      imageDisplaySize.width,
      imageDisplaySize.height,
    );

    // 描画されたRectと表示領域の共通部分を取得
    final Rect intersection = _currentDrawingRect!.intersect(imageDisplayRect);

    if (intersection.width <= 0 || intersection.height <= 0) {
      setState(() => _currentDrawingRect = null);
      return;
    }

    // スクリーン座標から画像ピクセル座標へのスケールとオフセット
    final double scaleX = imagePixelSize.width / imageDisplaySize.width;
    final double scaleY = imagePixelSize.height / imageDisplaySize.height;

    // 画像ピクセル座標でのRectを計算
    final Rect rectOnImage = Rect.fromLTRB(
      (intersection.left - imageDisplayRect.left) * scaleX,
      (intersection.top - imageDisplayRect.top) * scaleY,
      (intersection.right - imageDisplayRect.left) * scaleX,
      (intersection.bottom - imageDisplayRect.top) * scaleY,
    );
    
    // Undoスタックに現在の状態を保存
    _undoStack.add(img.Image.from(_editableImage));
    
    // 画像にマスクを適用
    img.fillRect(
      _editableImage,
      x1: rectOnImage.left.toInt(),
      y1: rectOnImage.top.toInt(),
      x2: rectOnImage.right.toInt(),
      y2: rectOnImage.bottom.toInt(),
      color: img.ColorRgb8(0, 0, 0),
    );
    
    // 適用したRectをリストに追加 (後の画像にも適用するため)
    _dynamicMaskRects.add(rectOnImage);

    // ★ 修正: 変更フラグを立てる
    _hasModified = true;

    setState(() {
      _currentDrawingRect = null;
      _updateDisplayImage();
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _editableImage = _undoStack.removeLast();
      if(_dynamicMaskRects.isNotEmpty) {
        _dynamicMaskRects.removeLast();
      }
      _updateDisplayImage();
      // Undoスタックが空になったら変更なし状態に戻す（簡易判定）
      if (_undoStack.isEmpty) _hasModified = false;
    });
  }

  void _reset() {
    setState(() {
      _undoStack.clear();
      _dynamicMaskRects.clear(); 
      if (_initialImageState != null) {
         _editableImage = img.Image.from(_initialImageState!);
         if (widget.maskTemplate == 't') {
            _editableImage = applyMaskToImage(_editableImage, template: 't');
         }
      }
      _updateDisplayImage();
      _hasModified = false;
    });
  }

  void _confirmAndPop() {
    // ★ 修正: 変更がなければ、再エンコードせず元のバイトデータをそのまま返す（劣化ゼロ & 高速）
    if (!_hasModified) {
      Navigator.pop(context, (imageBytes: widget.previewImageBytes, dynamicMasks: _dynamicMaskRects));
    } else {
      Navigator.pop(context, (imageBytes: _displayImageBytes, dynamicMasks: _dynamicMaskRects));
    }
  }

  Widget _buildEditor() {
    return Container(
      key: _imageContainerKey,
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _displayImageBytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
          CustomPaint(
            // ユーザーがドラッグ中のRectを表示
            painter: MaskPainter(currentDrawingRect: _currentDrawingRect),
          ),
          GestureDetector(
            onPanStart: widget.maskTemplate == 'dynamic' ? _onPanStart : null,
            onPanUpdate: widget.maskTemplate == 'dynamic' ? _onPanUpdate : null,
            onPanEnd: widget.maskTemplate == 'dynamic' ? _onPanEnd : null,
            behavior: HitTestBehavior.translucent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasChanges = _undoStack.isNotEmpty;
    // T社・マスクなしの場合は編集不可
    bool isEditable = widget.maskTemplate == 'dynamic';

    return Scaffold(
      appBar: AppBar(
        title: Text('マスクプレビュー (${widget.imageIndex} / ${widget.totalImages})'),
        actions: isEditable
            ? [
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: '最後のマスクを取り消し',
                  onPressed: hasChanges ? _undo : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  tooltip: '全てのマスクを消去',
                  onPressed: hasChanges ? _reset : null,
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildEditor(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
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
}

class MaskPainter extends CustomPainter {
  final Rect? currentDrawingRect;
  const MaskPainter({this.currentDrawingRect});

  @override
  void paint(Canvas canvas, Size size) {
    if (currentDrawingRect != null) {
      final paint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRect(currentDrawingRect!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    return oldDelegate.currentDrawingRect != currentDrawingRect;
  }
}