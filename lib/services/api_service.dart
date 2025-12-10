import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  static ApiService? _instance;
  late final String baseUrl;

  // ⭐ 手動設定「電腦的 IPv4」→ 給實體手機使用
  static const String REAL_DEVICE_IP = "http://172.20.10.9:5000";

  ApiService._internal() {
    baseUrl = _detectBaseUrl();
    debugPrint("🌐 API Base URL = $baseUrl");
  }

  static ApiService getInstance() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  // ============================================================
  // ⭐ 自動判斷 Base URL（模擬器 / 實體手機）
  // ============================================================
  String _detectBaseUrl() {
    // 1️⃣ Web
    if (kIsWeb) {
      return "http://localhost:5000";
    }

    // 2️⃣ Android
    if (Platform.isAndroid) {
      // Android 模擬器：10.0.2.2
      // 實體手機：你設定的 REAL_DEVICE_IP
      return _isEmulator() ? "http://10.0.2.2:5000" : REAL_DEVICE_IP;
    }

    // 3️⃣ iPhone 模擬器是 localhost，實體機是你設定的 IP
    if (Platform.isIOS) {
      return REAL_DEVICE_IP;
    }

    // 4️⃣ 其他平台
    return "http://localhost:5000";
  }

  // ============================================================
  // ⭐ 判斷是否為 Android 模擬器（不需要 plugin）
  // ============================================================
  bool _isEmulator() {
    // Android 模擬器的常見特徵
    const emulatorIndicators = [
      "google_sdk",
      "sdk_gphone",
      "sdk_phone_armv7",
      "sdk",
      "emulator",
    ];

    // 取 ANDROID_ID 判斷是否模擬器（不需要 package）
    final id = Platform.environment['ANDROID_BOOTLOGO'] ?? "";

    return emulatorIndicators.any((e) => id.toLowerCase().contains(e));
  }

  // ============================================================
  // 1. Login
  // ============================================================
  Future<User?> login(String account, String password) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'account': account, 'password': password}),
    );

    if (resp.statusCode == 200) {
      final map = jsonDecode(resp.body);
      return _userFromMap(map['user']);
    }

    return null;
  }

  // ============================================================
  // 2. Register（修正成功狀態碼 201）
  // ============================================================
  Future<String> register(User user) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'account': user.account,
        'username': user.username,
        'password': user.password,
        'email': user.email,
        'phone': user.phone,
      }),
    );

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return 'success';
    }

    try {
      final map = jsonDecode(resp.body);
      return map['error'] ?? '註冊失敗';
    } catch (_) {
      return '註冊失敗';
    }
  }

  // ============================================================
  // 3. Get User
  // ============================================================
  Future<User?> getUser(int userId) async {
    final resp = await http.get(Uri.parse('$baseUrl/api/users/$userId'));

    if (resp.statusCode == 200) {
      final map = jsonDecode(resp.body);
      if (map['user'] == null) return null;
      return _userFromMap(map['user']);
    }

    return null;
  }

  // ============================================================
  // 4. Update User
  // ============================================================
  Future<bool> updateUser(User user) async {
    final resp = await http.put(
      Uri.parse('$baseUrl/api/users/${user.userId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': user.username,
        'email': user.email,
        'phone': user.phone,
      }),
    );

    if (resp.statusCode == 200) {
      final map = jsonDecode(resp.body);
      return map['ok'] == true || map['success'] == true;
    }

    return false;
  }

  // ============================================================
  // 其他 API（原封不動）
  // ============================================================
  Future<Map<String, dynamic>?> getFakeNewsStats() async {
    final resp = await http.get(Uri.parse('$baseUrl/api/fake-news-stats'));
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    return null;
  }

  Future<Map<String, dynamic>?> getFullReport() async {
    final resp = await http.get(Uri.parse('$baseUrl/api/full-report'));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['report'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> analyzeImage({
    String? imageUrl,
    String? imageBase64,
  }) async {
    final payload = {};
    if (imageUrl != null) payload['url'] = imageUrl;
    if (imageBase64 != null) payload['imageBase64'] = imageBase64;

    final resp = await http.post(
      Uri.parse('$baseUrl/api/image-check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['result'] ?? data;
    }
    return null;
  }

  Future<List<dynamic>> fetchTrendingArticles() async {
    final resp = await http.get(Uri.parse('$baseUrl/api/trending'));
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception("無法取得熱門趨勢資料");
  }

  Future<List<dynamic>> fetchRecommendations() async {
    final resp = await http.get(Uri.parse('$baseUrl/api/recommended'));
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception("無法取得推薦資料");
  }

  Future<List<dynamic>> fetchRanking() async {
    final resp = await http.get(Uri.parse('$baseUrl/api/ranking'));
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception("無法取得排行榜資料");
  }

  Future<Map<String, dynamic>> fetchArticleDetail(int articleId) async {
    final resp = await http.get(Uri.parse('$baseUrl/api/articles/$articleId'));
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception("無法取得文章詳情");
  }

  Future<List<dynamic>> fetchComments(int articleId) async {
    final resp = await http.get(
      Uri.parse('$baseUrl/api/articles/$articleId/comments'),
    );
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    throw Exception("無法取得留言");
  }

  Future<void> postComment(int articleId, String author, String content) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/articles/$articleId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'author': author, 'content': content}),
    );
    if (resp.statusCode != 201) throw Exception("留言發送失敗");
  }

  // ============================================================
  // ⭐ Map → User 物件
  // ============================================================
  User _userFromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      account: map['account'],
      username: map['username'],
      password: "",
      email: map['email'],
      phone: map['phone'],
      newsCategorySubscription: map['news_category_subscription'] ?? false,
      expertAnalysisSubscription: map['expert_analysis_subscription'] ?? false,
      weeklyReportSubscription: map['weekly_report_subscription'] ?? false,
      fakeNewsAlert: map['fake_news_alert'] ?? false,
      trendingTopicAlert: map['trending_topic_alert'] ?? false,
      expertResponseAlert: map['expert_response_alert'] ?? false,
      privacyPolicyAgreed: map['privacy_policy_agreed'] ?? false,
    );
  }
}
