// lib/pages/profile_edit_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:drift/drift.dart' as drift;
import '../state/project_state.dart';
import '../widgets/custom_snackbar.dart';
import '../database/app_database.dart';
import '../utils/matching_profile.dart'; 

class ProfileEditPage extends ConsumerStatefulWidget {
  final MaskProfile? existingProfile;

  const ProfileEditPage({super.key, this.existingProfile});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 基本情報
  final _nameController = TextEditingController();
  ProfileType _selectedType = ProfileType.standard;

  // 項目定義 & 照合設定
  // 荷札の項目 (動的・編集可能)
  List<String> _nifudaFields = List.from(MatchingProfileRegistry.defaultNifudaFields);
  
  // 製品リストの項目 (動的)
  List<String> _productListFields = ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '数量', '備考'];
  
  // 照合ペア: Key=荷札項目, Value=製品リスト項目
  Map<String, String> _matchingPairs = {
    '品名': '品名記号',
    '形式': '形格',
    '個数': '数量',
    '図書番号': '製品コード番号'
  };
  String _keyOrderNo = 'ORDER No.';
  String _keyItemNo = 'ITEM OF SPARE';

  // 黒塗り設定
  File? _sampleImage;
  ui.Image? _decodedImage;
  List<Rect> _relativeRects = [];
  Rect? _currentDrawingRect;
  Offset? _startDragPos; 
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.existingProfile != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final p = widget.existingProfile!;
    _nameController.text = p.profileName;
    
    if (p.extractionMode != null) {
      _selectedType = ProfileType.values.firstWhere(
        (e) => e.toString() == p.extractionMode,
        orElse: () => ProfileType.standard,
      );
    }

    if (p.productListFieldsJson != null) {
      try {
        final List<dynamic> list = jsonDecode(p.productListFieldsJson!);
        _productListFields = list.cast<String>();
      } catch (e) { /* ignore */ }
    }

    // ★ 荷札項目復元
    if (p.nifudaFieldsJson != null) {
      try {
        final List<dynamic> list = jsonDecode(p.nifudaFieldsJson!);
        _nifudaFields = list.cast<String>();
      } catch (e) { /* ignore */ }
    }

    if (p.matchingPairsJson != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(p.matchingPairsJson!);
        _matchingPairs = map.cast<String, String>();
      } catch (e) { /* ignore */ }
    }

    try {
      final List<dynamic> list = jsonDecode(p.rectsJson);
      _relativeRects = list.map((s) {
        final parts = s.toString().split(',');
        return Rect.fromLTWH(
          double.parse(parts[0]), double.parse(parts[1]), 
          double.parse(parts[2]), double.parse(parts[3])
        );
      }).toList();
    } catch (e) { /* ignore */ }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // --- 保存処理 ---
  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      showCustomSnackBar(context, 'プロファイル名を入力してください', isError: true);
      _tabController.animateTo(0);
      return;
    }
    
    if (!_productListFields.contains(_keyOrderNo) || !_productListFields.contains(_keyItemNo)) {
       showCustomSnackBar(context, '製番・項番に対応する項目がリストに存在しません', isError: true);
       _tabController.animateTo(1);
       return;
    }

    final List<String> rectData = _relativeRects.map((r) => 
      "${r.left},${r.top},${r.width},${r.height}"
    ).toList();
    
    try {
      final db = ref.read(appDatabaseInstanceProvider);
      
      final companion = MaskProfilesCompanion(
        id: widget.existingProfile != null ? drift.Value(widget.existingProfile!.id) : const drift.Value.absent(),
        profileName: drift.Value(_nameController.text),
        rectsJson: drift.Value(jsonEncode(rectData)),
        productListFieldsJson: drift.Value(jsonEncode(_productListFields)),
        nifudaFieldsJson: drift.Value(jsonEncode(_nifudaFields)), // ★ 保存
        matchingPairsJson: drift.Value(jsonEncode(_matchingPairs)),
        extractionMode: drift.Value(_selectedType.toString()),
        promptId: const drift.Value('custom'), 
      );

      await db.maskProfilesDao.insertOrUpdateProfile(companion);
      
      if (mounted) {
        showCustomSnackBar(context, '保存しました');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showCustomSnackBar(context, '保存エラー: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProfile == null ? '新規プロファイル作成' : 'プロファイル編集'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile),
        ],
        bottom: TabBar(
          controller: _tabController,
          // ★ タブ色を白に変更
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: '基本設定'),
            Tab(text: '項目・照合'),
            Tab(text: '黒塗り設定'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), 
        children: [
          _buildBasicTab(),
          _buildFieldsTab(),
          _buildMaskTab(),
        ],
      ),
    );
  }

  Widget _buildBasicTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '会社名・生産課名',
              hintText: '例: A社 第1生産課',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('抽出モード (AIの読み取り方)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<ProfileType>(
            value: _selectedType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: ProfileType.standard, child: Text('標準 (汎用)')),
              // ★ 表示名を指定のものに変更
              DropdownMenuItem(value: ProfileType.tmeic, child: Text('TMEIC DS産')),
              DropdownMenuItem(value: ProfileType.tmeic_ups_2, child: Text('TMEIC UPS産二')),
              DropdownMenuItem(value: ProfileType.fullRow, child: Text('東芝 鉄シブ・鉄シ産')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedType = val);
            },
          ),
          const SizedBox(height: 16),
          const Text('※ 帳票のレイアウトに近いものを選択してください。', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFieldsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 荷札の項目定義 ---
          const Text('荷札の項目定義 (OCR対象)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('荷札から読み取る項目を設定します。', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ..._nifudaFields.map((f) => Chip(
                label: Text(f),
                onDeleted: () {
                  setState(() {
                    _nifudaFields.remove(f);
                    // ★ 連携: 照合パターンからも削除
                    _matchingPairs.remove(f);
                  });
                },
              )),
              ActionChip(
                label: const Icon(Icons.add, size: 16),
                onPressed: () => _showAddFieldDialog(isNifuda: true),
              )
            ],
          ),

          const Divider(height: 32),

          // --- 製品リストの項目定義 ---
          const Text('製品リストの項目定義', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('製品リストから読み取る項目を設定します。', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ..._productListFields.map((f) => Chip(
                label: Text(f),
                onDeleted: () => setState(() => _productListFields.remove(f)),
              )),
              ActionChip(
                label: const Icon(Icons.add, size: 16),
                onPressed: () => _showAddFieldDialog(isNifuda: false),
              )
            ],
          ),

          const Divider(height: 32),
          const Text('照合キーの設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _productListFields.contains(_keyOrderNo) ? _keyOrderNo : null,
                  decoration: const InputDecoration(labelText: '製番にあたる項目'),
                  items: _productListFields.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _keyOrderNo = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _productListFields.contains(_keyItemNo) ? _keyItemNo : null,
                  decoration: const InputDecoration(labelText: '項番にあたる項目'),
                  items: _productListFields.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _keyItemNo = v!),
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // --- 照合パターン設定 ---
          const Text('照合パターンの設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('荷札の項目 vs 製品リストの項目', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          
          // ★ 荷札項目リストに基づいて動的に生成
          ..._nifudaFields.where((f) => f != '製番' && f != '項目番号').map((nifudaItem) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  SizedBox(width: 100, child: Text(nifudaItem, style: const TextStyle(fontWeight: FontWeight.bold))),
                  const Icon(Icons.arrow_right_alt),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _matchingPairs.containsKey(nifudaItem) && _productListFields.contains(_matchingPairs[nifudaItem]) 
                          ? _matchingPairs[nifudaItem] 
                          : 'null_placeholder', 
                      isDense: true,
                      items: [
                        const DropdownMenuItem(value: 'null_placeholder', child: Text('(照合なし)', style: TextStyle(color: Colors.grey))),
                        ..._productListFields.map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      ],
                      onChanged: (val) {
                        setState(() {
                          if (val == 'null_placeholder') {
                            _matchingPairs.remove(nifudaItem);
                          } else {
                            _matchingPairs[nifudaItem] = val!;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showAddFieldDialog({required bool isNifuda}) {
    final textController = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(isNifuda ? '荷札項目を追加' : '製品リスト項目を追加'),
      content: TextField(
        controller: textController,
        decoration: const InputDecoration(hintText: '例: 型式, 数量'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
        TextButton(onPressed: () {
          final text = textController.text.trim();
          if (text.isNotEmpty) {
            final splits = text.split(RegExp(r'[,、]'));
            setState(() {
              final targetList = isNifuda ? _nifudaFields : _productListFields;
              for (var s in splits) {
                final clean = s.trim();
                if (clean.isNotEmpty && !targetList.contains(clean)) {
                  targetList.add(clean);
                }
              }
            });
          }
          Navigator.pop(ctx);
        }, child: const Text('追加')),
      ],
    ));
  }

  Widget _buildMaskTab() {
    return Column(
      children: [
        if (_sampleImage == null)
          Expanded(
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.document_scanner),
                label: const Text('サンプル画像をスキャン'),
                onPressed: _scanDocument,
              ),
            ),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
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
                        imageSize: _decodedImage != null ? Size(_decodedImage!.width.toDouble(), _decodedImage!.height.toDouble()) : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_sampleImage != null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('再スキャン'),
                  onPressed: _scanDocument,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('範囲クリア', style: TextStyle(color: Colors.red)),
                  onPressed: () => setState(() => _relativeRects.clear()),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- 以下、黒塗りロジック（既存） ---
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
      if(mounted) showCustomSnackBar(context, 'スキャンエラー: $e', isError: true);
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
    final FittedSizes fittedSizes = applyBoxFit(BoxFit.contain, imageSize, containerSize);
    final Size destSize = fittedSizes.destination; 
    final double dx = (containerSize.width - destSize.width) / 2;
    final double dy = (containerSize.height - destSize.height) / 2;
    final Rect imageRect = Rect.fromLTWH(dx, dy, destSize.width, destSize.height);
    final Rect intersection = _currentDrawingRect!.intersect(imageRect);

    if (intersection.width > 0 && intersection.height > 0) {
      final relRect = Rect.fromLTRB(
        (intersection.left - dx) / destSize.width,
        (intersection.top - dy) / destSize.height,
        (intersection.right - dx) / destSize.width,
        (intersection.bottom - dy) / destSize.height,
      );
      setState(() {
        _relativeRects.add(relRect);
      });
    }
    setState(() {
      _currentDrawingRect = null;
      _startDragPos = null;
    });
  }
}

class _MaskEditPainter extends CustomPainter {
  final List<Rect> rects;
  final Rect? currentRect;
  final Size? imageSize; 
  _MaskEditPainter({required this.rects, this.currentRect, this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6); 
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