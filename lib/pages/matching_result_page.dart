// lib/pages/matching_result_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_logs/flutter_logs.dart'; // ★ 修正: インポート追加
import '../utils/excel_export.dart';
import '../widgets/custom_snackbar.dart';
import 'home_actions.dart';
import '../state/project_state.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart' show Value; // DB更新のため

class MatchingResultPage extends ConsumerWidget {
  final Map<String, dynamic> matchingResults;
  final String projectFolderPath;
  final String projectTitle;
  final List<List<String>> nifudaData;
  final List<List<String>> productListKariData;
  final String currentCaseNumber;

  const MatchingResultPage({
    super.key,
    required this.matchingResults,
    required this.projectFolderPath,
    required this.projectTitle,
    required this.nifudaData,
    required this.productListKariData,
    required this.currentCaseNumber,
  });

  List<String> get _excelHeaders {
    return [
      '照合結果', '荷札_製番', '荷札_項目番号', '荷札_品名',
      '製品_ORDER No.', '製品_品名記号', '製品_製品コード番号',
      '照合済Case', '照合に使用したCase'
    ];
  }

  // ★ 修正: 戻り値の型 List<List<String>> を保証
  List<List<String>> get _excelData {
    final List<Map<String, dynamic>> allRows = [
      ...(matchingResults['matched'] as List<dynamic>).cast<Map<String, dynamic>>(),
      ...(matchingResults['unmatched'] as List<dynamic>).cast<Map<String, dynamic>>(),
      ...(matchingResults['missing'] as List<dynamic>).cast<Map<String, dynamic>>(),
    ];

    // ★ 修正: map の結果を List<String> にする
    return allRows.map((row) {
      // ★★★ バグ修正: as Map<String, dynamic>? ?? {} を as Map? ?? {} に変更
      final nifuda = row['nifuda'] as Map? ?? {}; // null チェック追加
      final product = row['product'] as Map? ?? {}; // null チェック追加
      final status = row['照合ステータス'] as String? ?? '';

      // ★ 修正: nifuda Mapから 'Case No.' を取得
      final matchingCase = nifuda['Case No.']?.toString() ?? currentCaseNumber;

      return <String>[ // 明示的に List<String> を返す
        status,
        nifuda['製番']?.toString() ?? '', nifuda['項目番号']?.toString() ?? '', nifuda['品名']?.toString() ?? '',
        product['ORDER No.']?.toString() ?? '', product['品名記号']?.toString() ?? '', product['製品コード番号']?.toString() ?? '',
        product['照合済Case']?.toString() ?? '',
        matchingCase,
      ];
    }).toList();
  }

  Future<String?> _saveAsExcel(BuildContext context, List<String> headers, List<List<String>> data, bool silent) async {
    try {
      final fileName = 'MatchingResult_${currentCaseNumber}_${_formatTimestampForFilename(DateTime.now())}.xlsx';
      final rowsWithoutHeader = data;

      final results = await exportToExcelStorage(
        fileName: fileName,
        sheetName: '照合結果_${currentCaseNumber}',
        headers: headers,
        rows: rowsWithoutHeader,
        projectFolderPath: projectFolderPath,
        subfolder: '照合結果/$currentCaseNumber',
      );
      if (!silent && context.mounted) {
        showCustomSnackBar(context, '照合結果を保存しました。ローカル: ${results['local']}, SMB: ${results['smb']}', durationSeconds: 5);
      }
      return p.join(projectFolderPath, '照合結果', currentCaseNumber, fileName);
    } catch (e) {
      if (!silent && context.mounted) {
        showCustomSnackBar(context, '照合結果の保存に失敗しました: $e', isError: true);
      }
      return null;
    }
  }

  void _moveToNextCase(BuildContext context, WidgetRef ref) {
    final currentNumber = int.tryParse(currentCaseNumber.replaceAll('#', '')) ?? 1;
    final nextNumber = currentNumber + 1;

    if (nextNumber > 50) {
      showCustomSnackBar(context, 'Case No. #50が最終です。', isError: true);
      return;
    }

    final nextCaseNumber = '#$nextNumber';
    final notifier = ref.read(projectProvider.notifier);
    notifier.updateCaseNumber(nextCaseNumber);

    Navigator.of(context).popUntil((route) => route.isFirst);
    showCustomSnackBar(context, 'Case No.を $nextCaseNumber に切り替えました。', showAtTop: true);
  }

  Future<void> _updateMatchedProducts(BuildContext context, WidgetRef ref) async {
    final matchedRows = (matchingResults['matched'] as List<dynamic>).cast<Map<String, dynamic>>();
    final db = ref.read(appDatabaseInstanceProvider);
    final productListDao = db.productListRowsDao;

    final projectState = ref.read(projectProvider);
    final projectId = projectState.currentProjectId;

    if (projectId == null) {
      showCustomSnackBar(context, 'DBプロジェクト未選択のため、照合済みマークは更新されません (JSONモード)。', isError: false, durationSeconds: 4);
      return;
    }

    final productRowsFromDb = await productListDao.getAllProductListRows(projectId);
    final productDbMap = { for (var row in productRowsFromDb) (row.orderNo + row.itemOfSpare) : row };


    List<Future<int>> updateFutures = [];

    for (final matchedRow in matchedRows) {
        // ★★★ バグ修正(予防): as Map<String, dynamic>? ?? {} を as Map? ?? {} に変更
        final productMap = matchedRow['product'] as Map? ?? {};
        final productKey = (productMap['ORDER No.']?.toString() ?? '') + (productMap['ITEM OF SPARE']?.toString() ?? '');

        final dbRow = productDbMap[productKey];

        if (dbRow != null) {
            updateFutures.add(productListDao.updateMatchedCase(dbRow.id, currentCaseNumber));
        }
    }

    if (updateFutures.isNotEmpty) {
      await Future.wait(updateFutures);
      FlutterLogs.logInfo('DB_ACTION', 'UPDATE_MATCHED_CASE', '${updateFutures.length} product rows marked as matched for Case $currentCaseNumber.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> displayHeaders = [
      '結果', '荷札_製番/項目番号', '製品_Order No./Item', '詳細'
    ];
    final allRows = [
      ...(matchingResults['matched'] as List<dynamic>).cast<Map<String, dynamic>>(),
      ...(matchingResults['unmatched'] as List<dynamic>).cast<Map<String, dynamic>>(),
      ...(matchingResults['missing'] as List<dynamic>).cast<Map<String, dynamic>>(),
    ];

    final projectState = ref.watch(projectProvider);
    final notifier = ref.read(projectProvider.notifier);

    final headers = _excelHeaders;
    final data = _excelData;

    return Scaffold(
      appBar: AppBar(
        title: Text('照合結果 (Case ${currentCaseNumber})'),
        actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveAsExcel(context, headers, data, false),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                 scrollDirection: Axis.vertical,
                 child: DataTable(
                    columns: displayHeaders.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    rows: allRows.map((row) {
                      final status = row['照合ステータス'] as String? ?? '';
                      final isMatched = status.contains('一致') || status.contains('再');
                      final isSkipped = status.contains('スキップ');
                      // ★★★ バグ修正: as Map<String, dynamic>? ?? {} を as Map? ?? {} に変更
                      final nifuda = row['nifuda'] as Map? ?? {};
                      final product = row['product'] as Map? ?? {};

                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                          if (isMatched) return Colors.green.shade100;
                          if (status.contains('未検出') || status.contains('失敗')) return Colors.red.shade100;
                          if (isSkipped) return Colors.yellow.shade100;
                          return null;
                        }),
                        cells: [
                          DataCell(Text(status)),
                          DataCell(Text('${nifuda['製番']?.toString() ?? ''}-${nifuda['項目番号']?.toString() ?? ''}')),
                          DataCell(Text(isMatched || isSkipped ? '${product['ORDER No.']?.toString() ?? ''}/${product['ITEM OF SPARE']?.toString() ?? ''}' : (product['ORDER No.']?.toString() ?? ''))),
                          DataCell(Text(row['詳細']?.toString() ?? '')),
                        ],
                      );
                    }).toList(),
                  ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      icon: const Icon(Icons.skip_next),
                      label: Text('次のCase (${'#${(int.tryParse(currentCaseNumber.replaceAll('#', '')) ?? 1) + 1}'})へ', style: const TextStyle(fontSize: 16)),
                      onPressed: () async {
                         await _updateMatchedProducts(context, ref);
                         _moveToNextCase(context, ref);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      icon: const Icon(Icons.share),
                      label: const Text('検品完了＆共有', style: const TextStyle(fontSize: 16)),
                      onPressed: () async {
                        await _updateMatchedProducts(context, ref);

                        // ★ 修正: productListData: productListKariData
                        final newStatus = await exportAllProjectDataAction(
                            context: context,
                            projectTitle: projectTitle,
                            projectFolderPath: projectFolderPath,
                            nifudaData: nifudaData,
                            productListData: productListKariData, // ★ 修正
                            matchingResults: matchingResults,
                            currentCaseNumber: currentCaseNumber,
                            jsonSavePath: projectState.jsonSavePath,
                            inspectionStatus: STATUS_COMPLETED,
                        );

                        if (newStatus == STATUS_COMPLETED) {
                           if (projectState.currentProjectId != null) {
                              await notifier.updateProjectStatus(STATUS_COMPLETED);
                           } else {
                              notifier.updateProjectStatus(STATUS_COMPLETED);
                           }
                           if(context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestampForFilename(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}

// 補助的な拡張関数 (List<ProductListRow>の検索用)
extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}