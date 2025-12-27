// lib/pages/product_list_ocr_confirm_page.dart
import 'package:flutter/material.dart';

class ProductListOcrConfirmPage extends StatefulWidget {
  final List<Map<String, String>> extractedProductRows;
  // ★ 追加: 表示するカラムのリストを受け取る
  final List<String> displayFields;

  const ProductListOcrConfirmPage({
    super.key,
    required this.extractedProductRows,
    required this.displayFields,
  });

  @override
  State<ProductListOcrConfirmPage> createState() => _ProductListOcrConfirmPageState();
}

class _ProductListOcrConfirmPageState extends State<ProductListOcrConfirmPage> {
  late List<Map<String, String>> _currentProductRows;

  @override
  void initState() {
    super.initState();
    // 受け取ったデータとフィールド定義に基づいてデータを整形
    _currentProductRows = widget.extractedProductRows.map((rowMap) {
      Map<String, String> structuredRow = {};
      for (String fieldName in widget.displayFields) {
        // フィールドに対応する値があれば取得、なければ空文字
        structuredRow[fieldName] = rowMap[fieldName]?.trim() ?? '';
      }
      return structuredRow;
    }).toList();
  }

  void _onConfirm() {
    // 確定時は「リストのリスト」形式にして返す
    final List<List<String>> confirmedDataAsListOfList = _currentProductRows.map((rowMap) {
      return widget.displayFields.map((fieldName) {
        return rowMap[fieldName]?.trim() ?? '';
      }).toList();
    }).toList();
    Navigator.pop(context, confirmedDataAsListOfList);
  }

  void _onDeleteAll() {
    Navigator.pop(context, null); // nullを返して全破棄
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('製品リストOCR結果確認'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // スクロール可能なテーブル部分
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: _currentProductRows.isEmpty
                    ? const Center(child: Text('表示する製品データがありません。'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            // ★ widget.displayFields を使って動的にカラム生成
                            columns: widget.displayFields
                                .map((field) => DataColumn(label: Text(field, style: const TextStyle(fontWeight: FontWeight.bold))))
                                .toList(),
                            rows: _currentProductRows.asMap().entries.map((entry) {
                               final rowData = entry.value;
                               return DataRow(
                                 cells: [
                                   // 各フィールドの値をセルに設定
                                   ...widget.displayFields.map((field) {
                                     return DataCell(Text(rowData[field] ?? ''));
                                   }),
                                 ]
                               );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
            // 画面下部のボタン部分
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('全て破棄'),
                      onPressed: _onDeleteAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text('確定 (${_currentProductRows.length}件)'),
                      onPressed: _currentProductRows.isEmpty ? null : _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
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