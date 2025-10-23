// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'home_actions.dart';
import '../widgets/home_widgets.dart';
import '../widgets/custom_snackbar.dart';
import 'dart:io'; 
import 'package:path/path.dart' as p; 
// ★★★ 削除：フォルダ選択パッケージのインポートを削除 ★★★
// import 'package:file_picker/file_picker.dart';

import 'camera_capture_page.dart';
import 'nifuda_ocr_confirm_page.dart';
import 'home_actions_gemini.dart'; 

// ★★★ 定数定義: 進捗ステータス ★★★
const String STATUS_PENDING = '検品前';
const String STATUS_IN_PROGRESS = '検品中';
const String STATUS_COMPLETED = '検品完了';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _projectTitle = '(新規プロジェクト)';
  String _selectedCompany = 'T社';
  final List<String> _companies = ['T社', 'マスク処理なし', '動的マスク処理'];

  String _selectedMatchingPattern = 'T社（製番・項目番号）';
  final List<String> _matchingPatterns = ['T社（製番・項目番号）', '汎用（図書番号優先）'];

  List<List<String>> _nifudaData = [
    ['製番', '項目番号', '品名', '形式', '個数', '図書番号', '摘要', '手配コード'],
  ];
  List<List<String>> _productListKariData = [
    ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考'],
  ];
  bool _isLoading = false;
  String? _currentProjectFolderPath;
  // String _productListPath = '/storage/emulated/0/DCIM/製品リスト原紙'; // ★★★ 削除 ★★★
  
  // ★★★ 追加: 進捗ステータス管理 ★★★
  String _inspectionStatus = STATUS_PENDING;
  
  @override
  void initState() {
    super.initState();
    // 初期状態のステータスを設定
    _updateStatus();
  }
  
  void _updateStatus([String? status]) {
    setState(() {
      if (status != null) {
        _inspectionStatus = status;
      } else if (_currentProjectFolderPath == null) {
        _inspectionStatus = STATUS_PENDING;
      } else if (_nifudaData.length > 1 || _productListKariData.length > 1) {
        // データが存在する場合は、完了していない限り「検品中」
        if (_inspectionStatus != STATUS_COMPLETED) {
           _inspectionStatus = STATUS_IN_PROGRESS;
        }
      } else {
        // プロジェクトフォルダがあるがデータがない場合
        _inspectionStatus = STATUS_IN_PROGRESS;
      }
    });
  }


  void _setLoading(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

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
      _setLoading(true);
      try {
        const String baseDcimPath = "/storage/emulated/0/DCIM";
        final String inspectionRelatedPath = p.join(baseDcimPath, "検品関係");
        final String projectFolderPath = p.join(inspectionRelatedPath, projectCode);

        final Directory projectDir = Directory(projectFolderPath);
        if (!await projectDir.exists()) {
          await projectDir.create(recursive: true);
        }

        if (mounted) {
          setState(() {
            _projectTitle = projectCode;
            _currentProjectFolderPath = projectFolderPath;
            _nifudaData = [['製番', '項目番号', '品名', '形式', '個数', '図書番号', '摘要', '手配コード']];
            _productListKariData = [['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考']];
            _inspectionStatus = STATUS_IN_PROGRESS; // ★ ステータスを検品中に設定
          });
          showCustomSnackBar(context, 'プロジェクト「$projectCode」が作成されました。');
        }
      } catch (e) {
        debugPrint('プロジェクトフォルダ作成エラー: $e');
        if (mounted) {
          showCustomSnackBar(context, 'プロジェクトフォルダの作成に失敗しました: $e', isError: true);
        }
      } finally {
        _setLoading(false);
      }
    } else {
      if (mounted) {
        showCustomSnackBar(context, 'プロジェクト作成がキャンセルされました。');
      }
    }
  }
  
  // ★★★ 削除: _handleChangeProductListPath 関数全体を削除 ★★★
  // Future<void> _handleChangeProductListPath() async {
  //   // FilePickerを使用してユーザーにディレクトリを選択させる
  //   String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
  //     dialogTitle: '製品リストのフォルダを選択してください',
  //     initialDirectory: _productListPath,
  //   );

  //   if (selectedDirectory != null) {
  //     // ユーザーがディレクトリを選択した場合
  //     setState(() {
  //       _productListPath = selectedDirectory;
  //     });
  //     if(mounted) showCustomSnackBar(context, '読込先フォルダを変更しました: $selectedDirectory');
  //   } else {
  //     // ユーザーが選択をキャンセルした場合
  //     if(mounted) showCustomSnackBar(context, 'フォルダ選択がキャンセルされました。');
  //   }
  // }

  Future<void> _handleCaptureNifudaWithGpt() async {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
      return;
    }
    _setLoading(true);
    final List<List<String>>? confirmedRows = await captureProcessAndConfirmNifudaAction(context, _currentProjectFolderPath!);
    _setLoading(false);

    if (mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
      setState(() {
        _nifudaData.addAll(confirmedRows);
        _updateStatus(); // ステータスを更新
      });
      showCustomSnackBar(context, '${confirmedRows.length}件の荷札データがGPTで追加されました。');
    }
  }

  Future<void> _handleCaptureNifudaWithGemini() async {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
      return;
    }
    _setLoading(true);
    final List<List<String>>? confirmedRows = await captureProcessAndConfirmNifudaActionWithGemini(context, _currentProjectFolderPath!);
    _setLoading(false);

    if (mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
      setState(() {
        _nifudaData.addAll(confirmedRows);
        _updateStatus(); // ステータスを更新
      });
      showCustomSnackBar(context, '${confirmedRows.length}件の荷札データがGeminiで追加されました。');
    }
  }
  
  void _showLoadingDialog(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _handleShowNifudaList() {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
      return;
    }
    showAndExportNifudaListAction(context, _nifudaData, _projectTitle, _currentProjectFolderPath!);
  }

  // ★★★ 変更: 製品リストをカメラで撮影してOCR (GPT版) ★★★
  Future<void> _handlePickProductListWithGpt() async {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
      return;
    }
    _setLoading(true);
    // productListPathを削除した新しい関数を呼び出す
    final List<List<String>>? confirmedRows = await captureProcessAndConfirmProductListAction(context, _selectedCompany, _setLoading, _currentProjectFolderPath!);
    if (mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
      setState(() {
        if(_productListKariData.length == 1 && _productListKariData.first[0] != 'ORDER No.') {
           _productListKariData = [
              ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考'],
           ];
        }
        _productListKariData.addAll(confirmedRows);
        _updateStatus(); // ステータスを更新
      });
      showCustomSnackBar(context, '${confirmedRows.length}件の製品リストデータが追加されました。');
    }
    if (mounted && _isLoading) {
      _setLoading(false);
    }
  }

  // ★★★ 変更: 製品リストをカメラで撮影してOCR (Gemini版) ★★★
  Future<void> _handlePickProductListWithGemini() async {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
      return;
    }
    _setLoading(true);
    // productListPathを削除した新しい関数を呼び出す
    final List<List<String>>? confirmedRows = await captureProcessAndConfirmProductListActionWithGemini(context, _selectedCompany, _setLoading, _currentProjectFolderPath!);
    if (mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
      setState(() {
        if(_productListKariData.length == 1 && _productListKariData.first[0] != 'ORDER No.') {
          _productListKariData = [
              ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考'],
          ];
        }
        _productListKariData.addAll(confirmedRows);
        _updateStatus(); // ステータスを更新
      });
      showCustomSnackBar(context, '${confirmedRows.length}件の製品リストデータが追加されました。');
    }
    if (mounted && _isLoading) {
      _setLoading(false);
    }
  }

  void _handleShowProductList() {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
      return;
    }
    showAndExportProductListAction(context, _productListKariData, _currentProjectFolderPath!);
  }

  // ★★★ 変更点: startMatchingAndShowResultsActionをawaitで呼び出し、戻り値のステータスを処理する ★★★
  Future<void> _handleStartMatching() async {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
      return;
    }
    
    // home_actions.dart の startMatchingAndShowResultsAction を await で呼び出し
    final String? newStatus = await startMatchingAndShowResultsAction(
      context, 
      _nifudaData, 
      _productListKariData, 
      _selectedMatchingPattern,
      _projectTitle, // projectTitleを追加
      _currentProjectFolderPath!,
    );
    
    if (mounted && newStatus == STATUS_COMPLETED) { // STATUS_COMPLETED を使用
      setState(() {
        _inspectionStatus = STATUS_COMPLETED;
      });
      showCustomSnackBar(context, 'プロジェクト「$_projectTitle」の検品を完了しました！', durationSeconds: 5);
    }
  }
  
  Future<void> _handleSaveProject() async {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, '保存するプロジェクトがありません。', isError: true);
      return;
    }
    // saveProjectActionはJSONパスを返すように変更したが、ここでは戻り値は無視
    await saveProjectAction(
      context,
      _currentProjectFolderPath!,
      _projectTitle,
      _nifudaData,
      _productListKariData,
    );
  }

  Future<void> _handleLoadProject() async {
    if (_isLoading) return;
    final loadedData = await loadProjectAction(context);
    if (loadedData != null && mounted) {
      setState(() {
        _projectTitle = loadedData['projectTitle'] as String;
        _currentProjectFolderPath = loadedData['currentProjectFolderPath'] as String;
        _nifudaData = loadedData['nifudaData'] as List<List<String>>;
        _productListKariData = loadedData['productListKariData'] as List<List<String>>;
        // 読み込み完了後、未完了であれば「検品中」
        _inspectionStatus = STATUS_IN_PROGRESS; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ボタンカラムの幅を計算し、画面全体を効率的に使う
    final screenWidth = MediaQuery.of(context).size.width;
    // 右側の撮影の仕方ボタンとステータスチップの領域を考慮して、ボタンカラムの最大幅を画面幅から引く
    final statusChipWidth = 120.0; // チップの概算幅
    final infoButtonWidth = 150.0; // 撮影の仕方ボタンの幅
    final maxContentWidth = screenWidth - 32.0; // 左右Paddingを除いた幅

    // 新規作成ボタンの幅は、画面左側にある他のアクションボタンと揃える
    final actionColumnWidth = (maxContentWidth * 0.5).clamp(280.0, 450.0);

    return Scaffold(
      appBar: AppBar(title: Text('シンコー府中輸出課 荷札照合アプリ - $_projectTitle')),
      // ★★★ 修正箇所: 画面右下にFABを配置し、_isLoadingがtrueの場合は無効化する ★★★
      floatingActionButton: FloatingActionButton.extended(
        // ★ 修正点: _isLoadingがtrueの場合は onPressed を null にして無効化する
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
              child: SingleChildScrollView( // ★★★ 全体をスクロール可能にする
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ★★★ 修正箇所 1: Row内に新規作成ボタンとステータスチップを配置 ★★★
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start, 
                      crossAxisAlignment: CrossAxisAlignment.center, // 垂直方向中央揃え
                      children: [
                        // 新規作成ボタンの幅を固定
                        SizedBox(
                          width: actionColumnWidth,
                          child: _buildActionButton(label: '新規作成', onPressed: _handleNewProject, icon: Icons.create_new_folder),
                        ),
                        
                        const SizedBox(width: 16), // 間隔
                        const Spacer(), 
                        // ステータスチップを右端に配置
                        _buildStatusChip(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // ★★★ 修正箇所 2: ボタンカラムの幅を actionColumnWidth に統一 ★★★
                    SizedBox(
                      width: actionColumnWidth,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: '保存',
                              onPressed: _handleSaveProject,
                              icon: Icons.save,
                              isEnabled: _currentProjectFolderPath != null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionButton(
                              label: '読み込み',
                              onPressed: _handleLoadProject,
                              icon: Icons.folder_open,
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
                          _buildActionButton(label: '荷札を撮影して抽出 (GPT)', onPressed: _handleCaptureNifudaWithGpt, icon: Icons.camera_alt_outlined, isEnabled: _currentProjectFolderPath != null),
                          const SizedBox(height: 10),
                          _buildActionButton(label: '荷札を撮影して抽出 (Gemini)', onPressed: _handleCaptureNifudaWithGemini, icon: Icons.camera, isEnabled: _currentProjectFolderPath != null, isEmphasized: true),
                          const SizedBox(height: 10),
                          _buildActionButton(label: '荷札リスト (${_nifudaData.length > 1 ? _nifudaData.length - 1 : 0}件)', onPressed: _handleShowNifudaList, icon: Icons.list_alt_rounded, isEnabled: _nifudaData.length > 1 && _currentProjectFolderPath != null),
                          const SizedBox(height: 10),
                          _buildCompanySelector(),
                          const SizedBox(height: 10),
                          // ★★★ 削除: 読込先フォルダ変更ボタンを削除 ★★★
                          // _buildActionButton(label: '読込先フォルダ変更', onPressed: _handleChangeProductListPath, icon: Icons.settings_applications),
                          // const SizedBox(height: 10),
                          // ★★★ 変更: ボタンのテキストを「製品リストを撮影して抽出」に変更 ★★★
                          _buildActionButton(label: '製品リストを撮影して抽出 (GPT)', onPressed: _handlePickProductListWithGpt, icon: Icons.image_search_rounded, isEnabled: _currentProjectFolderPath != null),
                          const SizedBox(height: 10),
                          _buildActionButton(label: '製品リストを撮影して抽出 (Gemini)', onPressed: _handlePickProductListWithGemini, icon: Icons.flash_on, isEnabled: _currentProjectFolderPath != null, isEmphasized: true),
                          const SizedBox(height: 10),
                          _buildActionButton(label: '製品リスト (${_productListKariData.length > 1 ? _productListKariData.length - 1 : 0}件)', onPressed: _handleShowProductList, icon: Icons.inventory_2_outlined, isEnabled: _productListKariData.length > 1 && _currentProjectFolderPath != null),
                          const SizedBox(height: 20),
                          _buildMatchingPatternSelector(),
                          const SizedBox(height: 10),
                          _buildActionButton(label: '照合を開始する', onPressed: _handleStartMatching, icon: Icons.compare_arrows_rounded, isEnabled: _nifudaData.length > 1 && _productListKariData.length > 1 && _currentProjectFolderPath != null, isEmphasized: true),
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
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('処理中です...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                )
              ),
          ],
        ),
      ),
    );
  }

  // ★★★ 追加: ステータス表示用のChipウィジェット ★★★
  Widget _buildStatusChip() {
    Color color;
    IconData icon;
    switch (_inspectionStatus) {
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
        _inspectionStatus,
        style: TextStyle(
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
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
      onPressed: (_isLoading) ? null : (isEnabled ? onPressed : null),
      style: style.copyWith(
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 48)),
      ),
    );
  }
  
  Widget _buildCompanySelector() {
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
          value: _selectedCompany,
          items: _companies.map((String company) {
            return DropdownMenuItem<String>(
              value: company, 
              child: Text(
                'マスク処理: $company',
                style: TextStyle(color: Colors.indigo[800], fontWeight: FontWeight.w600, fontSize: 14.5),
                overflow: TextOverflow.ellipsis,
              )
            );
          }).toList(),
          onChanged: _isLoading ? null : (String? newValue) => setState(() => _selectedCompany = newValue ?? _selectedCompany),
          icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.indigo[700]),
          isDense: true,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildMatchingPatternSelector() {
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
          value: _selectedMatchingPattern,
          items: _matchingPatterns.map((String pattern) {
            return DropdownMenuItem<String>(
              value: pattern,
              child: Text(
                '照合パターン: $pattern',
                style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w600, fontSize: 14.5),
                overflow: TextOverflow.ellipsis,
              )
            );
          }).toList(),
          onChanged: _isLoading ? null : (String? newValue) => setState(() => _selectedMatchingPattern = newValue ?? _selectedMatchingPattern),
          icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.green[700]),
          isDense: true,
          isExpanded: true,
        ),
      ),
    );
  }
}