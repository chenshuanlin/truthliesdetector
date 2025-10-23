import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  final ApiService _api = ApiService.getInstance();

  // 初始化：檢查本地儲存的登入狀態
  Future<void> initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId != null) {
        final user = await _api.getUser(userId);
        if (user != null) {
          _currentUser = user;
          _isLoggedIn = true;
        } else {
          // 如果資料庫中找不到用戶，清除本地儲存
          await clearUserData();
        }
      }
    } catch (e) {
      print('初始化用戶狀態失敗: $e');
      await clearUserData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 用戶登入
  Future<bool> login(String account, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
  final user = await _api.login(account, password);
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        
        // 儲存登入狀態到本地
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user.userId!);
        await prefs.setString('account', user.account);
        await prefs.setString('username', user.username);
        await prefs.setString('email', user.email);
        if (user.phone != null) {
          await prefs.setString('phone', user.phone!);
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('登入失敗: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 用戶註冊
  Future<String> register(User user) async {
    _isLoading = true;
    notifyListeners();

    try {
      return await _api.register(user);
    } catch (e) {
      print('註冊失敗: $e');
      if (e.toString().contains('帳號已存在')) {
        return '帳號已存在，請使用其他帳號';
      } else if (e.toString().contains('電子郵件已被使用')) {
        return '電子郵件已被使用，請使用其他信箱';
      } else {
        return '註冊失敗：${e.toString()}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 更新用戶資料
  Future<bool> updateUserProfile(String username, String email, String? phone) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = User(
        userId: _currentUser!.userId,
        account: _currentUser!.account,
        username: username,
        password: _currentUser!.password,
        email: email,
        phone: phone,
      );

  final success = await _api.updateUser(updatedUser);
      if (success) {
        _currentUser = updatedUser;
        
        // 更新本地儲存
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('email', email);
        if (phone != null) {
          await prefs.setString('phone', phone);
        } else {
          await prefs.remove('phone');
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('更新用戶資料失敗: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 用戶登出
  Future<void> logout() async {
    await clearUserData();
    notifyListeners();
  }

  // 清除用戶資料
  Future<void> clearUserData() async {
    _currentUser = null;
    _isLoggedIn = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('account');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('phone');
  }
}