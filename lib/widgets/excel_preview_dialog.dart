// lib/widgets/excel_preview_dialog.dart
import 'package:flutter/material.dart';
import 'custom_snackbar.dart';

class ExcelPreviewDialog extends StatelessWidget {
  final String title;
  final List<List<String>> data;
  final List<String> headers;
  // 保存用のパス引数 (projectFolderPath, subfolder) を削除

  const ExcelPreviewDialog({
    super.key,
    required this.title,
    required this.data,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length <= 1) {
      // データがない場合の表示（通常ここには到達しない想定だが念のため）
      return AlertDialog(
        title: Text(title),
        content: const Text('表示するデータがありません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      );
    }

    return AlertDialog(
      // タイトル行から保存ボタンを削除
      title: Text(title),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: headers
                  .map((h) => DataColumn(
                      label: Text(h,
                          style: const TextStyle(fontWeight: FontWeight.bold))))
                  .toList(),
              rows: data.sublist(1).map((row) {
                return DataRow(
                  cells: row.map((cell) => DataCell(Text(cell))).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}