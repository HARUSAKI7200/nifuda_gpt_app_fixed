// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_logs/flutter_logs.dart';
import '../state/project_state.dart';
// ★ 修正: home_actions.dart 全体をインポート (エラーダイアログ用にも)
import 'home_actions.dart';
//import '../widgets/home_widgets.dart'; // home_widgets.dart が存在しないためコメントアウト
import '../widgets/custom_snackbar.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'home_actions_gemini.dart';
import 'project_load_dialog.dart';
import '../database/app_database.dart';
import 'smb_settings_page.dart';
import 'directory_image_picker_page.dart'; // JSON読み込みに必要
import 'package:drift/drift.dart' show Value;

class HomePage extends ConsumerWidget {
  // ★ 修正: const コンストラクタを削除 (List.generateを許可するため)
  HomePage({super.key});

  // Case No.のドロップダウンリストアイテム
  // ★ 修正: class level final (non-const)
  final List<String> _caseNumbers = List.generate(50, (index) => '#${index + 1}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(databaseProvider);

    return dbAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.indigo))),
      error: (err, stack) => Scaffold(body: Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('データベースエラーが発生しました: $err', style: const TextStyle(color: Colors.red)),
      ))),
      data: (_) {
        final projectState = ref.watch(projectProvider);
        final notifier = ref.read(projectProvider.notifier);
        // ★ 修正: isProjectActive は DB ID がなくても JSON ロード直後は true になるように title も見る
        final isProjectActive = projectState.currentProjectId != null || projectState.projectTitle.isNotEmpty;
        final isLoading = projectState.isLoading;

        // T社と汎用のパターン
        final List<String> matchingPatterns = ['T社（製番・項目番号）', '汎用（図書番号優先）'];

        return Scaffold(
          appBar: AppBar(
            title: const Text('検品アプリ'),
            actions: [
               IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SmbSettingsPage()));
                  },
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. プロジェクト情報エリア
                _buildProjectInfoCard(projectState, isLoading),
                const SizedBox(height: 16),

                // 2. アクションボタンエリア
                _buildActionButtons(context, ref, projectState, notifier, isProjectActive, isLoading),
                const SizedBox(height: 16),

                // 3. 会社・照合パターン選択エリア
                Row(
                  children: [
                    Expanded(child: _buildCompanySelector(projectState, notifier, ['T社', 'マスク処理なし', '動的マスク処理'], isLoading)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMatchingPatternSelector(projectState, notifier, matchingPatterns, isLoading)),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. OCR・照合実行ボタンエリア
                _buildOCRAndMatchingButtons(context, ref, projectState, isProjectActive, isLoading),
                const SizedBox(height: 16),

                // 5. データプレビューエリア
                _buildDataPreview(context, ref, projectState, isProjectActive),

                const Spacer(),

                // 6. DBから読み込みボタン (ProjectLoadDialog)
                // ★ 修正: ボタンを_buildActionButtons内に移動したため削除
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ProjectState state,
    ProjectNotifier notifier,
    bool isProjectActive,
    bool isLoading,
  ) {
    return Column(
      children: [
        // Case No.選択ドロップダウン
        Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.orange.shade200)
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.currentCaseNumber,
              items: _caseNumbers.map((String caseNo) {
                return DropdownMenuItem<String>(
                  value: caseNo,
                  child: Text(
                    'Case No.: $caseNo',
                    style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w600, fontSize: 14.5),
                  )
                );
              }).toList(),
              onChanged: isLoading || !isProjectActive ? null : (String? newValue) => notifier.updateCaseNumber(newValue ?? '#1'),
              icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.orange[700]),
              isDense: true,
              isExpanded: true,
            ),
          ),
        ),

        // 新規作成 / DBから読み込み / JSON保存
        Row(
          children: [
            // 新規作成ボタン
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.add),
                label: const Text('新規作成', style: TextStyle(fontSize: 16)),
                onPressed: isLoading ? null : () => _showCreateProjectDialog(context, notifier),
              ),
            ),
            const SizedBox(width: 8),

            // ★ 修正: DBから読み込むボタン (JSON読込ボタンを置き換え)
            Expanded(
              child: ElevatedButton.icon(
                 style: ElevatedButton.styleFrom(
                   // DBロードボタンのスタイルを使用
                   backgroundColor: Colors.lightGreen.shade600,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 12),
                 ),
                 icon: const Icon(Icons.storage),
                 label: const Text('DBから読込', style: TextStyle(fontSize: 16)), // ラベルを短縮
                 onPressed: isLoading ? null : () async {
                   final selectedProject = await ProjectLoadDialog.show(context);
                   if (selectedProject != null) {
                     await notifier.loadProject(selectedProject);
                     // DBからロードした場合、JSONパスはリセットされる
                     notifier.updateJsonSavePath(null);
                   }
                 },
              ),
            ),
            const SizedBox(width: 8),

            // JSON保存ボタン
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isProjectActive ? Colors.green.shade600 : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.archive),
                label: Text(state.jsonSavePath == null ? 'JSON保存(新規)' : 'JSON保存(上書)', style: const TextStyle(fontSize: 14)),
                onPressed: isLoading || !isProjectActive ? null : () async {
                  if (state.projectFolderPath == null) {
                    _showErrorDialog(context, '保存エラー', 'プロジェクトが作成または読み込まれていません。');
                    return;
                  }
                  await saveProjectAction(
                      context,
                      state.projectFolderPath!,
                      state.projectTitle,
                      state.nifudaData,
                      state.productListKariData,
                      state.currentCaseNumber,
                      state.jsonSavePath,
                      notifier.updateJsonSavePath,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildProjectInfoCard(ProjectState state, bool isLoading) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 10, width: 200),
                    SizedBox(height: 8),
                    SizedBox(height: 10, width: 250),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'プロジェクトコード: ${state.projectTitle.isEmpty ? '未選択' : state.projectTitle}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: state.projectTitle.isEmpty ? Colors.grey : Colors.indigo[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(state.inspectionStatus),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          state.inspectionStatus,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('保存先パス: ${state.projectFolderPath ?? '---'}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  // JSON保存パスの表示を追加
                  if (state.jsonSavePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('JSON保存パス: ${p.basename(p.dirname(p.dirname(state.jsonSavePath!)))}/...', style: const TextStyle(fontSize: 13, color: Colors.green)),
                      ),
                  // Case No.の表示を追加
                  if (state.projectTitle.isNotEmpty) // プロジェクトが有効な場合
                     Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('現在のCase No.: ${state.currentCaseNumber}', style: const TextStyle(fontSize: 13, color: Colors.orange)),
                      ),
                ],
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case STATUS_COMPLETED: return Colors.green.shade600;
      case STATUS_IN_PROGRESS: return Colors.orange.shade600;
      case STATUS_PENDING:
      default: return Colors.grey.shade400;
    }
  }

  Widget _buildCompanySelector(ProjectState state, ProjectNotifier notifier, List<String> companies, bool isLoading) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.indigo.shade200)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedCompany,
          items: companies.map((String company) {
            return DropdownMenuItem<String>(
              value: company,
              child: Text(
                '会社: $company',
                style: TextStyle(color: Colors.indigo[800], fontWeight: FontWeight.w600, fontSize: 14.5),
                overflow: TextOverflow.ellipsis,
              )
            );
          }).toList(),
          onChanged: isLoading ? null : (String? newValue) => notifier.updateSelection(company: newValue),
          icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.indigo[700]),
          isDense: true,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildMatchingPatternSelector(ProjectState state, ProjectNotifier notifier, List<String> patterns, bool isLoading) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.green.shade200)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedMatchingPattern,
          items: patterns.map((String pattern) {
            return DropdownMenuItem<String>(
              value: pattern,
              child: Text(
                '照合パターン: $pattern',
                style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w600, fontSize: 14.5),
                overflow: TextOverflow.ellipsis,
              )
            );
          }).toList(),
          onChanged: isLoading ? null : (String? newValue) => notifier.updateSelection(matchingPattern: newValue),
          icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.green[700]),
          isDense: true,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildOCRAndMatchingButtons(BuildContext context, WidgetRef ref, ProjectState state, bool isProjectActive, bool isLoading) {
     final notifier = ref.read(projectProvider.notifier);
     // Case No.によるフィルタリングはUI上では行わず、データが存在するかで判断
     final hasNifudaData = state.nifudaData.length > 1;
     final hasProductData = state.productListKariData.length > 1;

     return Column(
       children: [
         // 荷札・製品リスト OCR
         Row(
           children: [
             Expanded(
               child: ElevatedButton.icon(
                 style: ElevatedButton.styleFrom(
                    backgroundColor: isProjectActive ? Colors.deepOrange.shade600 : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)
                 ),
                 icon: const Icon(Icons.camera_alt),
                 label: Text('荷札撮影 (${state.currentCaseNumber})', style: const TextStyle(fontSize: 16)),
                 onPressed: isProjectActive && !isLoading ? () async {
                   if (state.projectFolderPath == null) {
                       _showErrorDialog(context, 'エラー', 'プロジェクトが選択されていません。');
                       return;
                   }
                   final newRows = await captureProcessAndConfirmNifudaAction(
                      context,
                      state.projectFolderPath!,
                      state.currentCaseNumber, // ★ Case No.を渡す
                   );
                   if (newRows != null && newRows.isNotEmpty) {
                     if (state.currentProjectId != null) {
                         await notifier.addNifudaRows(newRows);
                     } else {
                         // Stateのみ更新 (一時的なデータとして)
                         final currentCaseNumber = state.currentCaseNumber;
                         final newRowsWithCase = newRows.map((row) => [...row, currentCaseNumber]).toList();
                         // ★ 修正: public getter を使用
                         final currentData = state.nifudaData.isEmpty ? [notifier.nifudaHeader] : state.nifudaData;
                         final updatedList = List<List<String>>.from(currentData)..addAll(newRowsWithCase);
                         notifier.state = state.copyWith(nifudaData: updatedList, inspectionStatus: STATUS_IN_PROGRESS);
                         showCustomSnackBar(context, '荷札データを一時的に追加しました (DB未保存)');
                     }
                   }
                 } : null,
               ),
             ),
             const SizedBox(width: 8),
             Expanded(
               child: ElevatedButton.icon(
                 style: ElevatedButton.styleFrom(
                    backgroundColor: isProjectActive ? Colors.pink.shade600 : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)
                 ),
                 icon: const Icon(Icons.scanner),
                 label: const Text('製品リストスキャン', style: const TextStyle(fontSize: 16)),
                 onPressed: isProjectActive && !isLoading ? () async {
                   if (state.projectFolderPath == null) {
                       _showErrorDialog(context, 'エラー', 'プロジェクトが選択されていません。');
                       return;
                   }
                   final newRows = await captureProcessAndConfirmProductListAction(
                      context,
                      state.selectedCompany,
                      notifier.setLoading,
                      state.projectFolderPath!,
                   );
                   if (newRows != null && newRows.isNotEmpty) {
                     if (state.currentProjectId != null) {
                         await notifier.addProductListRows(newRows);
                     } else {
                         // Stateのみ更新 (一時的なデータとして)
                         final newRowsWithMatchedCase = newRows.map((row) => [...row, '']).toList(); // 照合済みCase列追加
                         // ★ 修正: public getter を使用
                         final currentData = state.productListKariData.isEmpty ? [notifier.productListHeader] : state.productListKariData;
                         final updatedList = List<List<String>>.from(currentData)..addAll(newRowsWithMatchedCase);
                         notifier.state = state.copyWith(productListKariData: updatedList, inspectionStatus: STATUS_IN_PROGRESS);
                         showCustomSnackBar(context, '製品リストデータを一時的に追加しました (DB未保存)');
                     }
                   }
                 } : null,
               ),
             ),
           ],
         ),
         const SizedBox(height: 8),

         // 照合実行ボタン
         ElevatedButton.icon(
           style: ElevatedButton.styleFrom(
              backgroundColor: hasNifudaData && hasProductData ? Colors.purple.shade600 : Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 50),
           ),
           icon: const Icon(Icons.rule),
           label: Text('照合実行 (${state.currentCaseNumber})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
           onPressed: hasNifudaData && hasProductData && !isLoading ? () async {
             if (state.projectFolderPath == null) {
                 _showErrorDialog(context, 'エラー', 'プロジェクトが選択されていません。');
                 return;
             }
             final newStatus = await startMatchingAndShowResultsAction(
               context,
               state.nifudaData,
               state.productListKariData,
               state.selectedMatchingPattern,
               state.projectTitle,
               state.projectFolderPath!,
               state.currentCaseNumber, // ★ Case No.を渡す
             );
             if (newStatus != null) {
               // updateProjectStatus が DB ID なしでも State を更新するように修正済み
               await notifier.updateProjectStatus(newStatus);
             }
           } : null,
         ),
       ],
     );
  }

  Widget _buildDataPreview(BuildContext context, WidgetRef ref, ProjectState state, bool isProjectActive) {
     final hasNifudaData = state.nifudaData.length > 1;
     final hasProductData = state.productListKariData.length > 1;
     final notifier = ref.read(projectProvider.notifier);

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Text('データプレビュー', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
         const SizedBox(height: 8),
         Row(
           children: [
             // 荷札リスト表示
             Expanded(
               child: ElevatedButton.icon(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: hasNifudaData ? Colors.blue.shade600 : Colors.grey.shade400,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 12)
                 ),
                 icon: const Icon(Icons.list),
                 label: Text('荷札リスト(${state.currentCaseNumber})', style: const TextStyle(fontSize: 14)),
                 onPressed: hasNifudaData && isProjectActive ? () => showAndExportNifudaListAction(
                   context,
                   state.nifudaData,
                   state.projectTitle,
                   state.projectFolderPath!,
                   state.currentCaseNumber, // ★ Case No.を渡す
                 ) : null,
               ),
             ),
             const SizedBox(width: 8),
             // 製品リスト表示
             Expanded(
               child: ElevatedButton.icon(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: hasProductData ? Colors.teal.shade600 : Colors.grey.shade400,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 12)
                 ),
                 icon: const Icon(Icons.list_alt),
                 label: const Text('製品リスト(全体)', style: const TextStyle(fontSize: 14)),
                 onPressed: hasProductData && isProjectActive ? () => showAndExportProductListAction(
                   context,
                   state.productListKariData,
                   state.projectFolderPath!,
                 ) : null,
               ),
             ),
           ],
         ),
         const SizedBox(height: 8),
         // データサマリー
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceAround,
           children: [
              Text('荷札データ(全体): ${state.nifudaData.length - (state.nifudaData.isNotEmpty ? 1: 0)}件', style: TextStyle(color: hasNifudaData ? Colors.blue.shade800 : Colors.grey)), // ヘッダー分を引く
              Text('製品リスト: ${state.productListKariData.length - (state.productListKariData.isNotEmpty ? 1: 0)}件', style: TextStyle(color: hasProductData ? Colors.teal.shade800 : Colors.grey)), // ヘッダー分を引く
           ],
         )
       ],
     );
  }


  void _showCreateProjectDialog(BuildContext context, ProjectNotifier notifier) {
    final projectCodeController = TextEditingController();
    // ★ 修正: ベースパスのみを初期値とする
    final projectFolderPathController = TextEditingController(text: BASE_PROJECT_DIR);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新規プロジェクト作成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: projectCodeController,
                decoration: const InputDecoration(labelText: '依頼No (プロジェクトコード)'),
              ),
              TextField(
                controller: projectFolderPathController,
                readOnly: true, // ベースパスは固定
                decoration: const InputDecoration(labelText: '保存ベースフォルダ'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                final projectCode = projectCodeController.text.trim();
                if (projectCode.isEmpty) {
                  showCustomSnackBar(context, '依頼Noを入力してください。', isError: true);
                  return;
                }
                Navigator.of(context).pop();

                try {
                  // ★ 修正: プロジェクトフォルダパスはベースパス + プロジェクトコードにする
                  final projectSpecificPath = p.join(BASE_PROJECT_DIR, projectCode);
                  await notifier.createProject(
                    projectCode: projectCode,
                    projectFolderPath: projectSpecificPath, // ★ 修正
                  );
                  showCustomSnackBar(context, 'プロジェクト「$projectCode」を作成しました。');
                } catch (e) {
                   // ★ 修正: _showErrorDialog を呼び出す (HomePage内に定義)
                   _showErrorDialog(context, '作成エラー', 'プロジェクトの作成に失敗しました: $e');
                }
              },
              child: const Text('作成'),
            ),
          ],
        );
      },
    );
  }

  // ★ 追加: _showErrorDialog (home_actions.dartから移動または共有)
  // HomePage内にプライベートメソッドとして定義
  void _showErrorDialog(BuildContext context, String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(message)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}