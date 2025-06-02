import 'package:flutter/material.dart';

class TProductTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows; // GPTからの処理済みデータ (各行にORDER No.も含む)

  const TProductTable({
    Key? key,
    required this.rows,
  }) : super(key: key);

  // ★ 表示する列の順番と名前を定義（ORDER No. を先頭に）
  // このリストは product_list_ocr_confirm_page.dart の productFields と一致させるのが望ましい
  static const List<String> _columns = [
    'ORDER No.',
    'ITEM OF SPARE',
    '品名記号', // GPTが返すMapのキーと完全に一致させる
    '形格',
    '製品コード番号',
    '注文数',
    '記事',
    '備考'
  ];

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('表示する製品データがありません。'));
    }
    
    return SingleChildScrollView( // 表全体が画面を超える場合に縦スクロール
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView( // 表の内容が画面幅を超える場合に横スクロール
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18.0, // 列間のスペース
          headingRowHeight: 48.0, // ヘッダー行の高さ
          dataRowMinHeight: 40.0, 
          dataRowMaxHeight: 56.0,
          columns: _columns
              .map((colName) => DataColumn(
                    label: Text(
                      colName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // ヘッダーのスタイル
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          rows: rows.map((rowMap) { // 各rowMapが製品一行分のデータ
            return DataRow(
              cells: _columns.map((colName) { // 定義された列の順番でセルを作成
                final val = rowMap[colName]?.toString() ?? ''; // Mapから値を取得
                return DataCell(
                  Padding( // セル内のパディング
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(val, style: const TextStyle(fontSize: 13)),
                  )
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}