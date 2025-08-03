// widgets/ocr_result_table.dart
import 'package:flutter/material.dart';
// custom_snackbar.dartはここでは直接使用しないためインポートなし

class OcrResultTable extends StatelessWidget {
  final List<Map<String, String>> rows;

  const OcrResultTable({super.key, required this.rows});

  String normalizeValue(String? value) {
    if (value == '不明') return '';
    if (value == null) return '未検出'; // null のみ未検出
    return value.trim(); // 空文字列は空欄表示のまま許容
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('表示可能な項目がありません'));
    }

    // データを行と列に変換する (もし入力形式が異なる場合)
    // 現在は List<Map<String, String>> で各Mapが {'項目': 'X', '値': 'Y'} を想定

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('項目', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('値', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: rows.map((rowMap) { // 各Mapが一つの行に対応
            return DataRow(
              cells: [
                DataCell(Text(rowMap['項目'] ?? '')),
                DataCell(Text(normalizeValue(rowMap['値']))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}