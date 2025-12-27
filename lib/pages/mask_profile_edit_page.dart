// lib/pages/mask_profile_edit_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import '../state/project_state.dart';
import '../widgets/custom_snackbar.dart';
// ★ 追加: プロンプトレジストリ
import '../utils/prompt_definitions.dart';

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

  // ★ 追加: 選択されたプロンプトID (デフォルトは標準)
  String _selectedPromptId = PromptRegistry.availablePrompts.first.id;

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

    // 画像表示エリアの計算
    final FittedSizes fittedSizes = applyBoxFit(BoxFit.contain, imageSize, containerSize);
    final Size destSize = fittedSizes.destination; 
    
    final double dx = (containerSize.width - destSize.width) / 2;
    final double dy = (containerSize.height - destSize.height) / 2;
    final Rect imageRect = Rect.fromLTWH(dx, dy, destSize.width, destSize.height);

    final Rect intersection = _currentDrawingRect!.intersect(imageRect);

    if (intersection.width <= 0 || intersection.height <= 0) {
      setState(() {
        _currentDrawingRect = null;
        _startDragPos = null;
      });
      return;
    }

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

      // ★ 修正: promptId を保存
      await db.maskProfilesDao.insertProfile(
        _nameController.text, 
        rectData,
        promptId: _selectedPromptId,
      );
      
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
              child: Column(
                children: [
                  Row(
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
                  const SizedBox(height: 10),
                  // ★ 追加: プロンプト選択UI
                  DropdownButtonFormField<String>(
                    value: _selectedPromptId,
                    decoration: const InputDecoration(
                      labelText: '使用する抽出プロンプト',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: PromptRegistry.availablePrompts.map((def) {
                      return DropdownMenuItem(
                        value: def.id,
                        child: Text(def.label, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPromptId = val;
                        });
                      }
                    },
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
                                  fit: BoxFit.contain, 
                                )
                              ),
                              child: CustomPaint(
                                painter: _MaskEditPainter(
                                  rects: _relativeRects,
                                  currentRect: _currentDrawingRect,
                                  imageSize: Size(_decodedImage!.width.toDouble(), _decodedImage!.height.toDouble()), 
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
  final Size? imageSize; 

  _MaskEditPainter({required this.rects, this.currentRect, this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black; 

    Rect imageRect = Offset.zero & size;
    
    if (imageSize != null) {
      final FittedSizes fittedSizes = applyBoxFit(BoxFit.contain, imageSize!, size);
      final Size destSize = fittedSizes.destination;
      final double dx = (size.width - destSize.width) / 2;
      final double dy = (size.height - destSize.height) / 2;
      imageRect = Rect.fromLTWH(dx, dy, destSize.width, destSize.height);
    }

    for (final r in rects) {
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

    if (currentRect != null) {
      canvas.drawRect(currentRect!, Paint()..color = Colors.red.withOpacity(0.3));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}