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
    return Scaffold(
      appBar: AppBar(
        title: const Text('製品リストOCR結果確認'),
      ),
      body: Column(
        children: [
          Expanded(
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
                               // 削除ボタン用のセルを追加 (これによりセルの数が1つ増えるため、DataColumnも調整が必要)
                               // しかし、この削除ボタンはテーブルのデータ列とは論理的に異なるため、
                               // DataTableのcolumnsには含まれないようにするか、専用のDataColumnを用意する必要があります。
                               // 今回は、エラーの原因である「セルの数」の不一致を解消するために、
                               // DataTableのcolumnsとcellsの数を完全に一致させます。
                               // 削除ボタンは別の場所（例えばFloatingActionButtonやRowの外）に移動するか、
                               // DataTableのcolumnに「操作」のようなものを追加し、DataCellでボタンを表示します。
                               // まずはエラー解消のため、DataCell(IconButton)をDataTableのcellsから削除します。
                               // もし削除ボタンが必要な場合は、別途DataTableのcolumnsにDataColumnを追加してください。
                               // または、行削除ロジックを変更し、DataTableのDataCellとしては表示しないようにします。
                             ]
                           );
                        }).toList(),
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
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('全て破棄'),
                  onPressed: _onDeleteAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600], 
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text('確定 (${_currentProductRows.length}件)'),
                  onPressed: _currentProductRows.isEmpty ? null : _onConfirm, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700], 
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}