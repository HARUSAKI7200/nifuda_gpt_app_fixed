// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'home_actions.dart';
import '../widgets/home_widgets.dart';
import '../widgets/custom_snackbar.dart';
import 'dart:io'; 
import 'package:path/path.dart' as p; 
import 'camera_capture_page.dart';
import 'nifuda_ocr_confirm_page.dart';

import 'home_actions_gemini.dart'; 

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

  // ★★★ 変更点：GPTで荷札を撮影する処理 ★★★
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
      });
      showCustomSnackBar(context, '${confirmedRows.length}件の荷札データがGPTで追加されました。');
    }
  }

  // ★★★ 追加：Geminiで荷札を撮影する処理 ★★★
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

  Future<void> _handlePickProductListWithGpt() async {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
      return;
    }
    _setLoading(true);
    final List<List<String>>? confirmedRows = await pickProcessAndConfirmProductListAction(context, _selectedCompany, _setLoading, _currentProjectFolderPath!);
    if (mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
      setState(() {
        if(_productListKariData.length == 1 && _productListKariData.first[0] != 'ORDER No.') {
           _productListKariData = [
              ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考'],
           ];
        }
        _productListKariData.addAll(confirmedRows);
      });
      showCustomSnackBar(context, '${confirmedRows.length}件の製品リストデータが追加されました。');
    }
    if (mounted && _isLoading) {
      _setLoading(false);
    }
  }

  Future<void> _handlePickProductListWithGemini() async {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
      return;
    }
    _setLoading(true);
    final List<List<String>>? confirmedRows = await pickProcessAndConfirmProductListActionWithGemini(context, _selectedCompany, _setLoading, _currentProjectFolderPath!);
    if (mounted && confirmedRows != null && confirmedRows.isNotEmpty) {
      setState(() {
        if(_productListKariData.length == 1 && _productListKariData.first[0] != 'ORDER No.') {
          _productListKariData = [
              ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考'],
          ];
        }
        _productListKariData.addAll(confirmedRows);
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

  void _handleStartMatching() {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, 'まず「新規作成」でプロジェクトを作成してください。', isError: true);
      return;
    }
    startMatchingAndShowResultsAction(context, _nifudaData, _productListKariData, _selectedMatchingPattern, _currentProjectFolderPath!);
  }
  
  Future<void> _handleSaveProject() async {
    if (_isLoading) return;
    if (_currentProjectFolderPath == null) {
      showCustomSnackBar(context, '保存するプロジェクトがありません。', isError: true);
      return;
    }
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColumnWidth = (MediaQuery.of(context).size.width * 0.5).clamp(280.0, 450.0);

    return Scaffold(
      appBar: AppBar(title: Text('シンコー府中輸出課 荷札照合アプリ - $_projectTitle')),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: buttonColumnWidth,
                        child: _buildActionButton(label: '新規作成', onPressed: _handleNewProject, icon: Icons.create_new_folder),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: buttonColumnWidth,
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
                    width: buttonColumnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // ★★★ 変更点：荷札撮影ボタンを２つに分割 ★★★
                        _buildActionButton(label: '荷札を撮影して抽出 (GPT)', onPressed: _handleCaptureNifudaWithGpt, icon: Icons.camera_alt_outlined, isEnabled: _currentProjectFolderPath != null),
                        const SizedBox(height: 10),
                        _buildActionButton(label: '荷札を撮影して抽出 (Gemini)', onPressed: _handleCaptureNifudaWithGemini, icon: Icons.camera, isEnabled: _currentProjectFolderPath != null, isEmphasized: true),
                        const SizedBox(height: 10),
                        _buildActionButton(label: '荷札リスト (${_nifudaData.length > 1 ? _nifudaData.length - 1 : 0}件)', onPressed: _handleShowNifudaList, icon: Icons.list_alt_rounded, isEnabled: _nifudaData.length > 1 && _currentProjectFolderPath != null),
                        const SizedBox(height: 10),
                        _buildCompanySelector(),
                        const SizedBox(height: 10),
                        _buildActionButton(label: '製品リスト画像をOCRする (GPT)', onPressed: _handlePickProductListWithGpt, icon: Icons.image_search_rounded, isEnabled: _currentProjectFolderPath != null),
                        const SizedBox(height: 10),
                        _buildActionButton(label: '製品リスト画像をOCRする (Gemini)', onPressed: _handlePickProductListWithGemini, icon: Icons.flash_on, isEnabled: _currentProjectFolderPath != null, isEmphasized: true),
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
            Positioned(
              top: 16.0,
              right: 16.0,
              child: _buildActionButton(
                label: '撮影の仕方',
                onPressed: () => showPhotoGuide(context),
                icon: Icons.info_outline,
                isInfoButton: true,
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isEnabled = true,
    bool isEmphasized = false,
    bool isInfoButton = false,
  }) {
    // ボタンのスタイル定義（強調表示、情報ボタン、通常ボタン）
    final ButtonStyle style = isInfoButton
        ? ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey[600], foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            fixedSize: const Size(150, 48),
          )
        : isEmphasized
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
      label: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5)),
      onPressed: (_isLoading && onPressed != _handleNewProject && !isInfoButton) ? null : (isEnabled ? onPressed : null),
      style: style.copyWith(
        minimumSize: MaterialStateProperty.all(isInfoButton ? const Size(150, 48) : const Size(double.infinity, 48)),
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