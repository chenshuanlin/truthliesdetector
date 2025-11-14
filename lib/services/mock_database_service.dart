import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';

class MockDatabaseService {
  static MockDatabaseService? _instance;
  // 模擬資料庫儲存
  static final List<User> _users = [
    // 預設測試用戶
    User(
      userId: 1,
      account: 'test',
      username: '測試用戶',
      password: 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', // 'hello' 的 SHA256
      email: 'test@example.com',
      phone: '0912345678',
    ),
  ];
  static int _nextUserId = 2;

  MockDatabaseService._();

  static MockDatabaseService get instance {
    _instance ??= MockDatabaseService._();
    return _instance!;
  }

  // 初始化連線（模擬）
  Future<void> initConnection() async {
    // 模擬連線延遲
    await Future.delayed(const Duration(milliseconds: 500));
    print('模擬資料庫連線成功');
  }

  // 關閉連線（模擬）
  Future<void> closeConnection() async {
    print('模擬資料庫連線關閉');
  }

  // 密碼加密
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 用戶註冊
  Future<bool> registerUser(User user) async {
    try {
      await initConnection();

      // 檢查帳號是否已存在
      final existingUser = _users.where((u) => u.account == user.account).firstOrNull;
      if (existingUser != null) {
        throw Exception('帳號已存在');
      }

      // 檢查 email 是否已存在
      final existingEmail = _users.where((u) => u.email == user.email).firstOrNull;
      if (existingEmail != null) {
        throw Exception('電子郵件已被使用');
      }

      // 建立新用戶
      final hashedPassword = _hashPassword(user.password);
      final newUser = User(
        userId: _nextUserId++,
        account: user.account,
        username: user.username,
        password: hashedPassword,
        email: user.email,
        phone: user.phone,
      );

      _users.add(newUser);
      print('用戶註冊成功: ${user.account}');
      return true;
    } catch (e) {
      print('註冊失敗: $e');
      rethrow;
    }
  }

  // 用戶登入
  Future<User?> loginUser(String account, String password) async {
    try {
      await initConnection();

      final hashedPassword = _hashPassword(password);
      final user = _users.where((u) => 
        u.account == account && u.password == hashedPassword
      ).firstOrNull;

      if (user != null) {
        print('用戶登入成功: $account');
        return user;
      } else {
        print('登入失敗: 帳號或密碼錯誤');
        return null;
      }
    } catch (e) {
      print('登入失敗: $e');
      return null;
    }
  }

  // 取得用戶資料
  Future<User?> getUserById(int userId) async {
    try {
      await initConnection();

      final user = _users.where((u) => u.userId == userId).firstOrNull;
      if (user != null) {
        print('取得用戶資料成功: ${user.account}');
      }
      return user;
    } catch (e) {
      print('取得用戶資料失敗: $e');
      return null;
    }
  }

  // 更新用戶資料
  Future<bool> updateUser(User updatedUser) async {
    try {
      await initConnection();

      final index = _users.indexWhere((u) => u.userId == updatedUser.userId);
      if (index != -1) {
        // 保持原始密碼
        final originalPassword = _users[index].password;
        _users[index] = User(
          userId: updatedUser.userId,
          account: updatedUser.account,
          username: updatedUser.username,
          password: originalPassword,
          email: updatedUser.email,
          phone: updatedUser.phone,
        );
        print('用戶資料更新成功: ${updatedUser.account}');
        return true;
      }
      return false;
    } catch (e) {
      print('更新用戶資料失敗: $e');
      return false;
    }
  }

  // 更新密碼
  Future<bool> updatePassword(int userId, String newPassword) async {
    try {
      await initConnection();

      final index = _users.indexWhere((u) => u.userId == userId);
      if (index != -1) {
        final hashedPassword = _hashPassword(newPassword);
        final user = _users[index];
        _users[index] = User(
          userId: user.userId,
          account: user.account,
          username: user.username,
          password: hashedPassword,
          email: user.email,
          phone: user.phone,
        );
        print('密碼更新成功');
        return true;
      }
      return false;
    } catch (e) {
      print('更新密碼失敗: $e');
      return false;
    }
  }

  // 除錯用：列出所有用戶
  void debugListUsers() {
    print('=== 模擬資料庫中的用戶 ===');
    for (final user in _users) {
      print('ID: ${user.userId}, 帳號: ${user.account}, 用戶名: ${user.username}, Email: ${user.email}');
    }
    print('========================');
  }
}