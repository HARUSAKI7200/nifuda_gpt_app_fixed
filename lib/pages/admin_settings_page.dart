// lib/pages/admin_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'smb_settings_page.dart';
import 'profile_list_page.dart'; // 名前を変更して再利用・拡張します

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者設定'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: ListView(
        children: [
          _buildSectionHeader('基本設定'),
          _buildSettingsTile(
            context,
            icon: Icons.folder_shared,
            title: '共有フォルダ (SMB) 設定',
            subtitle: 'Excelファイルの保存先サーバー設定',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmbSettingsPage()),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader('作業プロファイル管理'),
          _buildSettingsTile(
            context,
            icon: Icons.settings_applications,
            title: '作業プロファイル設定',
            subtitle: '会社・生産課ごとの項目定義、照合ルール、黒塗り設定',
            onTap: () {
              // リストページへ遷移（新規作成もここから）
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileListPage()),
              );
            },
          ),
          // 将来的にユーザー管理などもここに追加可能
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blueGrey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blueGrey[800]),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}