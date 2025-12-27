// lib/state/user_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import 'project_state.dart'; // databaseProviderへのアクセスのため

// 状態クラス
class UserState {
  final User? currentUser;
  final List<User> registeredUsers; // ★ 追加: 登録済みユーザーリスト
  final bool isLoading;
  final String? error;

  const UserState({
    this.currentUser,
    this.registeredUsers = const [],
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    User? currentUser,
    List<User>? registeredUsers,
    bool? isLoading,
    String? error
  }) {
    return UserState(
      currentUser: currentUser ?? this.currentUser,
      registeredUsers: registeredUsers ?? this.registeredUsers,
      isLoading: isLoading ?? this.isLoading,
      error: error, // エラーはnullを渡せるようにする（リセット用）
    );
  }
}

// Notifier
class UserNotifier extends StateNotifier<UserState> {
  final AppDatabase _db;
  static const String _prefKeyUserId = 'logged_in_user_id';

  UserNotifier(this._db) : super(const UserState()) {
    // 起動時はユーザーリストを読み込むだけにする（自動ログインはしない）
    loadRegisteredUsers();
  }

  // 登録済みユーザー一覧を読み込む
  Future<void> loadRegisteredUsers() async {
    state = state.copyWith(isLoading: true);
    try {
      final users = await _db.usersDao.getAllUsers();
      state = state.copyWith(registeredUsers: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'ユーザー一覧の取得に失敗: $e');
    }
  }

  // ログイン処理 (IDまたは名前で)
  Future<bool> login(User user) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _saveUserSession(user.id);
      state = state.copyWith(currentUser: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'ログインエラー: $e');
      return false;
    }
  }

  // 新規登録処理
  Future<bool> register(String username) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final existing = await _db.usersDao.findUserByName(username);
      if (existing != null) {
        state = state.copyWith(isLoading: false, error: 'このユーザー名は既に使用されています。');
        return false;
      }

      final id = await _db.usersDao.createUser(username);
      final newUser = await _db.usersDao.getUserById(id);
      
      if (newUser != null) {
        await _saveUserSession(newUser.id);
        // リストを再読み込みして最新の状態にする
        final allUsers = await _db.usersDao.getAllUsers();
        state = state.copyWith(
          currentUser: newUser, 
          registeredUsers: allUsers,
          isLoading: false
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '登録エラー: $e');
      return false;
    }
  }

  // ログアウト
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyUserId);
    // ログアウト時はcurrentUserをnullにし、リストは再ロードしておく
    final users = await _db.usersDao.getAllUsers();
    state = state.copyWith(currentUser: null, registeredUsers: users); // currentUserをnullに
  }

  Future<void> _saveUserSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyUserId, userId);
  }
}

// Provider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  if (dbAsync.hasValue) {
    return UserNotifier(dbAsync.requireValue);
  } else {
    // 起動直後のロード待機などは呼び出し元で管理
    throw Exception('Database not initialized');
  }
});