// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:shimmer/shimmer.dart'; 
import 'package:flutter_logs/flutter_logs.dart'; 
import '../state/project_state.dart'; 
// ★ 修正: home_actions.dart 全体をインポート
import 'home_actions.dart';
//import '../widgets/home_widgets.dart';
import '../widgets/custom_snackbar.dart';
import 'dart:io'; 
import 'package:path/path.dart' as p; 
import 'home_actions_gemini.dart';
import 'project_load_dialog.dart';
import '../database/app_database.dart'; 
import 'smb_settings_page.dart'; // ★★★ 追加: SMB設定画面のインポート

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { 
    // ★ 修正: dbAsync は AsyncValue<AppDatabase>
    final dbAsync = ref.watch(databaseProvider);

    // ★ 修正: AsyncValue の .when を使ってUIを分岐
    return dbAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.indigo))),
      error: (err, stack) => Scaffold(body: Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("データベースの初期化に失敗しました: $err", textAlign: TextAlign.center),
      ))),
      data: (dbInstance) {
        // ★ DB初期化OKなら、Notifierを監視
        // (projectProvider は dbAsync.requireValue を内部で使うので、ここでは安全)
        final projectState = ref.watch(projectProvider);
        final projectNotifier = ref.read(projectProvider.notifier);

        // ★ 修正: 変数を projectState から直接読む
        final String _projectTitle = projectState.projectTitle;
        final List<List<String>> _nifudaData = projectState.nifudaData;
        final List<List<String>> _productListKariData = projectState.productListKariData;
        final bool _isLoading = projectState.isLoading;
        final String? _currentProjectFolderPath = projectState.projectFolderPath;
        final String _inspectionStatus = projectState.inspectionStatus;

        final List<String> _companies = ['T社', 'マスク処理なし', '動的マスク処理'];
        final List<String> _matchingPatterns = ['T社（製番・項目番号）', '汎用（図書番号優先）'];

        // --- アクションのラッパー関数 (修正あり) ---
        
        // ★★★ この関数 (_handleNewProject) を修正 ★★★
        Future<void> _handleNewProject() async {
          if (_isLoading) return;
          
          final String? projectCode = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              String? inputCode;
              return AlertDialog(
                title: const Text('新規フォルダ作成'),
                content: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '依頼Noを入力してください',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    inputCode = value.trim();
                  },
                  onSubmitted: (value) {
                    Navigator.of(dialogContext).pop(inputCode);
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(inputCode),
                    child: const Text('作成'),
                  ),
                ],
              );
            },
          );

          if (projectCode != null && projectCode.isNotEmpty) {
            try {
              // ★★★ ここから変更 ★★★

              // 1. 現在の日付を取得 (例: 20231027)
              final now = DateTime.now();
              final formattedDate = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";

              // 2. ベースパスを定義
              const String baseDcimPath = "/storage/emulated/0/DCIM";
              final String inspectionRelatedPath = p.join(baseDcimPath, "検品関係");
              
              // 3. 日付フォルダパスを生成 (例: /storage/emulated/0/DCIM/検品関係/20231027)
              final String dateFolderPath = p.join(inspectionRelatedPath, formattedDate);

              // 4. 最終的なプロジェクトパスを生成 (例: /storage/emulated/0/DCIM/検品関係/20231027/QZ83941)
              final String projectFolderPath = p.join(dateFolderPath, projectCode);

              // ★★★ ここまで変更 ★★★

              final Directory projectDir = Directory(projectFolderPath);
              if (!await projectDir.exists()) {
                await projectDir.create(recursive: true);
              }
              
              await projectNotifier.createProject(
                projectCode: projectCode,
                projectFolderPath: projectFolderPath, // 変更後のパスを渡す
              );

              if (context.mounted) {
                showCustomSnackBar(context, 'プロジェクト「$projectCode」が作成されました。');
              }
            } catch (e) {
              FlutterLogs.logError('PROJECT_ACTION', 'CREATE_ERROR', 'Project creation failed: $e');
              if (context.mounted) {
                showCustomSnackBar(context, 'プロジェクトの作成に失敗しました: $e', isError: true);
              }
            }
          } else {
            if (context.mounted) {
              showCustomSnackBar(context, 'プロジェクト作成がキャンセルされました。');
            }
          }
        }

        // (変更なし)
        Future<void> _handleCaptureNifudaWithGpt() async {
          if (_isLoading || _currentProjectFolderPath == null) {
            if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'まず「新規作成」か「読み込み」でプロジェクトを開いてください。', isError: true);
            return;
          }
          
          final List<List<String>>? confirmedRows = await captureProcessAndConfirmNifudaAction(context, _currentProjectFolderPath);

          if (context.mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
            await projectNotifier.addNifudaRows(confirmedRows);
            if (context.mounted) {
              showCustomSnackBar(context, '${confirmedRows.length}件の荷札データがDBに追加されました。');
            }
          }
        }
        
        // (変更なし)
        Future<void> _handleCaptureNifudaWithGemini() async {
          if (_isLoading || _currentProjectFolderPath == null) {
             if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'まず「新規作成」か「読み込み」でプロジェクトを開いてください。', isError: true);
             return;
          }

          final List<List<String>>? confirmedRows = await captureProcessAndConfirmNifudaActionWithGemini(context, _currentProjectFolderPath);

          if (context.mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
            await projectNotifier.addNifudaRows(confirmedRows);
            if (context.mounted) {
              showCustomSnackBar(context, '${confirmedRows.length}件の荷札データがGeminiでDBに追加されました。');
            }
          }
        }
        
        // (変更なし)
        void _handleShowNifudaList() {
          if (_isLoading || _currentProjectFolderPath == null) {
            if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'プロジェクトを開いてください。', isError: true);
            return;
          }
          showAndExportNifudaListAction(context, _nifudaData, _projectTitle, _currentProjectFolderPath);
        }
        
        // ★ 修正: _selectedCompany -> projectState.selectedCompany
        Future<void> _handlePickProductListWithGpt() async {
          if (_isLoading || _currentProjectFolderPath == null) {
            if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'プロジェクトを開いてください。', isError: true);
            return;
          }
          
          final List<List<String>>? confirmedRows = await captureProcessAndConfirmProductListAction(context, projectState.selectedCompany, (_) {}, _currentProjectFolderPath);
          
          if (context.mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
            await projectNotifier.addProductListRows(confirmedRows);
            if (context.mounted) {
               showCustomSnackBar(context, '${confirmedRows.length}件の製品リストデータがGPTでDBに追加されました。');
            }
          }
          if (context.mounted && _isLoading) {
            projectNotifier.setLoading(false);
          }
        }
        
        // ★ 修正: _selectedCompany -> projectState.selectedCompany
        Future<void> _handlePickProductListWithGemini() async {
          if (_isLoading || _currentProjectFolderPath == null) {
            if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'プロジェクトを開いてください。', isError: true);
            return;
          }

          final List<List<String>>? confirmedRows = await captureProcessAndConfirmProductListActionWithGemini(context, projectState.selectedCompany, (_) {}, _currentProjectFolderPath);
          
          if (context.mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
            await projectNotifier.addProductListRows(confirmedRows);
            if (context.mounted) {
              showCustomSnackBar(context, '${confirmedRows.length}件の製品リストデータがGeminiでDBに追加されました。');
            }
          }
          if (context.mounted && _isLoading) {
            projectNotifier.setLoading(false);
          }
        }
        
        // (変更なし)
        void _handleShowProductList() {
          if (_isLoading || _currentProjectFolderPath == null) {
            if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'プロジェクトを開いてください。', isError: true);
            return;
          }
          showAndExportProductListAction(context, _productListKariData, _currentProjectFolderPath);
        }
        
        // ★ 修正: _selectedMatchingPattern -> projectState.selectedMatchingPattern
        Future<void> _handleStartMatching() async {
          if (_isLoading || _currentProjectFolderPath == null) {
            if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'プロジェクトを開いてください。', isError: true);
            return;
          }
          
          final String? newStatus = await startMatchingAndShowResultsAction(
            context, 
            _nifudaData, 
            _productListKariData, 
            projectState.selectedMatchingPattern, // ★ 修正
            _projectTitle,
            _currentProjectFolderPath,
          );
          
          if (context.mounted && newStatus == STATUS_COMPLETED) {
            await projectNotifier.updateProjectStatus(STATUS_COMPLETED);
            if (context.mounted) {
              showCustomSnackBar(context, 'プロジェクト「$_projectTitle」の検品を完了しました！', durationSeconds: 5);
            }
          }
        }
        
        // (変更なし)
        Future<void> _handleSaveProject() async {
          if (_isLoading || _currentProjectFolderPath == null) {
            if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'エクスポートするプロジェクトがありません。', isError: true);
            return;
          }
          projectNotifier.setLoading(true);
          await saveProjectAction(
            context,
            _currentProjectFolderPath,
            _projectTitle,
            _nifudaData,
            _productListKariData,
          );
          projectNotifier.setLoading(false);
          if (context.mounted) {
            showCustomSnackBar(context, '現在の状態をJSONファイルにエクスポートしました。');
          }
        }
        
        // (変更なし)
        Future<void> _handleLoadProject() async {
          if (_isLoading) return;
          
          final Project? selectedProject = await ProjectLoadDialog.show(context);
          
          if (selectedProject != null && context.mounted) {
            await projectNotifier.loadProject(selectedProject);
            if (context.mounted) {
               showCustomSnackBar(context, 'プロジェクト「${selectedProject.projectTitle}」をDBから読み込みました。');
            }
          } else if (context.mounted) {
            showCustomSnackBar(context, 'プロジェクトの読み込みがキャンセルされました。');
          }
        }


        // --- UI構築 (変更なし) ---
        final screenWidth = MediaQuery.of(context).size.width;
        final actionColumnWidth = (screenWidth - 32.0 * 2).clamp(280.0, 450.0);

        return Scaffold(
          appBar: AppBar(
            title: Text('シンコー府中輸出課 荷札照合アプリ - $_projectTitle'),
            // ★★★ ここから修正 ★★★
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_ethernet_rounded),
                tooltip: '共有フォルダ設定',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SmbSettingsPage()),
                  );
                },
              ),
            ],
            // ★★★ ここまで修正 ★★★
          ),
          //floatingActionButton: FloatingActionButton.extended(
            //onPressed: _isLoading ? null : () => showPhotoGuide(context),
            //icon: const Icon(Icons.info_outline),
            //label: const Text('撮影の仕方'),
            //backgroundColor: Colors.indigo[600],
            //foregroundColor: Colors.white,
          //),
          body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start, 
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: actionColumnWidth,
                              child: _buildActionButton(label: '新規作成', onPressed: _handleNewProject, icon: Icons.create_new_folder, isLoading: _isLoading),
                            ),
                            
                            const SizedBox(width: 16),
                            const Spacer(), 
                            _buildStatusChip(_inspectionStatus),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        SizedBox(
                          width: actionColumnWidth,
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  label: 'JSONへ保存 (バックアップ)', 
                                  onPressed: _handleSaveProject,
                                  icon: Icons.save_alt, 
                                  isEnabled: _currentProjectFolderPath != null,
                                  isLoading: _isLoading,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'DBから読み込み', 
                                  onPressed: _handleLoadProject,
                                  icon: Icons.folder_open,
                                  isLoading: _isLoading,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: actionColumnWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _buildActionButton(label: '荷札を撮影して抽出 (GPT)', onPressed: _handleCaptureNifudaWithGpt, icon: Icons.camera_alt_outlined, isEnabled: _currentProjectFolderPath != null, isLoading: _isLoading),
                              const SizedBox(height: 10),
                              _buildActionButton(label: '荷札を撮影して抽出 (Gemini)', onPressed: _handleCaptureNifudaWithGemini, icon: Icons.camera, isEnabled: _currentProjectFolderPath != null, isEmphasized: true, isLoading: _isLoading),
                              const SizedBox(height: 10),
                              _buildActionButton(label: '荷札リスト (${_nifudaData.length > 1 ? _nifudaData.length - 1 : 0}件)', onPressed: _handleShowNifudaList, icon: Icons.list_alt_rounded, isEnabled: _nifudaData.length > 1 && _currentProjectFolderPath != null, isLoading: _isLoading),
                              const SizedBox(height: 10),
                              _buildCompanySelector(projectState, projectNotifier, _companies, _isLoading),
                              const SizedBox(height: 10),
                              _buildActionButton(label: '製品リストを撮影して抽出 (GPT)', onPressed: _handlePickProductListWithGpt, icon: Icons.image_search_rounded, isEnabled: _currentProjectFolderPath != null, isLoading: _isLoading),
                              const SizedBox(height: 10),
                              _buildActionButton(label: '製品リストを撮影して抽出 (Gemini)', onPressed: _handlePickProductListWithGemini, icon: Icons.flash_on, isEnabled: _currentProjectFolderPath != null, isEmphasized: true, isLoading: _isLoading),
                              const SizedBox(height: 10),
                              _buildActionButton(label: '製品リスト (${_productListKariData.length > 1 ? _productListKariData.length - 1 : 0}件)', onPressed: _handleShowProductList, icon: Icons.inventory_2_outlined, isEnabled: _productListKariData.length > 1 && _currentProjectFolderPath != null, isLoading: _isLoading),
                              const SizedBox(height: 20),
                              _buildMatchingPatternSelector(projectState, projectNotifier, _matchingPatterns, _isLoading),
                              const SizedBox(height: 10),
                              _buildActionButton(label: '照合を開始する', onPressed: _handleStartMatching, icon: Icons.compare_arrows_rounded, isEnabled: _nifudaData.length > 1 && _productListKariData.length > 1 && _currentProjectFolderPath != null, isEmphasized: true, isLoading: _isLoading),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.7),
                        highlightColor: Colors.white,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flash_on, size: 50, color: Colors.white),
                            SizedBox(height: 16),
                            Text('AIが処理中です...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    )
                  ),
              ],
            ),
          ),
        );
      }, // ★ AsyncValue.when の data: ブロックの終了
    );
  }

  // --- UIヘルパー関数 (変更なし) ---
  
  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case STATUS_COMPLETED:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case STATUS_IN_PROGRESS:
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;
      case STATUS_PENDING:
      default:
        color = Colors.blueGrey;
        icon = Icons.pause_circle_outline;
        break;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      avatar: Icon(icon, color: Colors.white, size: 18),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  Widget _buildActionButton(
    {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isLoading, 
    bool isEnabled = true,
    bool isEmphasized = false,
  }) {
    final ButtonStyle style = isEmphasized
            ? ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700], foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)
              )
            : ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[50], foregroundColor: Colors.indigo[700],
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                textStyle: const TextStyle(fontSize: 14.5)
              );
              
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5), overflow: TextOverflow.ellipsis),
      onPressed: (isLoading) ? null : (isEnabled ? onPressed : null),
      style: style.copyWith(
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 48)),
      ),
    );
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
                'マスク処理: $company',
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
}