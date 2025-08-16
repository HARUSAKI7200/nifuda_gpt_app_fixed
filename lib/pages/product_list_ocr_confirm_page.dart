import 'package:flutter/material.dart';

class ProductListOcrConfirmPage extends StatefulWidget {
  final List<Map<String, String>> extractedProductRows;

  static const List<String> productFields = [
    'ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考'
  ];

  const ProductListOcrConfirmPage({
    super.key,
    required this.extractedProductRows,
  });

  @override
  State<ProductListOcrConfirmPage> createState() => _ProductListOcrConfirmPageState();
}

class _ProductListOcrConfirmPageState extends State<ProductListOcrConfirmPage> {
  late List<Map<String, String>> _currentProductRows;

  @override
  void initState() {
    super.initState();
    // ここで extractedProductRows を ProductListOcrConfirmPage.productFields に基づいて整形し直す
    _currentProductRows = widget.extractedProductRows.map((rowMap) {
      Map<String, String> structuredRow = {};
      for (String fieldName in ProductListOcrConfirmPage.productFields) {
        // 全ての期待されるフィールドに対して、値が存在するか確認し、なければ空文字列を割り当てる
        structuredRow[fieldName] = rowMap[fieldName]?.trim() ?? '';
      }
      return structuredRow;
    }).toList();
  }

  void _onConfirm() {
    final List<List<String>> confirmedDataAsListOfList = _currentProductRows.map((rowMap) {
      return ProductListOcrConfirmPage.productFields.map((fieldName) {
        return rowMap[fieldName]?.trim() ?? '';
      }).toList();
    }).toList();
    Navigator.pop(context, confirmedDataAsListOfList);
  }

  void _onDeleteAll() {
    Navigator.pop(context, null); // nullを返して全破棄
  }

  void _removeRow(int rowIndex) {
    setState(() {
      if (rowIndex >= 0 && rowIndex < _currentProductRows.length) {
        _currentProductRows.removeAt(rowIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
    // ★ 変更点：手動での下部パディング計算を削除
    // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
    // final double buttonBottomPosition = 15.0 + 60.0 + 10.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('製品リストOCR結果確認'),
      ),
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
      // ★ 変更点：body全体をSafeAreaでラップ
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
      body: SafeArea(
        child: Column( // Stackの代わりにColumnを使用
          children: [
            // スクロール可能なテーブル部分
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), // 下パディングを削除
                child: _currentProductRows.isEmpty
                    ? const Center(child: Text('表示する製品データがありません。'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: ProductListOcrConfirmPage.productFields
                                .map((field) => DataColumn(label: Text(field, style: const TextStyle(fontWeight: FontWeight.bold))))
                                .toList(),
                            rows: _currentProductRows.asMap().entries.map((entry) {
                               final rowIndex = entry.key;
                               final rowData = entry.value;
                               return DataRow(
                                 cells: [
                                   // 各フィールドに対して、rowDataから値を取得し、なければ空文字列を割り当てる
                                   ...ProductListOcrConfirmPage.productFields.map((field) {
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
                        padding: const EdgeInsets.symmetric(vertical: 12), // 垂直パディングのみ
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // ボタン間のスペース
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text('確定 (${_currentProductRows.length}件)'),
                      onPressed: _currentProductRows.isEmpty ? null : _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12), // 垂直パディングのみ
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