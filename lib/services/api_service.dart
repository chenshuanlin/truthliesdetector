import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  static ApiService? _instance;
  final String baseUrl;

  ApiService._internal(this.baseUrl);

  /// ⭐ 正常版：不要自動加 /api
  static ApiService getInstance({String? baseUrl}) {
    _instance ??= ApiService._internal(
      baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:5000',
          ),
    );
    return _instance!;
  }

  // ===================================================================
  // 1. Login
  // ===================================================================
  Future<User?> login(String account, String password) async {
    final url = Uri.parse('$baseUrl/api/login');

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'account': account, 'password': password}),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return _userFromMap(data['user']);
    }
    return null;
  }

  // ===================================================================
  // 2. Register
  // ===================================================================
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

    if (resp.statusCode == 200) return 'success';

    try {
      final data = jsonDecode(resp.body);
      return data['error'] ?? '註冊失敗';
    } catch (_) {
      return '註冊失敗';
    }
  }

  // ===================================================================
  // 3. Get User — 給 Provider 初始化用
  // ===================================================================
  Future<User?> getUser(int userId) async {
    final url = Uri.parse('$baseUrl/api/users/$userId');
    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return _userFromMap(data['user']);
    }
    return null;
  }

  // ===================================================================
  // 4. Update User
  // ===================================================================
  Future<bool> updateUser(User user) async {
    final url = Uri.parse('$baseUrl/api/users/${user.userId}');

    final resp = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': user.username,
        'email': user.email,
        'phone': user.phone,
      }),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['ok'] == true || data['success'] == true;
    }

    return false;
  }

  // ===================================================================
  // 5. 假新聞統計
  // ===================================================================
  Future<Map<String, dynamic>?> getFakeNewsStats() async {
    final resp = await http.get(Uri.parse('$baseUrl/api/fake-news-stats'));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return null;
  }

  // ===================================================================
  // 6. Full Report
  // ===================================================================
  Future<Map<String, dynamic>?> getFullReport() async {
    final resp = await http.get(Uri.parse('$baseUrl/api/full-report'));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['report'];
    }
    return null;
  }

  // ===================================================================
  // 7. Image Analyze
  // ===================================================================
  Future<Map<String, dynamic>?> analyzeImage({
    String? imageUrl,
    String? imageBase64,
  }) async {
    final payload = <String, dynamic>{};
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

  // ===================================================================
  // 8. AI文章 API
  // ===================================================================
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

  // ===================================================================
  // 🧩 Private - user mapping
  // ===================================================================
  User _userFromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      account: map['account'],
      username: map['username'],
      password: '',
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
