// lib/pages/smb_settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// このパスはご自身のプロジェクト構造に合わせてください
import '../widgets/custom_snackbar.dart';

class SmbSettingsPage extends StatefulWidget {
  const SmbSettingsPage({super.key});

  @override
  State<SmbSettingsPage> createState() => _SmbSettingsPageState();
}

class _SmbSettingsPageState extends State<SmbSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  // プロファイル1 (例: 社内Wi-Fi)
  final _host1Controller = TextEditingController();
  final _share1Controller = TextEditingController();
  final _path1Controller = TextEditingController();
  final _user1Controller = TextEditingController();
  final _pass1Controller = TextEditingController();
  final _domain1Controller = TextEditingController();
  bool _useProfile1 = false;

  // プロファイル2 (例: VPN/モバイル)
  final _host2Controller = TextEditingController();
  final _share2Controller = TextEditingController();
  final _path2Controller = TextEditingController();
  final _user2Controller = TextEditingController();
  final _pass2Controller = TextEditingController(); // プロファイル2用のパスワードコントローラー
  final _domain2Controller = TextEditingController();
  bool _useProfile2 = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    // プロファイル1の読み込み
    _host1Controller.text = prefs.getString('smb_host_1') ?? '';
    _share1Controller.text = prefs.getString('smb_share_1') ?? 'Share';
    _path1Controller.text = prefs.getString('smb_path_1') ?? '';
    _domain1Controller.text = prefs.getString('smb_domain_1') ?? '';
    _user1Controller.text = prefs.getString('smb_user_1') ?? '';
    _pass1Controller.text = prefs.getString('smb_pass_1') ?? '';
    _useProfile1 = prefs.getBool('smb_use_1') ?? false;

    // プロファイル2の読み込み
    _host2Controller.text = prefs.getString('smb_host_2') ?? '';
    _share2Controller.text = prefs.getString('smb_share_2') ?? 'Share';
    _path2Controller.text = prefs.getString('smb_path_2') ?? '';
    _domain2Controller.text = prefs.getString('smb_domain_2') ?? '';
    _user2Controller.text = prefs.getString('smb_user_2') ?? '';
    _pass2Controller.text = prefs.getString('smb_pass_2') ?? '';
    _useProfile2 = prefs.getBool('smb_use_2') ?? false;

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      showCustomSnackBar(context, '入力内容を確認してください。', isError: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // プロファイル1の保存
    await prefs.setString('smb_host_1', _host1Controller.text.trim());
    await prefs.setString('smb_share_1', _share1Controller.text.trim());
    await prefs.setString('smb_path_1', _path1Controller.text.trim());
    await prefs.setString('smb_domain_1', _domain1Controller.text.trim());
    await prefs.setString('smb_user_1', _user1Controller.text.trim());
    await prefs.setString('smb_pass_1', _pass1Controller.text);
    await prefs.setBool('smb_use_1', _useProfile1);

    // プロファイル2の保存
    await prefs.setString('smb_host_2', _host2Controller.text.trim());
    await prefs.setString('smb_share_2', _share2Controller.text.trim());
    await prefs.setString('smb_path_2', _path2Controller.text.trim());
    await prefs.setString('smb_domain_2', _domain2Controller.text.trim());
    await prefs.setString('smb_user_2', _user2Controller.text.trim());
    await prefs.setString('smb_pass_2', _pass2Controller.text);
    await prefs.setBool('smb_use_2', _useProfile2);

    if (context.mounted) {
      showCustomSnackBar(context, '共有フォルダ設定を保存しました。');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('共有フォルダ設定'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: '設定を保存',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildProfileCard(
                    title: 'プロファイル1 (例: 社内Wi-Fi)',
                    useProfile: _useProfile1,
                    onUseChanged: (val) => setState(() => _useProfile1 = val ?? false),
                    hostController: _host1Controller,
                    shareController: _share1Controller,
                    pathController: _path1Controller,
                    domainController: _domain1Controller,
                    userController: _user1Controller,
                    passController: _pass1Controller,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileCard(
                    title: 'プロファイル2 (例: VPN/モバイル)',
                    useProfile: _useProfile2,
                    onUseChanged: (val) => setState(() => _useProfile2 = val ?? false),
                    hostController: _host2Controller,
                    shareController: _share2Controller,
                    pathController: _path2Controller,
                    domainController: _domain2Controller,
                    userController: _user2Controller,
                    // ★★★ ここを修正 ★★★
                    passController: _pass2Controller, // _passController -> _pass2Controller
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('設定を保存'),
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required bool useProfile,
    required ValueChanged<bool?> onUseChanged,
    required TextEditingController hostController,
    required TextEditingController shareController,
    required TextEditingController pathController,
    required TextEditingController domainController,
    required TextEditingController userController,
    required TextEditingController passController,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: Text(title, style: Theme.of(context).textTheme.titleMedium),
              value: useProfile,
              onChanged: onUseChanged,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            TextFormField(
              controller: hostController,
              decoration: const InputDecoration(
                // ★ 修正: ラベルと入力欄の隙間を確保
                isDense: true, 
                contentPadding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
                labelText: 'ホスト名 または IPアドレス (*)',
                hintText: '例: 192.168.1.100',
              ),
              validator: (value) {
                if (useProfile && (value == null || value.isEmpty)) {
                  return '必須項目です';
                }
                return null;
              },
            ),
            TextFormField(
              controller: shareController,
              decoration: const InputDecoration(
                // ★ 修正: ラベルと入力欄の隙間を確保
                isDense: true, 
                contentPadding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
                labelText: '共有名 (*)',
                hintText: '例: Share や Public',
              ),
              validator: (value) {
                if (useProfile && (value == null || value.isEmpty)) {
                  return '必須項目です';
                }
                return null;
              },
            ),
            TextFormField(
              controller: pathController,
              decoration: const InputDecoration(
                // ★ 修正: ラベルと入力欄の隙間を確保
                isDense: true, 
                contentPadding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
                labelText: 'フォルダパス (共有名以下)',
                hintText: '例: 検品データ/2025年 (空欄可)',
              ),
              // パスは空欄でもOK
            ),
            TextFormField(
              controller: domainController,
              decoration: const InputDecoration(
                // ★ 修正: ラベルと入力欄の隙間を確保
                isDense: true, 
                contentPadding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
                labelText: 'ドメイン名 (空欄可)',
                hintText: '例: WORKGROUP (通常は空欄)',
              ),
            ),
            TextFormField(
              controller: userController,
              decoration: const InputDecoration(
                // ★ 修正: ラベルと入力欄の隙間を確保
                isDense: true, 
                contentPadding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
                labelText: 'ユーザー名 (*)',
              ),
              validator: (value) {
                if (useProfile && (value == null || value.isEmpty)) {
                  return '必須項目です';
                }
                return null;
              },
            ),
            TextFormField(
              controller: passController,
              decoration: const InputDecoration(
                // ★ 修正: ラベルと入力欄の隙間を確保
                isDense: true, 
                contentPadding: EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
                labelText: 'パスワード (*)',
              ),
              obscureText: true,
              validator: (value) {
                if (useProfile && (value == null || value.isEmpty)) {
                  return '必須項目です';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _host1Controller.dispose();
    _share1Controller.dispose();
    _path1Controller.dispose();
    _domain1Controller.dispose();
    _user1Controller.dispose();
    _pass1Controller.dispose();

    _host2Controller.dispose();
    _share2Controller.dispose();
    _path2Controller.dispose();
    _domain2Controller.dispose();
    _user2Controller.dispose();
    _pass2Controller.dispose();
    super.dispose();
  }
}