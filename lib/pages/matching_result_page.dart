// lib/pages/matching_result_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart'; 
import '../utils/excel_export.dart';
import '../widgets/custom_snackbar.dart';
import 'home_actions.dart'; // saveProjectActionのために必要

class MatchingResultPage extends StatelessWidget {
  final Map<String, dynamic> matchingResults;
  final String projectFolderPath; 
  final String projectTitle; 
  final List<List<String>> nifudaData; 
  final List<List<String>> productListKariData; 

  const MatchingResultPage({
    super.key, 
    required this.matchingResults, 
    required this.projectFolderPath,
    required this.projectTitle, 
    required this.nifudaData, 
    required this.productListKariData, 
  });

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
            onPressed: allRows.isEmpty ? null : () => _saveAsExcel(context, displayHeaders, allRows, false), // false: 共有なし
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: allRows.isEmpty ? null : () => _handleSaveAndShare(context, displayHeaders, allRows),
        icon: const Icon(Icons.share),
        label: const Text('検品完了＆共有'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
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

  // ★ 修正: exportToExcelStorage の戻り値(Map)を処理するように変更
  Future<String?> _saveAsExcel(BuildContext context, List<String> headers, List<Map<String, dynamic>> data, bool silent) async {
    final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '照合結果_$now.xlsx';

    final List<List<String>> dataRows = data.map((resultMap) {
      return headers.map((header) => resultMap[header]?.toString() ?? '').toList();
    }).toList();

    try {
      // ★ 修正: 戻り値を Map で受け取る
      final Map<String, String> exportResult = await exportToExcelStorage( 
        fileName: fileName,
        sheetName: '照合結果',
        headers: headers,
        rows: dataRows,
        projectFolderPath: projectFolderPath, // 渡されたパスを使用
        subfolder: '抽出結果', // サブフォルダ名を指定
      );
      
      final String localMsg = exportResult['local'] ?? 'ローカル保存エラー';
      final String smbMsg = exportResult['smb'] ?? 'SMB処理エラー';
      
      // share_plusのためにフルパスが必要なので、p.joinを使ってフルパスを再構成する
      final String fullPath = p.join(projectFolderPath, '抽出結果', fileName);
      
      if (context.mounted && !silent) {
        // ★ 修正: silent=false の場合のみ、両方の結果をスナックバーで表示
        showCustomSnackBar(
          context, 
          'ローカル: $localMsg\n共有フォルダ: $smbMsg',
          durationSeconds: 7, // メッセージが長いので長めに表示
        );
      }
      return fullPath; // ★ 修正なし: 共有機能のためフルパスを返す
    } catch (e) {
      if (context.mounted && !silent) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('保存エラー'),
                  content: Text('Excelファイルの保存に失敗しました: $e'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ));
      }
      return null;
    }
  }
  
  // ★ 修正なし: _saveAsExcel が fullPath を返し続けるため変更不要
  Future<void> _handleSaveAndShare(BuildContext context, List<String> headers, List<Map<String, dynamic>> data) async {
    if (!context.mounted) return;
    
    // 1. Loading表示
    showCustomSnackBar(context, '検品完了データを保存中...', showAtTop: true);

    // 2. プロジェクトデータ (JSON) の保存
    final String? jsonFilePath = await saveProjectAction(
      context,
      projectFolderPath,
      projectTitle,
      nifudaData,
      productListKariData,
    );
    
    // 3. 照合結果 Excel の保存 (サイレント)
    final String? excelFilePath = await _saveAsExcel(context, headers, data, true);

    final List<XFile> filesToShare = [];
    String message = '依頼No「$projectTitle」の検品が完了しました。\n\n';

    if (jsonFilePath != null) {
      filesToShare.add(XFile(jsonFilePath));
      message += '・プロジェクトデータ (JSON) を添付しました。\n';
    } else {
      message += '・プロジェクトデータ (JSON) の保存に失敗しました。\n';
    }

    if (excelFilePath != null) {
      filesToShare.add(XFile(excelFilePath));
      message += '・照合結果 (Excel) を添付しました。';
    } else {
      message += '・照合結果 (Excel) の保存に失敗しました。\n';
    }

    if (!context.mounted) return;
    showCustomSnackBar(context, '共有メニューを開きます...', showAtTop: true);
    
    // 4. ファイル共有の実行
    if (filesToShare.isNotEmpty) {
       await Share.shareXFiles(
          filesToShare,
          text: message,
          subject: '【検品完了】$projectTitle',
       );
    } else {
       await Share.share(message, subject: '【検品完了】$projectTitle');
    }
    
    if (context.mounted) {
       // 画面暗転回避のため、手動で戻ることを推奨するSnackbarを出す
       showCustomSnackBar(context, '共有が完了しました。左上の矢印でホーム画面に戻ってください。', durationSeconds: 5, showAtTop: true);
    }
  }
}