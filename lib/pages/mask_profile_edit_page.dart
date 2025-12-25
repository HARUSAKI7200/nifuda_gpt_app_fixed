// lib/pages/mask_profile_edit_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import '../state/project_state.dart';
import '../widgets/custom_snackbar.dart';

class MaskProfileEditPage extends ConsumerStatefulWidget {
  const MaskProfileEditPage({super.key});

  @override
  ConsumerState<MaskProfileEditPage> createState() => _MaskProfileEditPageState();
}

class _MaskProfileEditPageState extends ConsumerState<MaskProfileEditPage> {
  final _nameController = TextEditingController();
  File? _sampleImage;
  ui.Image? _decodedImage;
  List<Rect> _relativeRects = []; // 0.0~1.0 の相対座標で保存
  Rect? _currentDrawingRect;
  Offset? _startDragPos; 
  final GlobalKey _imageKey = GlobalKey();

  Future<void> _scanDocument() async {
    try {
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        pageLimit: 1,
        isGalleryImport: true,
      );

      final scanner = DocumentScanner(options: options);
      final result = await scanner.scanDocument();

      if (result.images.isNotEmpty) {
        final File imageFile = File(result.images.first);
        final bytes = await imageFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();

        setState(() {
          _sampleImage = imageFile;
          _decodedImage = frame.image;
          _relativeRects.clear();
        });
      }
    } catch (e) {
      if (mounted) showCustomSnackBar(context, 'スキャンエラー: $e', isError: true);
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_decodedImage == null) return;
    final RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPos = box.globalToLocal(details.globalPosition);

    setState(() {
      _startDragPos = localPos;
      _currentDrawingRect = Rect.fromPoints(localPos, localPos);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_decodedImage == null || _startDragPos == null) return;
    final RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final localPos = box.globalToLocal(details.globalPosition);

    setState(() {
      _currentDrawingRect = Rect.fromPoints(_startDragPos!, localPos);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentDrawingRect == null || _decodedImage == null) return;
    
    final RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final containerSize = box.size;
    final imageSize = Size(_decodedImage!.width.toDouble(), _decodedImage!.height.toDouble());

    // ★ 修正ポイント: 実際に画像が表示されている領域を計算
    final FittedSizes fittedSizes = applyBoxFit(BoxFit.contain, imageSize, containerSize);
    final Size destSize = fittedSizes.destination; // 画面上の画像のサイズ
    
    // 画像の表示位置（中央寄せされている場合のオフセット）
    final double dx = (containerSize.width - destSize.width) / 2;
    final double dy = (containerSize.height - destSize.height) / 2;
    final Rect imageRect = Rect.fromLTWH(dx, dy, destSize.width, destSize.height);

    // 描画された矩形と画像領域の重なり部分を取得（はみ出し防止）
    final Rect intersection = _currentDrawingRect!.intersect(imageRect);

    // 重なりがなければ無効
    if (intersection.width <= 0 || intersection.height <= 0) {
      setState(() {
        _currentDrawingRect = null;
        _startDragPos = null;
      });
      return;
    }

    // ★ 修正ポイント: 画像領域基準での相対座標に変換
    // (描画座標 - 画像開始位置) / 画像表示サイズ
    final relRect = Rect.fromLTRB(
      (intersection.left - dx) / destSize.width,
      (intersection.top - dy) / destSize.height,
      (intersection.right - dx) / destSize.width,
      (intersection.bottom - dy) / destSize.height,
    );

    setState(() {
      _relativeRects.add(relRect);
      _currentDrawingRect = null;
      _startDragPos = null;
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      showCustomSnackBar(context, '設定名（会社名）を入力してください', isError: true);
      return;
    }
    if (_relativeRects.isEmpty) {
      showCustomSnackBar(context, '黒塗り範囲を指定してください', isError: true);
      return;
    }

    try {
      final db = ref.read(appDatabaseInstanceProvider);
      
      final List<String> rectData = _relativeRects.map((r) => 
        "${r.left},${r.top},${r.width},${r.height}"
      ).toList();

      await db.maskProfilesDao.insertProfile(_nameController.text, rectData);
      
      if (mounted) {
        showCustomSnackBar(context, 'マスク設定「${_nameController.text}」を保存しました');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showCustomSnackBar(context, '保存エラー: 設定名が重複している可能性があります\n$e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規マスク設定の追加')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '設定名（例: A社）'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('スキャン'),
                    onPressed: _scanDocument,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('画像を指でなぞって黒塗り範囲を指定してください。', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            Expanded(
              child: _sampleImage == null
                  ? const Center(child: Text('サンプル画像をスキャンしてください'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: Container(
                              key: _imageKey,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                image: DecorationImage(
                                  image: FileImage(_sampleImage!),
                                  fit: BoxFit.contain, // ★ ここに合わせて座標計算を修正しました
                                )
                              ),
                              child: CustomPaint(
                                painter: _MaskEditPainter(
                                  rects: _relativeRects,
                                  currentRect: _currentDrawingRect,
                                  imageSize: Size(_decodedImage!.width.toDouble(), _decodedImage!.height.toDouble()), // ★ 追加: 画像サイズを渡す
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _relativeRects.clear()),
                    child: const Text('範囲リセット', style: TextStyle(color: Colors.red)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('この設定を保存'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: _saveProfile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaskEditPainter extends CustomPainter {
  final List<Rect> rects;
  final Rect? currentRect;
  final Size? imageSize; // ★ 追加

  _MaskEditPainter({required this.rects, this.currentRect, this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black; // 不透明な黒

    // ★ 修正ポイント: 描画時も画像表示エリアを計算して位置合わせする
    Rect imageRect = Offset.zero & size;
    
    if (imageSize != null) {
      final FittedSizes fittedSizes = applyBoxFit(BoxFit.contain, imageSize!, size);
      final Size destSize = fittedSizes.destination;
      final double dx = (size.width - destSize.width) / 2;
      final double dy = (size.height - destSize.height) / 2;
      imageRect = Rect.fromLTWH(dx, dy, destSize.width, destSize.height);
    }

    // 保存領域の描画
    for (final r in rects) {
      // 相対座標 * 画像表示サイズ + オフセット
      canvas.drawRect(
        Rect.fromLTRB(
          imageRect.left + r.left * imageRect.width,
          imageRect.top + r.top * imageRect.height,
          imageRect.left + r.right * imageRect.width,
          imageRect.top + r.bottom * imageRect.height,
        ),
        paint,
      );
    }

    // ドラッグ中領域の描画（赤枠）
    if (currentRect != null) {
      canvas.drawRect(currentRect!, Paint()..color = Colors.red.withOpacity(0.3));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}