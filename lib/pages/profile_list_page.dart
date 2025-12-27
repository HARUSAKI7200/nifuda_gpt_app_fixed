// lib/pages/profile_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/project_state.dart';
import '../widgets/custom_snackbar.dart';
import '../database/app_database.dart';
import 'profile_edit_page.dart'; // 新しい編集ページ

class ProfileListPage extends ConsumerStatefulWidget {
  const ProfileListPage({super.key});

  @override
  ConsumerState<ProfileListPage> createState() => _ProfileListPageState();
}

class _ProfileListPageState extends ConsumerState<ProfileListPage> {
  List<MaskProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final db = ref.read(appDatabaseInstanceProvider);
    final profiles = await db.maskProfilesDao.getAllProfiles();
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProfile(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定の削除'),
        content: Text('プロファイル「$name」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(appDatabaseInstanceProvider);
      await db.maskProfilesDao.deleteProfile(id);
      await _loadProfiles(); 
      // メイン状態も更新
      ref.read(projectProvider.notifier).loadMaskProfiles();
      if (mounted) showCustomSnackBar(context, '削除しました');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('作業プロファイル一覧')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileEditPage()),
          );
          if (result == true) {
            _loadProfiles();
            ref.read(projectProvider.notifier).loadMaskProfiles();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? const Center(child: Text('登録されたプロファイルはありません。\n「+」ボタンから作成してください。'))
              : ListView.builder(
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(profile.profileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('抽出モード: ${profile.extractionMode ?? "標準"}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProfileEditPage(existingProfile: profile)),
                                );
                                if (result == true) {
                                  _loadProfiles();
                                  ref.read(projectProvider.notifier).loadMaskProfiles();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProfile(profile.id, profile.profileName),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}