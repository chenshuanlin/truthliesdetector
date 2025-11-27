import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  static ApiService? _instance;
  final String baseUrl;

  ApiService._internal(this.baseUrl);

  static ApiService getInstance({String? baseUrl}) {
    _instance ??= ApiService._internal(
      baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://192.168.0.125:5000',
          ),
    );
    return _instance!;
  }

  Future<Map<String, dynamic>?> getFakeNewsStats() async {
    final url = Uri.parse('$baseUrl/api/fake-news-stats');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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

  Future<String> register(User user) async {
    final url = Uri.parse('$baseUrl/api/register');
    final resp = await http.post(
      url,
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
    try {
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': user.username,
          'email': user.email,
          'phone': user.phone,
        }),
      );
      print('API 回應狀態碼: ${resp.statusCode}');
      print('API 回應內容: ${resp.body}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['ok'] == true ||
            data['success'] == true ||
            data['stats'] == true;
      }
      return false;
    } catch (e) {
      print('API 請求錯誤: $e');
      return false;
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

  Future<Map<String, dynamic>?> analyzeImage({
    String? imageUrl,
    String? imageBase64,
  }) async {
    final url = Uri.parse('$baseUrl/api/image-check');
    try {
      final payload = <String, dynamic>{};
      if (imageUrl != null) payload['url'] = imageUrl;
      if (imageBase64 != null) payload['imageBase64'] = imageBase64;
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
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

  Future<Map<String, dynamic>?> triggerScraper({String query = '減肥'}) async {
    final url = Uri.parse('$baseUrl/api/trigger-scraper');
    print('觸發爬蟲: $url, 查詢關鍵字: $query');
    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );
      print('爬蟲觸發回應狀態碼: ${resp.statusCode}');
      print('爬蟲觸發回應內容: ${resp.body}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data;
      }
      return null;
    } catch (e) {
      print('觸發爬蟲錯誤: $e');
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
      newsCategorySubscription: map['news_category_subscription'] ?? false,
      expertAnalysisSubscription: map['expert_analysis_subscription'] ?? false,
      weeklyReportSubscription: map['weekly_report_subscription'] ?? false,
      fakeNewsAlert: map['fake_news_alert'] ?? false,
      trendingTopicAlert: map['trending_topic_alert'] ?? false,
      expertResponseAlert: map['expert_response_alert'] ?? false,
      privacyPolicyAgreed: map['privacy_policy_agreed'] ?? false,
    );
  }

  // 🔥 熱門趨勢文章
  Future<List<dynamic>> fetchTrendingArticles() async {
    final response = await http.get(Uri.parse('$baseUrl/api/trending'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('無法取得熱門趨勢資料');
    }
  }

  // 🎯 為您推薦（推薦文章）
  Future<List<dynamic>> fetchRecommendations() async {
    final response = await http.get(Uri.parse('$baseUrl/api/recommended'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('無法取得推薦資料');
    }
  }

  // 🏆 排行榜（依 reliability_score）
  Future<List<dynamic>> fetchRanking() async {
    final response = await http.get(Uri.parse('$baseUrl/api/ranking'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('無法取得排行榜資料');
    }
  }

  // 📰 文章詳情（HomePage 點擊會用到）
  Future<Map<String, dynamic>> fetchArticleDetail(int articleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/articles/$articleId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('無法取得文章詳情');
    }
  }

  // 💬 取得留言
  Future<List<dynamic>> fetchComments(int articleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/articles/$articleId/comments'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('無法取得留言');
    }
  }

  // ✏️ 發送留言
  Future<void> postComment(int articleId, String author, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/articles/$articleId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'author': author, 'content': content}),
    );
    if (response.statusCode != 201) {
      throw Exception('留言發送失敗');
    }
  }
}
