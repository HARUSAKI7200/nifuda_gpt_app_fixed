// lib/widgets/excel_preview_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/excel_export.dart';
import '../widgets/custom_snackbar.dart';

class ExcelPreviewDialog extends StatelessWidget {
  final String title;
  final List<List<String>> data;
  final List<String> headers;
  final String projectFolderPath; // 追加
  final String? subfolder; // 追加

  const ExcelPreviewDialog({
    super.key,
    required this.title,
    required this.data,
    required this.headers,
    required this.projectFolderPath, // 追加
    this.subfolder, // 追加
  });

  @override
  Widget build(BuildContext context) {
    final dataRows = data.length > 1 ? data.sublist(1) : <List<String>>[];

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: dataRows.isEmpty
            ? const Center(child: Text('表示するデータがありません。'))
            : SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: headers
                        .map((headerText) => DataColumn(
                              label: Text(headerText, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                    rows: dataRows.map((row) {
                      return DataRow(
                        cells: headers.asMap().entries.map((entry) {
                          final colIndex = entry.key;
                          return DataCell(Text(colIndex < row.length ? row[colIndex] : ''));
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: <Widget>[
        TextButton(
          child: const Text('閉じる'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save_alt_rounded),
          label: const Text('Excel保存'),
          onPressed: dataRows.isEmpty
              ? null
              : () async {
                  final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                  final baseFileName = title.replaceAll(' ', '_').replaceAll(':', '').replaceAll('-', '_');
                  final fileName = '${baseFileName}_$now.xlsx';

                  try {
                    final filePath = await exportToExcelStorage(
                      fileName: fileName,
                      sheetName: title,
                      headers: headers,
                      rows: dataRows,
                      projectFolderPath: projectFolderPath, // 渡されたパスを使用
                      subfolder: subfolder, // 渡されたサブフォルダを使用
                    );
                    if (context.mounted) {
                      showTopSnackBar(context, 'Excelファイルを保存しました: $filePath');
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                                title: const Text('Excel保存エラー'),
                                content: Text('保存に失敗しました: $e'),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                              ));
                    }
                  }
                },
        ),
      ],
    );
  }
}