import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';

class DatabaseService {
  static DatabaseService? _instance;
  PostgreSQLConnection? _connection;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  // 初始化資料庫連線
  Future<void> initConnection() async {
    try {
      _connection = PostgreSQLConnection(
        'localhost',            // host
        5432,                  // port
        'truthliesdetector',   // database name
        username: 'postgres',  // username
        password: '1234',      // password
      );
      
      await _connection!.open();
      print('資料庫連線成功');
    } catch (e) {
      print('資料庫連線失敗: $e');
      rethrow;
    }
  }

  // 關閉資料庫連線
  Future<void> closeConnection() async {
    await _connection?.close();
    _connection = null;
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
      if (_connection == null || _connection!.isClosed) await initConnection();

      // 檢查帳號是否已存在
      final checkResult = await _connection!.query(
        'SELECT account FROM public.users WHERE account = @account',
        substitutionValues: {'account': user.account},
      );

      if (checkResult.isNotEmpty) {
        throw Exception('帳號已存在');
      }

      // 檢查 email 是否已存在
      final emailCheckResult = await _connection!.query(
        'SELECT email FROM public.users WHERE email = @email',
        substitutionValues: {'email': user.email},
      );

      if (emailCheckResult.isNotEmpty) {
        throw Exception('電子郵件已被使用');
      }

      // 插入新用戶
      final hashedPassword = _hashPassword(user.password);
      await _connection!.query(
        '''
        INSERT INTO public.users (account, username, password, email, phone)
        VALUES (@account, @username, @password, @email, @phone)
        ''',
        substitutionValues: {
          'account': user.account,
          'username': user.username,
          'password': hashedPassword,
          'email': user.email,
          'phone': user.phone,
        },
      );

      return true;
    } catch (e) {
      print('註冊失敗: $e');
      return false;
    }
  }

  // 用戶登入
  Future<User?> loginUser(String account, String password) async {
    try {
      if (_connection == null || _connection!.isClosed) await initConnection();

      final hashedPassword = _hashPassword(password);
      final result = await _connection!.query(
        '''
        SELECT user_id, account, username, password, email, phone
        FROM public.users
        WHERE account = @account AND password = @password
        ''',
        substitutionValues: {
          'account': account,
          'password': hashedPassword,
        },
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return User(
          userId: row[0] as int,
          account: row[1] as String,
          username: row[2] as String,
          password: row[3] as String,
          email: row[4] as String,
          phone: row[5] as String?,
        );
      }

      return null;
    } catch (e) {
      print('登入失敗: $e');
      return null;
    }
  }

  // 取得用戶資料
  Future<User?> getUserById(int userId) async {
    try {
      if (_connection == null || _connection!.isClosed) await initConnection();

      final result = await _connection!.query(
        '''
        SELECT user_id, account, username, password, email, phone
        FROM public.users
        WHERE user_id = @userId
        ''',
        substitutionValues: {'userId': userId},
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return User(
          userId: row[0] as int,
          account: row[1] as String,
          username: row[2] as String,
          password: row[3] as String,
          email: row[4] as String,
          phone: row[5] as String?,
        );
      }

      return null;
    } catch (e) {
      print('取得用戶資料失敗: $e');
      return null;
    }
  }

  // 更新用戶資料
  Future<bool> updateUser(User user) async {
    try {
      if (_connection == null || _connection!.isClosed) await initConnection();

      await _connection!.query(
        '''
        UPDATE public.users
        SET username = @username, email = @email, phone = @phone
        WHERE user_id = @userId
        ''',
        substitutionValues: {
          'username': user.username,
          'email': user.email,
          'phone': user.phone,
          'userId': user.userId,
        },
      );

      return true;
    } catch (e) {
      print('更新用戶資料失敗: $e');
      return false;
    }
  }

  // 更新密碼
  Future<bool> updatePassword(int userId, String newPassword) async {
    try {
      if (_connection == null || _connection!.isClosed) await initConnection();

      final hashedPassword = _hashPassword(newPassword);
      await _connection!.query(
        'UPDATE public.users SET password = @password WHERE user_id = @userId',
        substitutionValues: {
          'password': hashedPassword,
          'userId': userId,
        },
      );

      return true;
    } catch (e) {
      print('更新密碼失敗: $e');
      return false;
    }
  }
}