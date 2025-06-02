// lib/pages/matching_result_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/excel_export.dart';
import '../widgets/custom_snackbar.dart';

class MatchingResultPage extends StatelessWidget {
  final Map<String, dynamic> matchingResults;
  final String projectFolderPath; // 追加

  const MatchingResultPage({super.key, required this.matchingResults, required this.projectFolderPath}); // 追加

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allRows = [
      ...(matchingResults['matched'] as List<dynamic>).cast<Map<String, dynamic>>(),
      ...(matchingResults['unmatched'] as List<dynamic>).cast<Map<String, dynamic>>(),
      ...(matchingResults['missing'] as List<dynamic>).cast<Map<String, dynamic>>(),
    ];

    final List<String> displayHeaders = allRows.isNotEmpty
        ? _getSortedHeaders(allRows.first.keys.toList())
        : ['照合結果'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('照合結果'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Excelで保存',
            onPressed: allRows.isEmpty ? null : () => _saveAsExcel(context, displayHeaders, allRows),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0), 
        child: allRows.isEmpty
            ? const Center(child: Text('照合結果データがありません。'))
            : SingleChildScrollView( 
                child: SingleChildScrollView( 
                  scrollDirection: Axis.horizontal,
                  child: DataTable( 
                    columnSpacing: 12.0,
                    columns: displayHeaders
                        .map((header) => DataColumn(
                              label: Text(header, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ))
                        .toList(),
                    rows: allRows.map((resultMap) {
                      return DataRow(
                        cells: displayHeaders.map((header) {
                          final cellValue = resultMap[header]?.toString() ?? '';
                          final status = resultMap['照合ステータス']?.toString() ?? '';
                          final mismatches = (resultMap['不一致項目リスト'] as List<dynamic>?)?.cast<String>() ?? [];
                          
                          Color cellColor = Colors.black;
                          if (mismatches.any((mismatch) => header.contains(mismatch.split('/').first))) {
                            cellColor = Colors.red.shade700;
                          }

                          if (header == '照合ステータス') {
                            if (status == '一致') cellColor = Colors.green.shade700;
                            else if (status.contains('不一致')) cellColor = Colors.red.shade700;
                            else if (status.contains('未検出')) cellColor = Colors.orange.shade700;
                          }

                          return DataCell(
                            Text(cellValue, style: TextStyle(fontSize: 12, color: cellColor)),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: allRows.isEmpty ? null : () => _saveAsExcel(context, displayHeaders, allRows), 
        icon: const Icon(Icons.download_for_offline_outlined),
        label: const Text('Excelで保存'),
      ),
    );
  }

  List<String> _getSortedHeaders(List<String> originalHeaders) {
    const preferredOrder = ['照合ステータス', '製番', '項目番号', '手配コード', '品名', '形式', '個数', 'ORDER No.', 'ITEM OF SPARE', '製品コード番号'];
    List<String> sorted = [];
    for (var key in preferredOrder) {
      final match = originalHeaders.firstWhere((h) => h.contains(key), orElse: () => '');
      if (match.isNotEmpty && !sorted.contains(match)) {
        sorted.add(match);
      }
    }
    for (var header in originalHeaders) {
      if (!sorted.contains(header)) {
        sorted.add(header);
      }
    }
    return sorted;
  }

  Future<void> _saveAsExcel(BuildContext context, List<String> headers, List<Map<String, dynamic>> data) async {
    final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '照合結果_$now.xlsx';

    final List<List<String>> dataRows = data.map((resultMap) {
      return headers.map((header) => resultMap[header]?.toString() ?? '').toList();
    }).toList();

    try {
      final filePath = await exportToExcelStorage( 
        fileName: fileName,
        sheetName: '照合結果',
        headers: headers,
        rows: dataRows,
        projectFolderPath: projectFolderPath, // 渡されたパスを使用
        subfolder: '抽出結果', // サブフォルダ名を指定
      );
      if (context.mounted) {
        showTopSnackBar(context, 'Excelを保存しました: $filePath');
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('保存エラー'),
                  content: Text('Excelファイルの保存に失敗しました: $e'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ));
      }
    }
  }
}