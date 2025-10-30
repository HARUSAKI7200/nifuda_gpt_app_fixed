// lib/widgets/excel_preview_dialog.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../utils/excel_export.dart';
import 'custom_snackbar.dart';

class ExcelPreviewDialog extends StatelessWidget {
  final String title;
  final List<List<String>> data;
  final List<String> headers;
  final String projectFolderPath;
  final String subfolder; // 例: '荷札リスト/#1'

  const ExcelPreviewDialog({
    super.key,
    required this.title,
    required this.data,
    required this.headers,
    required this.projectFolderPath,
    required this.subfolder,
  });

  Future<void> _exportExcel(BuildContext context) async {
    if (data.length <= 1) {
      showCustomSnackBar(context, 'エクスポートするデータがありません。', isError: true);
      return;
    }

    try {
      if (!context.mounted) return;
      showCustomSnackBar(context, 'Excelファイルを保存しています...', showAtTop: true);

      // ★ 修正: ファイル名を生成 (サブフォルダ名 + タイムスタンプ)
      final safeSubfolderName = subfolder.replaceAll(RegExp(r'[/\\]'), '_');
      final fileName = '${safeSubfolderName}_${_formatTimestampForFilename(DateTime.now())}.xlsx';
      
      final rowsWithoutHeader = data.sublist(1); // ヘッダーを除いたデータ行

      final results = await exportToExcelStorage(
        fileName: fileName,
        sheetName: title.replaceAll(RegExp(r'[/\\]'), ' '), // シート名はファイル名に使えない文字を置換
        headers: headers,
        rows: rowsWithoutHeader,
        projectFolderPath: projectFolderPath,
        subfolder: subfolder,
      );

      if (!context.mounted) return;
      showCustomSnackBar(context, '保存完了: ローカル(${results['local']}), SMB(${results['smb']})', durationSeconds: 5);

    } catch (e) {
      if (!context.mounted) return;
      showCustomSnackBar(context, 'Excelエクスポートエラー: $e', isError: true);
    }
  }

  // home_actions.dart からコピーしたユーティリティ関数
  String _formatTimestampForFilename(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportExcel(context),
            tooltip: 'Excelとして保存',
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            rows: data.sublist(1).map((row) {
              return DataRow(
                cells: row.map((cell) => DataCell(Text(cell))).toList(),
              );
            }).toList(),
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