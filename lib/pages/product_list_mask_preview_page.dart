import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/ocr_masker.dart';
import '../widgets/custom_snackbar.dart'; // custom_snackbar.dartをインポート

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
  State<ProductListMaskPreviewPage> createState() => _ProductListMaskPreviewPageState();
}

class _ProductListMaskPreviewPageState extends State<ProductListMaskPreviewPage> {
  Future<Uint8List>? _maskingFuture;
  Uint8List? _maskedImageBytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _maskingFuture = _applyMask();
  }

  Future<Uint8List> _applyMask() async {
    try {
      final bytes = await applyMaskToImage(widget.originalImageBytes, template: widget.maskTemplate);
      if(mounted) setState(() => _maskedImageBytes = bytes);
      return bytes;
    } catch (e) {
      if(mounted) setState(() => _error = 'マスク処理中にエラーが発生しました: $e');
      showTopSnackBar(context, 'マスク処理中にエラーが発生しました: $e', isError: true);
      throw Exception('Masking failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('マスクプレビュー (${widget.imageIndex} / ${widget.totalImages})'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: FutureBuilder<Uint8List>(
                  future: _maskingFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError || _error != null) {
                      return Text(_error ?? '不明なエラー', style: const TextStyle(color: Colors.red));
                    }
                    if (snapshot.hasData) {
                      return InteractiveViewer(
                        child: Image.memory(snapshot.data!),
                      );
                    }
                    return const Text('画像を読み込めません');
                  },
                ),
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
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('この内容で送信'),
                  onPressed: _maskedImageBytes == null ? null : () => Navigator.pop(context, _maskedImageBytes), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700], 
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}