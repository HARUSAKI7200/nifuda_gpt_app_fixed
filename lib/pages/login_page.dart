// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/user_state.dart';
import '../database/app_database.dart';
import '../widgets/custom_snackbar.dart';
import 'home_page.dart'; // ★ 追加: 遷移先として必要

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  bool _isCreatingNew = false; // 新規作成モードかどうか

  @override
  void initState() {
    super.initState();
    // ★ 追加: ログイン画面が表示されたら、念のため確実にログアウト状態にする
    // (前の画面から戻ってきた場合や、不正な状態で遷移した場合の対策)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = ref.read(userProvider);
      if (userState.currentUser != null) {
         ref.read(userProvider.notifier).logout();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _onUserSelected(User user) async {
    final success = await ref.read(userProvider.notifier).login(user);
    if (success && mounted) {
      // ★ 修正: 状態変化による自動遷移に頼らず、明示的にHomePageへ遷移する
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  }

  void _onRegister() async {
    final name = _usernameController.text.trim();
    if (name.isEmpty) {
      showCustomSnackBar(context, '名前を入力してください', isError: true);
      return;
    }

    final success = await ref.read(userProvider.notifier).register(name);
    if (!success && mounted) {
      final error = ref.read(userProvider).error;
      showCustomSnackBar(context, error ?? '登録に失敗しました', isError: true);
    } else if (success && mounted) {
      showCustomSnackBar(context, 'ユーザー登録しました: $name');
      // ★ 修正: 登録成功時も明示的にHomePageへ遷移
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final users = userState.registeredUsers;

    return Scaffold(
      appBar: AppBar(title: const Text('検品アプリ ログイン')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- ロゴ ---
              const SizedBox(height: 20),
              const Icon(Icons.verified_user, size: 64, color: Colors.indigo),
              const SizedBox(height: 10),
              const Text(
                '作業者を選択してください',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // --- ユーザーリスト (登録済みがある場合) ---
              if (users.isNotEmpty && !_isCreatingNew) ...[
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(user.username.substring(0, 1), style: const TextStyle(color: Colors.indigo)),
                          ),
                          title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text('ID: ${user.id}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: userState.isLoading ? null : () => _onUserSelected(user),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('新しいアカウントを作成'),
                  onPressed: () {
                    setState(() {
                      _isCreatingNew = true;
                    });
                  },
                ),
                const SizedBox(height: 10),
              ] 
              
              // --- 新規登録フォーム (リストがない場合、または新規作成モード) ---
              else ...[
                Expanded(
                  child: Center(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              users.isEmpty ? '最初のアカウントを作成' : '新規アカウント作成',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'ユーザー名 (例: 田中)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_add),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (userState.isLoading)
                              const CircularProgressIndicator()
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _onRegister,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('登録して開始'),
                                ),
                              ),
                            
                            // キャンセルボタン（リストがある場合のみ表示）
                            if (users.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isCreatingNew = false;
                                  });
                                },
                                child: const Text('キャンセル（一覧に戻る）'),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}