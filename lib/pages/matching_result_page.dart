// lib/pages/matching_result_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_logs/flutter_logs.dart';
import '../utils/excel_export.dart';
import '../widgets/custom_snackbar.dart';
import 'home_actions.dart';
import '../state/project_state.dart';
import '../state/user_state.dart'; // ★ 追加
import '../database/app_database.dart';
import 'package:drift/drift.dart' show Value;

class MatchingResultPage extends ConsumerWidget {
  final Map<String, dynamic> matchingResults;
  final String projectFolderPath;
  final String projectTitle;
  final List<List<String>> nifudaData;
  final List<List<String>> productListKariData;
  final String currentCaseNumber;

  static const Map<String, String> _displayFieldsMap = {
    '製番': 'ORDER No.',
    '項目番号': 'ITEM OF SPARE',
    '品名': '品名記号',
    '形式': '形格',
    '個数': '注文数',
    '図書番号': '製品コード番号', 
    '手配コード': '製品コード番号',
    '記事': '記事', 
  };
  static const List<String> _nifudaFieldKeys = [
    '製番', '項目番号', '品名', '形式', '個数', '図書番号', '手配コード', '記事'
  ];

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

  List<List<String>> get _excelData {
    final List<Map<String, dynamic>> allRows = [
      ...(matchingResults['matched'] as List<dynamic>).cast<Map<String, dynamic>>(),
      ...(matchingResults['unmatched'] as List<dynamic>).cast<Map<String, dynamic>>(),
      ...(matchingResults['missing'] as List<dynamic>).cast<Map<String, dynamic>>(),
    ];

    return allRows.map((row) {
      final nifuda = row['nifuda'] as Map? ?? {};
      final product = row['product'] as Map? ?? {};
      final status = row['照合ステータス'] as String? ?? '';
      final matchingCase = nifuda['Case No.']?.toString() ?? currentCaseNumber;

      return <String>[
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
        skipPermissionCheck: false, 
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

  List<DataColumn> _buildColumns() {
    List<DataColumn> columns = [];
    columns.add(const DataColumn(
      label: Text('項目', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    ));
    
    columns.add(const DataColumn(
      label: Text('照合結果', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    ));
    
    columns.addAll(_nifudaFieldKeys.map((nifudaField) {
      return DataColumn(label: Text(nifudaField, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)));
    }));
    
    return columns;
  }

  List<DataRow> _buildDataRows() {
    final List<DataRow> dataRows = [];
    
    final List<Map<String, dynamic>> matchedRows = (matchingResults['matched'] as List<dynamic>).cast<Map<String, dynamic>>();
    final List<Map<String, dynamic>> unmatchedRows = (matchingResults['unmatched'] as List<dynamic>).cast<Map<String, dynamic>>();
    
    final List<Map<String, dynamic>> allRows = [...unmatchedRows, ...matchedRows];

    if (allRows.isEmpty) {
      return [];
    }

    for (final row in allRows) {
      final status = row['照合ステータス'] as String? ?? '';
      final nifuda = row['nifuda'] as Map? ?? {};
      final product = row['product'] as Map? ?? {};
      final mismatchFields = (row['不一致項目リスト'] as List<dynamic>?)?.cast<String>() ?? [];
      
      final isMatched = status.contains('一致') || status.contains('再');
      final isError = status.contains('未検出') || status.contains('失敗') || status.contains('不一致');

      Color rowColor = Colors.white;
      if (isMatched) {
        rowColor = Colors.green.shade50;
      } else if (isError) {
        rowColor = Colors.red.shade50;
      } else if (status.contains('スキップ')) {
        rowColor = Colors.yellow.shade100;
      }

      final List<DataCell> nifudaCells = [];
      nifudaCells.add(DataCell(Text('荷札', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo.shade700))));
      nifudaCells.add(DataCell(Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isError ? Colors.red.shade700 : (isMatched ? Colors.green.shade700 : Colors.orange.shade700)))));

      if (nifuda.isEmpty) {
        nifudaCells.addAll(_nifudaFieldKeys.map((_) => DataCell(_buildValueCell('---', true, false, rowColor))));
      } else {
        nifudaCells.addAll(_nifudaFieldKeys.map((nifudaField) {
          final nifudaValue = nifuda[nifudaField]?.toString() ?? '';
          bool isMismatch = mismatchFields.any((field) => field.startsWith(nifudaField));
          return DataCell(_buildValueCell(nifudaValue, isMismatch, false, rowColor));
        }));
      }
      dataRows.add(DataRow(cells: nifudaCells, color: MaterialStateProperty.all(rowColor)));

      final List<DataCell> productCells = [];
      productCells.add(DataCell(Text('リスト', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade700))));
      productCells.add(DataCell(Text(row['詳細']?.toString() ?? '', style: const TextStyle(fontSize: 10, color: Colors.black54))));

      if (product.isEmpty) {
        productCells.addAll(_nifudaFieldKeys.map((_) => DataCell(_buildValueCell('---', true, true, rowColor))));
      } else {
        productCells.addAll(_nifudaFieldKeys.map((nifudaField) {
          final productField = _displayFieldsMap[nifudaField]; 
          String productValue = '---';
          if (productField != null) {
              if (nifudaField == '品名') {
                  final hinmei = product['品名記号']?.toString() ?? '';
                  final kiji = product['記事']?.toString() ?? '';
                  productValue = hinmei.isNotEmpty ? hinmei : kiji;
              } 
              else if (nifudaField == '記事') {
                   productValue = product['記事']?.toString() ?? '';
              }
              else if (nifudaField == '図書番号' || nifudaField == '手配コード') {
                  productValue = product['製品コード番号']?.toString() ?? '';
              }
              else {
                  productValue = product[productField]?.toString() ?? '';
              }
          }
          
          bool isMismatch = mismatchFields.any((field) => field.contains(nifudaField) || (productField != null && field.contains(productField)));
          bool highlight = (nifudaField == '記事') ? false : isMismatch;
          return DataCell(_buildValueCell(productValue, highlight, true, rowColor));
        }));
      }
      dataRows.add(DataRow(cells: productCells, color: MaterialStateProperty.all(rowColor)));
    }
    
    return dataRows;
  }

  Widget _buildValueCell(String text, bool isMismatch, bool isProductRow, Color rowColor) {
    Color textColor = isProductRow ? Colors.teal.shade900 : Colors.indigo.shade900;
    Color highlightColor = Colors.transparent;
    
    if (isMismatch) {
      textColor = Colors.red.shade900;
      highlightColor = Colors.red.shade100.withOpacity(0.5);
    } else if (text.isEmpty || text == '---') {
      textColor = Colors.grey.shade600;
    }

    return Container(
      decoration: BoxDecoration(
         color: isMismatch ? highlightColor : rowColor,
         border: Border(
           left: BorderSide(color: Colors.grey.shade300, width: 0.5),
           right: BorderSide(color: Colors.grey.shade300, width: 0.5),
         )
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.centerLeft,
      child: Text(
        text.isEmpty ? '---' : text, 
        style: TextStyle(
          fontSize: 12, 
          color: textColor,
          fontWeight: isMismatch ? FontWeight.bold : FontWeight.normal,
        )
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectProvider);
    final notifier = ref.read(projectProvider.notifier);

    final headers = _excelHeaders;
    final data = _excelData;

    final List<DataColumn> columns = _buildColumns();
    final List<DataRow> rows = _buildDataRows();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('照合結果がありません。'))
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: columns,
                          rows: rows,
                          horizontalMargin: 8,
                          columnSpacing: 0,
                          dataRowMinHeight: 32,
                          dataRowMaxHeight: 32,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade400, width: 1.0),
                              bottom: BorderSide(color: Colors.grey.shade400, width: 1.0),
                            ),
                          ),
                          dataRowColor: MaterialStateProperty.resolveWith<Color?>((states) => Colors.transparent),
                          dataTextStyle: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700, 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.skip_next),
                    label: Text('次のCase (${'#${(int.tryParse(currentCaseNumber.replaceAll('#', '')) ?? 1) + 1}'})へ', style: const TextStyle(fontSize: 16)),
                    onPressed: () async {
                       await _updateMatchedProducts(context, ref);
                       _moveToNextCase(context, ref);
                    },
                  ),
                  const SizedBox(height: 10),

                  isSmallScreen
                  ? Column(
                      children: [
                        _buildSaveButton(
                          context, ref, notifier, projectState, 
                          '共有フォルダ(SMB)\nへ保存', Icons.cloud_upload_outlined, Colors.green.shade700, 
                          true 
                        ),
                        const SizedBox(height: 10),
                        _buildSaveButton(
                          context, ref, notifier, projectState, 
                          'アプリ(LINE/Gmail)\nで共有', Icons.share, Colors.indigo.shade700, 
                          false 
                        ),
                      ],
                    )
                  : Row( 
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildSaveButton(
                            context, ref, notifier, projectState, 
                            '共有フォルダ(SMB)\nへ保存', Icons.cloud_upload_outlined, Colors.green.shade700, 
                            true
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSaveButton(
                            context, ref, notifier, projectState, 
                            'アプリ(LINE/Gmail)\nで共有', Icons.share, Colors.indigo.shade700, 
                            false
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context, WidgetRef ref, ProjectNotifier notifier, ProjectState projectState,
    String label, IconData icon, Color bgColor, bool isSMB
  ) {
    // ★ ユーザー名を取得
    final userName = ref.read(userProvider).currentUser?.username;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white, 
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 50),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, textAlign: TextAlign.center), 
      onPressed: () async {
        await _updateMatchedProducts(context, ref);
        
        final String? newStatus;
        if (isSMB) {
          newStatus = await exportDataToStorageAction(
              context: context,
              projectTitle: projectTitle,
              projectFolderPath: projectFolderPath,
              nifudaData: nifudaData,
              productListData: productListKariData,
              matchingResults: matchingResults,
              currentCaseNumber: currentCaseNumber,
              jsonSavePath: projectState.jsonSavePath,
              inspectionStatus: STATUS_COMPLETED,
              processedBy: userName, // ★ 追加
          );
        } else {
          newStatus = await shareDataViaAppsAction(
              context: context,
              projectTitle: projectTitle,
              projectFolderPath: projectFolderPath,
              nifudaData: nifudaData,
              productListData: productListKariData,
              matchingResults: matchingResults,
              currentCaseNumber: currentCaseNumber,
              jsonSavePath: projectState.jsonSavePath,
              inspectionStatus: STATUS_COMPLETED,
              processedBy: userName, // ★ 追加
          );
        }

        if (newStatus == STATUS_COMPLETED) {
           if (projectState.currentProjectId != null) {
              await notifier.updateProjectStatus(STATUS_COMPLETED);
           } else {
              notifier.updateProjectStatus(STATUS_COMPLETED);
           }
           if(context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
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

extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}