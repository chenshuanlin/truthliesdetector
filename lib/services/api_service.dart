import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  static ApiService? _instance;
  final String baseUrl;

  ApiService._internal(this.baseUrl);

  static ApiService getInstance({String? baseUrl}) {
    _instance ??= ApiService._internal(baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080'));
    return _instance!;
  }

  Future<User?> login(String account, String password) async {
    final url = Uri.parse('$baseUrl/api/login');
    final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'account': account,
      'password': password,
    }));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return _userFromMap(data['user']);
    }
    return null;
  }

  Future<String> register(User user) async {
    final url = Uri.parse('$baseUrl/api/register');
    final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'account': user.account,
      'username': user.username,
      'password': user.password,
      'email': user.email,
      'phone': user.phone,
    }));
    if (resp.statusCode == 200) return 'success';
    try {
      final data = jsonDecode(resp.body);
      return data['error'] ?? '註冊失敗';
    } catch (_) {
      return '註冊失敗';
    }
  }

  Future<User?> getUser(int userId) async {
    final url = Uri.parse('$baseUrl/api/users/$userId');
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return _userFromMap(data['user']);
    }
    return null;
  }

  Future<bool> updateUser(User user) async {
    final url = Uri.parse('$baseUrl/api/users/${user.userId}');
    final resp = await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'username': user.username,
      'email': user.email,
      'phone': user.phone,
    }));
    return resp.statusCode == 200;
  }

  Future<Map<String, dynamic>?> analyzeNews(String newsUrl) async {
    final url = Uri.parse('$baseUrl/api/analyze-news');
    final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'url': newsUrl,
    }));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['analysis'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getFakeNewsStats() async {
    final url = Uri.parse('$baseUrl/api/fake-news-stats');
    print('正在請求: $url');
    try {
      final resp = await http.get(url);
      print('API 回應狀態碼: ${resp.statusCode}');
      print('API 回應內容: ${resp.body}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['stats'];
      }
      return null;
    } catch (e) {
      print('API 請求錯誤: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFullReport() async {
    final url = Uri.parse('$baseUrl/api/full-report');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['report'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeImage({String? imageUrl, String? imageBase64}) async {
    final url = Uri.parse('$baseUrl/api/image-check');
    try {
      final payload = <String, dynamic>{};
      if (imageUrl != null) payload['url'] = imageUrl;
      if (imageBase64 != null) payload['imageBase64'] = imageBase64;
      final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['result'] as Map<String, dynamic>? ?? data;
      }
      return null;
    } catch (e) {
      print('analyzeImage error: $e');
      return null;
    }
  }

  User _userFromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] as int?,
      account: map['account'] as String,
      username: map['username'] as String,
      password: '',
      email: map['email'] as String,
      phone: map['phone'] as String?,
    );
  }
}
