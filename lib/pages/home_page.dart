// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ★ 追加
import 'package:shimmer/shimmer.dart'; // ★ 追加: Shimmer
import 'package:flutter_logs/flutter_logs.dart'; // ★ 追加
import '../state/project_state.dart'; // ★ 追加: 状態管理
// ★ 修正: 定数名の衝突を避けるため、ステータス定数をhide
import 'home_actions.dart' hide STATUS_PENDING, STATUS_IN_PROGRESS, STATUS_COMPLETED, BASE_PROJECT_DIR;
import '../widgets/home_widgets.dart';
import '../widgets/custom_snackbar.dart';
import 'dart:io'; 
import 'package:path/path.dart' as p; 
import 'home_actions_gemini.dart'; 

// ★★★ StatefulWidget から ConsumerWidget に変更 ★★★
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // WidgetRefを追加
    final projectState = ref.watch(projectProvider);
    final projectNotifier = ref.read(projectProvider.notifier); // <- ProjectNotifier

    final String _projectTitle = projectState.projectTitle;
    final String _selectedCompany = projectState.selectedCompany;
    final String _selectedMatchingPattern = projectState.selectedMatchingPattern;
    final List<List<String>> _nifudaData = projectState.nifudaData;
    final List<List<String>> _productListKariData = projectState.productListKariData;
    final bool _isLoading = projectState.isLoading;
    final String? _currentProjectFolderPath = projectState.projectFolderPath;
    final String _inspectionStatus = projectState.inspectionStatus;

    final List<String> _companies = ['T社', 'マスク処理なし', '動的マスク処理'];
    final List<String> _matchingPatterns = ['T社（製番・項目番号）', '汎用（図書番号優先）'];

    // --- アクションのラッパー関数 ---
    
    // プロジェクト作成
    Future<void> _handleNewProject() async {
      if (_isLoading) return;
      
      final String? projectCode = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          String? inputCode;
          return AlertDialog(
            title: const Text('新規プロジェクト作成'),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '製番を入力してください (例: QZ83941)',
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
        projectNotifier.setLoading(true); // ★ Notifierでローディングを設定
        try {
          const String baseDcimPath = "/storage/emulated/0/DCIM";
          final String inspectionRelatedPath = p.join(baseDcimPath, "検品関係");
          final String projectFolderPath = p.join(inspectionRelatedPath, projectCode);

          final Directory projectDir = Directory(projectFolderPath);
          if (!await projectDir.exists()) {
            await projectDir.create(recursive: true);
          }
          
          if (context.mounted) {
            // ★ Notifierで状態を一括更新
            projectNotifier.updateProjectData(
              projectTitle: projectCode,
              projectFolderPath: projectFolderPath,
              nifudaData: [['製番', '項目番号', '品名', '形式', '個数', '図書番号', '摘要', '手配コード']],
              productListKariData: [['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考']],
              inspectionStatus: STATUS_IN_PROGRESS, 
            );
            showCustomSnackBar(context, 'プロジェクト「$projectCode」が作成されました。');
            FlutterLogs.logInfo('PROJECT_ACTION', 'CREATE', 'Project $projectCode created at $projectFolderPath');
          }
        } catch (e) {
          FlutterLogs.logError('PROJECT_ACTION', 'CREATE_ERROR', 'Project folder creation failed: $e');
          if (context.mounted) {
            showCustomSnackBar(context, 'プロジェクトフォルダの作成に失敗しました: $e', isError: true);
          }
        } finally {
          projectNotifier.setLoading(false); // ★ Notifierでローディングを解除
        }
      } else {
        if (context.mounted) {
          showCustomSnackBar(context, 'プロジェクト作成がキャンセルされました。');
        }
      }
    }

    Future<void> _handleCaptureNifudaWithGpt() async {
      if (_isLoading || _currentProjectFolderPath == null) {
        if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
        return;
      }
      projectNotifier.setLoading(true);
      // captureProcessAndConfirmNifudaAction のロジックを修正しない限り、この関数内で状態を更新する必要がある
      final List<List<String>>? confirmedRows = await captureProcessAndConfirmNifudaAction(context, _currentProjectFolderPath);
      projectNotifier.setLoading(false);

      if (context.mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
        final newNifudaData = List<List<String>>.from(_nifudaData)..addAll(confirmedRows);
        projectNotifier.updateProjectData(nifudaData: newNifudaData, inspectionStatus: STATUS_IN_PROGRESS);
        showCustomSnackBar(context, '${confirmedRows.length}件の荷札データがGPTで追加されました。');
      }
    }
    
    Future<void> _handleCaptureNifudaWithGemini() async {
      if (_isLoading || _currentProjectFolderPath == null) {
         if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
         return;
      }
      projectNotifier.setLoading(true);
      final List<List<String>>? confirmedRows = await captureProcessAndConfirmNifudaActionWithGemini(context, _currentProjectFolderPath);
      projectNotifier.setLoading(false);

      if (context.mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
        final newNifudaData = List<List<String>>.from(_nifudaData)..addAll(confirmedRows);
        projectNotifier.updateProjectData(nifudaData: newNifudaData, inspectionStatus: STATUS_IN_PROGRESS);
        showCustomSnackBar(context, '${confirmedRows.length}件の荷札データがGeminiで追加されました。');
      }
    }
    
    void _handleShowNifudaList() {
      if (_isLoading || _currentProjectFolderPath == null) {
        if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
        return;
      }
      showAndExportNifudaListAction(context, _nifudaData, _projectTitle, _currentProjectFolderPath);
    }
    
    Future<void> _handlePickProductListWithGpt() async {
      if (_isLoading || _currentProjectFolderPath == null) {
        if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
        return;
      }
      // setLoadingコールバックは home_actions.dart の中で使用されていないため、ダミー関数を渡す
      final List<List<String>>? confirmedRows = await captureProcessAndConfirmProductListAction(context, _selectedCompany, (_) {}, _currentProjectFolderPath);
      
      if (context.mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
        List<List<String>> baseList = _productListKariData;
        if(baseList.length == 1 && baseList.first[0] != 'ORDER No.') {
           baseList = [['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考']];
        }
        final newProductListData = List<List<String>>.from(baseList)..addAll(confirmedRows);

        projectNotifier.updateProjectData(productListKariData: newProductListData, inspectionStatus: STATUS_IN_PROGRESS);
        showCustomSnackBar(context, '${confirmedRows.length}件の製品リストデータがGPTで追加されました。');
      }
      if (context.mounted && _isLoading) {
        projectNotifier.setLoading(false);
      }
    }
    
    Future<void> _handlePickProductListWithGemini() async {
      if (_isLoading || _currentProjectFolderPath == null) {
        if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
        return;
      }
      // setLoadingコールバックは home_actions_gemini.dart の中で使用されていないため、ダミー関数を渡す
      final List<List<String>>? confirmedRows = await captureProcessAndConfirmProductListActionWithGemini(context, _selectedCompany, (_) {}, _currentProjectFolderPath);
      
      if (context.mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
        List<List<String>> baseList = _productListKariData;
        if(baseList.length == 1 && baseList.first[0] != 'ORDER No.') {
          baseList = [['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考']];
        }
        final newProductListData = List<List<String>>.from(baseList)..addAll(confirmedRows);

        projectNotifier.updateProjectData(productListKariData: newProductListData, inspectionStatus: STATUS_IN_PROGRESS);
        showCustomSnackBar(context, '${confirmedRows.length}件の製品リストデータがGeminiで追加されました。');
      }
      if (context.mounted && _isLoading) {
        projectNotifier.setLoading(false);
      }
    }
    
    void _handleShowProductList() {
      if (_isLoading || _currentProjectFolderPath == null) {
        if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
        return;
      }
      showAndExportProductListAction(context, _productListKariData, _currentProjectFolderPath);
    }
    
    Future<void> _handleStartMatching() async {
      if (_isLoading || _currentProjectFolderPath == null) {
        if (_currentProjectFolderPath == null) showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
        return;
      }
      
      final String? newStatus = await startMatchingAndShowResultsAction(
        context, 
        _nifudaData, 
        _productListKariData, 
        _selectedMatchingPattern,
        _projectTitle,
        _currentProjectFolderPath,
      );
      
      if (context.mounted && newStatus == STATUS_COMPLETED) {
        projectNotifier.updateStatus(STATUS_COMPLETED);
        showCustomSnackBar(context, 'プロジェクト「$_projectTitle」の検品を完了しました！', durationSeconds: 5);
      }
    }
    
    Future<void> _handleSaveProject() async {
      if (_isLoading || _currentProjectFolderPath == null) {
        if (_currentProjectFolderPath == null) showCustomSnackBar(context, '保存するプロジェクトがありません。', isError: true);
        return;
      }
      projectNotifier.setLoading(true);
      // saveProjectActionはJSONパスを返すように変更したが、ここでは戻り値は無視
      await saveProjectAction(
        context,
        _currentProjectFolderPath,
        _projectTitle,
        _nifudaData,
        _productListKariData,
      );
      projectNotifier.setLoading(false);
    }
    
    Future<void> _handleLoadProject() async {
      if (_isLoading) return;
      projectNotifier.setLoading(true);
      final loadedData = await loadProjectAction(context);
      if (loadedData != null && context.mounted) {
        projectNotifier.updateProjectData(
          projectTitle: loadedData['projectTitle'] as String,
          projectFolderPath: loadedData['currentProjectFolderPath'] as String,
          nifudaData: loadedData['nifudaData'] as List<List<String>>,
          productListKariData: loadedData['productListKariData'] as List<List<String>>,
          inspectionStatus: STATUS_IN_PROGRESS, 
        );
      }
      projectNotifier.setLoading(false);
    }


    // --- UI構築 ---
    final screenWidth = MediaQuery.of(context).size.width;
    final actionColumnWidth = (screenWidth - 32.0 * 2).clamp(280.0, 450.0);

    return Scaffold(
      appBar: AppBar(title: Text('シンコー府中輸出課 荷札照合アプリ - $_projectTitle')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () => showPhotoGuide(context),
        icon: const Icon(Icons.info_outline),
        label: const Text('撮影の仕方'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
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
                          // ★ 修正: _isLoading -> isLoading: _isLoading
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
                            // ★ 修正: _isLoading -> isLoading: _isLoading
                            child: _buildActionButton(
                              label: '保存',
                              onPressed: _handleSaveProject,
                              icon: Icons.save,
                              isEnabled: _currentProjectFolderPath != null,
                              isLoading: _isLoading,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            // ★ 修正: _isLoading -> isLoading: _isLoading
                            child: _buildActionButton(
                              label: '読み込み',
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
                          // ★ 修正: _isLoading -> isLoading: _isLoading
                          _buildActionButton(label: '荷札を撮影して抽出 (GPT)', onPressed: _handleCaptureNifudaWithGpt, icon: Icons.camera_alt_outlined, isEnabled: _currentProjectFolderPath != null, isLoading: _isLoading),
                          const SizedBox(height: 10),
                          // ★ 修正: _isLoading -> isLoading: _isLoading
                          _buildActionButton(label: '荷札を撮影して抽出 (Gemini)', onPressed: _handleCaptureNifudaWithGemini, icon: Icons.camera, isEnabled: _currentProjectFolderPath != null, isEmphasized: true, isLoading: _isLoading),
                          const SizedBox(height: 10),
                          // ★ 修正: _isLoading -> isLoading: _isLoading
                          _buildActionButton(label: '荷札リスト (${_nifudaData.length > 1 ? _nifudaData.length - 1 : 0}件)', onPressed: _handleShowNifudaList, icon: Icons.list_alt_rounded, isEnabled: _nifudaData.length > 1 && _currentProjectFolderPath != null, isLoading: _isLoading),
                          const SizedBox(height: 10),
                          _buildCompanySelector(projectState, projectNotifier, _companies, _isLoading),
                          const SizedBox(height: 10),
                          // ★ 修正: _isLoading -> isLoading: _isLoading
                          _buildActionButton(label: '製品リストを撮影して抽出 (GPT)', onPressed: _handlePickProductListWithGpt, icon: Icons.image_search_rounded, isEnabled: _currentProjectFolderPath != null, isLoading: _isLoading),
                          const SizedBox(height: 10),
                          // ★ 修正: _isLoading -> isLoading: _isLoading
                          _buildActionButton(label: '製品リストを撮影して抽出 (Gemini)', onPressed: _handlePickProductListWithGemini, icon: Icons.flash_on, isEnabled: _currentProjectFolderPath != null, isEmphasized: true, isLoading: _isLoading),
                          const SizedBox(height: 10),
                          // ★ 修正: _isLoading -> isLoading: _isLoading
                          _buildActionButton(label: '製品リスト (${_productListKariData.length > 1 ? _productListKariData.length - 1 : 0}件)', onPressed: _handleShowProductList, icon: Icons.inventory_2_outlined, isEnabled: _productListKariData.length > 1 && _currentProjectFolderPath != null, isLoading: _isLoading),
                          const SizedBox(height: 20),
                          _buildMatchingPatternSelector(projectState, projectNotifier, _matchingPatterns, _isLoading),
                          const SizedBox(height: 10),
                          // ★ 修正: _isLoading -> isLoading: _isLoading
                          _buildActionButton(label: '照合を開始する', onPressed: _handleStartMatching, icon: Icons.compare_arrows_rounded, isEnabled: _nifudaData.length > 1 && _productListKariData.length > 1 && _currentProjectFolderPath != null, isEmphasized: true, isLoading: _isLoading),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // ★★★ ShimmerによるローディングUIに変更 ★★★
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
  }

  // --- UIヘルパー関数はConsumerWidgetのメソッドとして保持 ---
  
  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      // ★ 修正: project_state.dartから定数を参照
      case STATUS_COMPLETED:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      // ★ 修正: project_state.dartから定数を参照
      case STATUS_IN_PROGRESS:
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;
      // ★ 修正: project_state.dartから定数を参照
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
    required bool isLoading, // ★ 修正: この引数は必須
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
          // ★ 修正ポイント：未定義の matchingPatterns ではなく、引数 patterns を使用
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