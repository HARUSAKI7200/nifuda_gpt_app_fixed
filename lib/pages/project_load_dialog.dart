// lib/pages/project_load_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class ProjectLoadDialog extends StatefulWidget {
  final String baseFolder;

  const ProjectLoadDialog({super.key, required this.baseFolder});

  @override
  State<ProjectLoadDialog> createState() => _ProjectLoadDialogState();
  
  static Future<Map<String, String>?> show(BuildContext context, String baseFolder) async {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectLoadDialog(baseFolder: baseFolder),
    );
  }
}

class _ProjectLoadDialogState extends State<ProjectLoadDialog> {
  late Future<List<ProjectEntry>> _projectFilesFuture;
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _projectFilesFuture = _scanProjectFiles();
  }

  Future<List<ProjectEntry>> _scanProjectFiles() async {
    final baseDir = Directory(widget.baseFolder);
    if (!await baseDir.exists()) {
      return [];
    }

    final List<ProjectEntry> entries = [];
    // 'SAVES'フォルダ内のみを再帰的に検索
    final List<FileSystemEntity> entities = baseDir.listSync(recursive: true).where((e) => e.path.contains('SAVES') && e.path.endsWith('.json')).toList();

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        final fileName = p.basename(entity.path);
        // ファイル名の形式: [製番]_[yyyyMMdd]_[HHmmss].json
        final parts = fileName.split('_');
        
        if (parts.length == 3) {
          try {
            final projectCode = parts[0];
            final datePart = parts[1];
            final timePart = parts[2].split('.').first;
            
            final dateTime = DateTime.parse(
              '${datePart.substring(0, 4)}-${datePart.substring(4, 6)}-${datePart.substring(6, 8)} '
              '${timePart.substring(0, 2)}:${timePart.substring(2, 4)}:${timePart.substring(4, 6)}',
            );

            entries.add(ProjectEntry(
              projectCode: projectCode,
              saveTime: dateTime,
              filePath: entity.path,
              // プロジェクトフォルダは /DCIM/検品関係/[製番]
              projectFolderPath: p.dirname(p.dirname(entity.path)), 
            ));
          } catch (e) {
            FlutterLogs.logThis(tag: 'PROJECT_LOAD', subTag: 'FILE_PARSE_ERROR', logMessage: 'Failed to parse file name: $fileName, Error: $e', level: LogLevel.WARNING);
          }
        }
      }
    }

    // 最新のものから順にソート
    entries.sort((a, b) => b.saveTime.compareTo(a.saveTime));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('プロジェクトを読み込む'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: FutureBuilder<List<ProjectEntry>>(
          future: _projectFilesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('保存されたプロジェクトファイルが見つかりませんでした。'));
            } else {
              final entries = snapshot.data!;
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    child: ListTile(
                      title: Text(entry.projectCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('保存日時: ${_dateFormat.format(entry.saveTime)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // 選択された情報を返す
                        Navigator.of(context).pop({
                          'projectTitle': entry.projectCode,
                          'filePath': entry.filePath,
                          'projectFolderPath': entry.projectFolderPath,
                        });
                      },
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}

class ProjectEntry {
  final String projectCode;
  final DateTime saveTime;
  final String filePath;
  final String projectFolderPath;

  ProjectEntry({
    required this.projectCode,
    required this.saveTime,
    required this.filePath,
    required this.projectFolderPath,
  });
}