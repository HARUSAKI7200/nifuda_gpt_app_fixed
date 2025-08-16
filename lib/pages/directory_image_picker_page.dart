// lib/pages/directory_image_picker_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../widgets/custom_snackbar.dart';

// ★ 修正：2段階選択に対応した新しい画像選択画面
class DirectoryImagePickerPage extends StatefulWidget {
  final String rootDirectoryPath;

  const DirectoryImagePickerPage({super.key, required this.rootDirectoryPath});

  @override
  State<DirectoryImagePickerPage> createState() => _DirectoryImagePickerPageState();
}

class _DirectoryImagePickerPageState extends State<DirectoryImagePickerPage> {
  List<Directory> _dateDirs = [];
  List<Directory> _seibanDirs = [];
  List<File> _imageFiles = [];

  Directory? _selectedDateDir;
  Directory? _selectedSeibanDir;

  final Set<String> _selectedImagePaths = {};
  bool _isLoading = true;
  String _currentTitle = "日付を選択";

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
  }

  Future<void> _requestPermissionAndLoad() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) status = await Permission.storage.request();
    
    if (Platform.isAndroid) {
      var externalStatus = await Permission.manageExternalStorage.status;
      if (!externalStatus.isGranted) externalStatus = await Permission.manageExternalStorage.request();
      if (!externalStatus.isGranted) {
        if (mounted) {
          showCustomSnackBar(context, 'ストレージへのアクセス権限がありません。', isError: true);
          Navigator.pop(context);
        }
        return;
      }
    }
    _loadDateDirs();
  }

  void _loadDateDirs() {
    setState(() {
      _isLoading = true;
      _currentTitle = "日付を選択";
      _selectedDateDir = null;
      _selectedSeibanDir = null;
    });
    final rootDir = Directory(widget.rootDirectoryPath);
    if (rootDir.existsSync()) {
      final dirs = rootDir.listSync().whereType<Directory>().toList();
      dirs.sort((a, b) => b.path.compareTo(a.path)); // 日付で降順ソート
      setState(() {
        _dateDirs = dirs;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        showCustomSnackBar(context, 'ルートフォルダが見つかりません', isError: true);
        Navigator.pop(context);
      }
    }
  }

  void _loadSeibanDirs(Directory dateDir) {
    setState(() {
      _isLoading = true;
      _selectedDateDir = dateDir;
      _currentTitle = "${p.basename(dateDir.path)} > 製番を選択";
    });
    final dirs = dateDir.listSync().whereType<Directory>().toList();
    dirs.sort((a, b) => a.path.compareTo(b.path)); // 製番で昇順ソート
    setState(() {
      _seibanDirs = dirs;
      _isLoading = false;
    });
  }

  void _loadImages(Directory seibanDir) {
    setState(() {
      _isLoading = true;
      _selectedSeibanDir = seibanDir;
      _currentTitle = "${p.basename(_selectedDateDir!.path)} > ${p.basename(seibanDir.path)}";
    });
    final files = seibanDir.listSync().whereType<File>().where((file) {
      final ext = p.extension(file.path).toLowerCase();
      return ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp';
    }).toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    setState(() {
      _imageFiles = files;
      _isLoading = false;
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedImagePaths.contains(path)) {
        _selectedImagePaths.remove(path);
      } else {
        _selectedImagePaths.add(path);
      }
    });
  }
  
  void _onConfirm() {
    Navigator.pop(context, _selectedImagePaths.toList());
  }

  Future<bool> _onWillPop() async {
    if (_selectedSeibanDir != null) {
      _loadSeibanDirs(_selectedDateDir!);
      _selectedSeibanDir = null; // 状態をリセット
      _imageFiles = []; // 画像リストをクリア
      return false;
    }
    if (_selectedDateDir != null) {
      _loadDateDirs();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$_currentTitle (${_selectedImagePaths.length}件選択中)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: '確定',
              onPressed: _selectedImagePaths.isEmpty ? null : _onConfirm,
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildCurrentView(),
        floatingActionButton: _selectedImagePaths.isEmpty
          ? null 
          : FloatingActionButton.extended(
              onPressed: _onConfirm,
              label: Text('確定 (${_selectedImagePaths.length}件)'),
              icon: const Icon(Icons.check),
            ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_selectedSeibanDir != null) {
      return _buildImageGrid();
    }
    if (_selectedDateDir != null) {
      return _buildDirectoryList(_seibanDirs, (dir) => _loadImages(dir));
    }
    return _buildDirectoryList(_dateDirs, (dir) => _loadSeibanDirs(dir));
  }

  Widget _buildDirectoryList(List<Directory> dirs, void Function(Directory) onTap) {
    if (dirs.isEmpty) return const Center(child: Text("このフォルダにサブフォルダはありません。"));
    return ListView.builder(
      itemCount: dirs.length,
      itemBuilder: (context, index) {
        final dir = dirs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: const Icon(Icons.folder, size: 40, color: Colors.orange),
            title: Text(p.basename(dir.path)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onTap(dir),
          ),
        );
      },
    );
  }

  Widget _buildImageGrid() {
    if (_imageFiles.isEmpty) return const Center(child: Text("このフォルダに画像ファイルはありません。"));
    return GridView.builder(
      padding: const EdgeInsets.all(4.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: _imageFiles.length,
      itemBuilder: (context, index) {
        final file = _imageFiles[index];
        final isSelected = _selectedImagePaths.contains(file.path);
        return GestureDetector(
          onTap: () => _toggleSelection(file.path),
          child: GridTile(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(file, fit: BoxFit.cover),
                if (isSelected)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}