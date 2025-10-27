// lib/pages/project_load_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:intl/intl.dart';
import '../database/app_database.dart'; 
import '../state/project_state.dart'; 

class ProjectLoadDialog extends ConsumerWidget {
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm:ss');

  ProjectLoadDialog({super.key});

  static Future<Project?> show(BuildContext context) async {
    return showDialog<Project>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectLoadDialog(), 
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ 修正: DBが準備できていない可能性も考慮
    // (databaseProviderはFutureProviderになったので.whenが使える)
    final dbAsync = ref.watch(databaseProvider);
    
    return AlertDialog(
      title: const Text('プロジェクトを読み込む'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        // ★ 修正: DBがロード中の場合もケア
        child: dbAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('DBエラー: $err')),
          data: (dbInstance) {
            // ★ DBがOKなら、プロジェクト一覧のStreamを監視
            final projectsAsync = ref.watch(projectListStreamProvider);
            
            return projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('プロジェクト一覧の取得エラー: $err')),
              data: (projects) {
                if (projects.isEmpty) {
                  return const Center(child: Text('保存されたプロジェクトが見つかりませんでした。'));
                }
                
                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: ListTile(
                        title: Text(project.projectCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('状態: ${project.inspectionStatus}\nパス: ${project.projectFolderPath}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).pop(project);
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        )
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