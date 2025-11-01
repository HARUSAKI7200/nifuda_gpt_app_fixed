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
        // マスク処理の選択肢
        final List<String> maskOptions = ['T社', 'マスク処理なし', '動的マスク処理'];


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
            // ★ 修正: UI全体を2カラムレイアウト (Row) に変更
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 左カラム (操作ボタン) ---
                Expanded(
                  flex: 2, // 左カラムを少し狭く
                  child: SingleChildScrollView(
                    child: _buildLeftColumn(context, ref, projectState, notifier, isProjectActive, isLoading, maskOptions, matchingPatterns),
                  ),
                ),
                
                const SizedBox(width: 16),

                // --- 右カラム (プロジェクト情報) ---
                Expanded(
                  flex: 3, // 右カラムを少し広く
                  child: Column(
                    children: [
                      _buildProjectInfoCard(projectState, isLoading),
                      const SizedBox(height: 16),
                      _buildCaseSelector(projectState, notifier, isProjectActive, isLoading),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ★ 新規: 左カラムのUIを構築するメソッド
  Widget _buildLeftColumn(
    BuildContext context, 
    WidgetRef ref, 
    ProjectState state, 
    ProjectNotifier notifier, 
    bool isProjectActive, 
    bool isLoading,
    List<String> maskOptions,
    List<String> matchingPatterns,
  ) {
    // データ件数
    final nifudaDataCount = state.nifudaData.length - (state.nifudaData.isNotEmpty ? 1 : 0);
    final productDataCount = state.productListKariData.length - (state.productListKariData.isNotEmpty ? 1 : 0);
    final hasNifudaData = nifudaDataCount > 0;
    final hasProductData = productDataCount > 0;

    return Column(
      children: [
        // 1. 新規作成
        _buildActionButton(
          text: '新規作成',
          icon: Icons.add,
          color: Colors.indigo.shade700,
          onPressed: isLoading ? null : () => _showCreateProjectDialog(context, notifier),
        ),
        
        // 2. 保存 / 読み込み
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                text: state.jsonSavePath == null ? '保存(新規)' : '保存(上書)',
                icon: Icons.archive,
                color: Colors.green.shade600,
                isEnabled: isProjectActive && !isLoading,
                onPressed: () async {
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
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                text: 'DB読込',
                icon: Icons.storage,
                color: Colors.lightGreen.shade600,
                isEnabled: !isLoading,
                onPressed: () async {
                   final selectedProject = await ProjectLoadDialog.show(context);
                   if (selectedProject != null) {
                     await notifier.loadProject(selectedProject);
                     notifier.updateJsonSavePath(null);
                   }
                },
              ),
            ),
          ],
        ),
        
        const Divider(height: 24, thickness: 1),

        // 3. 荷札 (GPT)
        _buildActionButton(
          text: '荷札を撮影して抽出 (GPT)',
          icon: Icons.camera_alt,
          color: Colors.deepOrange.shade600,
          isEnabled: isProjectActive && !isLoading,
          onPressed: () async {
             if (state.projectFolderPath == null) {
                 _showErrorDialog(context, 'エラー', 'プロジェクトが選択されていません。');
                 return;
             }
             final newRows = await captureProcessAndConfirmNifudaAction(
                context,
                state.projectFolderPath!,
                state.currentCaseNumber,
             );
             if (newRows != null && newRows.isNotEmpty) {
                 // DB未保存（JSONのみ）の場合もStateは更新される
                 await notifier.addNifudaRows(newRows);
             }
          },
        ),
        
        // 4. 荷札 (Gemini)
        _buildActionButton(
          text: '荷札を撮影して抽出 (Gemini)',
          icon: Icons.camera_alt_outlined, // 別のアイコン
          color: Colors.orange.shade700,
          isEnabled: isProjectActive && !isLoading,
          onPressed: () async {
             if (state.projectFolderPath == null) {
                 _showErrorDialog(context, 'エラー', 'プロジェクトが選択されていません。');
                 return;
             }
             // ★ 新しい Gemini アクションを呼び出す
             final newRows = await captureProcessAndConfirmNifudaActionGemini(
                context,
                state.projectFolderPath!,
                state.currentCaseNumber,
             );
             if (newRows != null && newRows.isNotEmpty) {
                 await notifier.addNifudaRows(newRows);
             }
          },
        ),
        
        // 5. 荷札リスト
        _buildActionButton(
          text: '荷札リスト (全体: $nifudaDataCount 件)',
          icon: Icons.list,
          color: Colors.blue.shade600,
          isEnabled: hasNifudaData && isProjectActive && !isLoading,
          onPressed: () => showAndExportNifudaListAction(
             context,
             state.nifudaData,
             state.projectTitle,
             state.projectFolderPath!,
             state.currentCaseNumber, // (ダイアログ側で Case No. フィルタリング)
          ),
        ),

        const Divider(height: 24, thickness: 1),

        // 6. マスク処理 (ドロップダウン)
        _buildDropdownSelector(
          value: state.selectedCompany,
          items: maskOptions,
          prefix: 'マスク処理:',
          onChanged: isLoading ? null : (String? newValue) => notifier.updateSelection(company: newValue),
          color: Colors.indigo,
        ),

        // 7. 製品リスト (GPT)
        _buildActionButton(
          text: '製品リストを撮影して抽出 (GPT)',
          icon: Icons.scanner,
          color: Colors.pink.shade600,
          isEnabled: isProjectActive && !isLoading,
          onPressed: () async {
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
                 await notifier.addProductListRows(newRows);
             }
          },
        ),
        
        // 8. 製品リスト (Gemini)
        _buildActionButton(
          text: '製品リストを撮影して抽出 (Gemini)',
          icon: Icons.scanner_outlined, // 別のアイコン
          color: Colors.red.shade700,
          isEnabled: isProjectActive && !isLoading,
          onPressed: () async {
             if (state.projectFolderPath == null) {
                 _showErrorDialog(context, 'エラー', 'プロジェクトが選択されていません。');
                 return;
             }
             final newRows = await captureProcessAndConfirmProductListActionGemini(
                context,
                state.selectedCompany,
                notifier.setLoading,
                state.projectFolderPath!,
             );
             if (newRows != null && newRows.isNotEmpty) {
                 await notifier.addProductListRows(newRows);
             }
          },
        ),

        // 9. 製品リスト
        _buildActionButton(
          text: '製品リスト ($productDataCount 件)',
          icon: Icons.list_alt,
          color: Colors.teal.shade600,
          isEnabled: hasProductData && isProjectActive && !isLoading,
          onPressed: () => showAndExportProductListAction(
             context,
             state.productListKariData,
             state.projectFolderPath!,
          ),
        ),
        
        const Divider(height: 24, thickness: 1),

        // 10. 照合パターン (ドロップダウン)
        _buildDropdownSelector(
          value: state.selectedMatchingPattern,
          items: matchingPatterns,
          prefix: '照合パターン:',
          onChanged: isLoading ? null : (String? newValue) => notifier.updateSelection(matchingPattern: newValue),
          color: Colors.green,
        ),
        
        // 11. 照合を開始する
        _buildActionButton(
          text: '照合を開始する (${state.currentCaseNumber})',
          icon: Icons.rule,
          color: Colors.purple.shade600,
          isEnabled: hasNifudaData && hasProductData && isProjectActive && !isLoading,
          isLarge: true,
          onPressed: () async {
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
               state.currentCaseNumber,
             );
             if (newStatus != null) {
               await notifier.updateProjectStatus(newStatus);
             }
          },
        ),
      ],
    );
  }

  // ★ 新規: 汎用的なアクションボタン
  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool isEnabled = true,
    bool isLarge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: (isEnabled && onPressed != null) ? color : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isLarge ? 16 : 12),
          minimumSize: const Size(double.infinity, 50),
          alignment: Alignment.centerLeft,
        ),
        icon: Icon(icon, size: isLarge ? 24 : 20),
        label: Text(
          text, 
          style: TextStyle(fontSize: isLarge ? 18 : 14, fontWeight: isLarge ? FontWeight.bold : FontWeight.normal),
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: (isEnabled && onPressed != null) ? onPressed : null,
      ),
    );
  }

  // ★ 新規: 汎用的なドロップダウン
  Widget _buildDropdownSelector({
    required String value,
    required List<String> items,
    required String prefix,
    required Function(String?)? onChanged,
    required MaterialColor color,
  }) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.shade200)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                '$prefix $item',
                style: TextStyle(color: color[800], fontWeight: FontWeight.w600, fontSize: 14.5),
                overflow: TextOverflow.ellipsis,
              )
            );
          }).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.arrow_drop_down_rounded, color: color[700]),
          isDense: true,
          isExpanded: true,
        ),
      ),
    );
  }

  // ★ 修正: 右カラムに移動
  Widget _buildCaseSelector(ProjectState state, ProjectNotifier notifier, bool isProjectActive, bool isLoading) {
    return Container(
      height: 48,
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
                '現在選択中の Case No.: $caseNo',
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
                      Flexible( // ★ タイトルが長い場合に備える
                        child: Text(
                          'プロジェクトコード: ${state.projectTitle.isEmpty ? '未選択' : state.projectTitle}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: state.projectTitle.isEmpty ? Colors.grey : Colors.indigo[800],
                          ),
                          overflow: TextOverflow.ellipsis,
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
                  // ★ Case No.の表示は右カラムの別ウィジェットに移動
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

  // ★ 修正: 特殊な空白文字(U+00A0)を除去し、floatingLabelBehaviorを追加
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
              // ★ 修正: 2つのTextField間にスペースを追加
              const SizedBox(height: 16), 
              TextField(
                controller: projectFolderPathController,
                readOnly: true, // ベースパスは固定
                decoration: const InputDecoration(
                  labelText: '保存ベースフォルダ',
                  // ★ 修正: ラベルが常に浮くように設定
                  floatingLabelBehavior: FloatingLabelBehavior.always, 
                ),
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

