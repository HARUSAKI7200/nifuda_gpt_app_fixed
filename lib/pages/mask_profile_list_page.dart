// lib/pages/mask_profile_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/project_state.dart';
import '../widgets/custom_snackbar.dart';
import '../database/app_database.dart';

class MaskProfileListPage extends ConsumerStatefulWidget {
  const MaskProfileListPage({super.key});

  @override
  ConsumerState<MaskProfileListPage> createState() => _MaskProfileListPageState();
}

class _MaskProfileListPageState extends ConsumerState<MaskProfileListPage> {
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
        content: Text('マスク設定「$name」を削除しますか？\nこの操作は取り消せません。'),
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
      await _loadProfiles(); // リスト更新
      if (mounted) showCustomSnackBar(context, '削除しました');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('マスク設定の管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? const Center(child: Text('保存されたマスク設定はありません'))
              : ListView.builder(
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    // 範囲の数をカウント（表示用）
                    final rectCount = (jsonDecode(profile.rectsJson) as List).length;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(profile.profileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('黒塗り箇所: $rectCount 個'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProfile(profile.id, profile.profileName),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}