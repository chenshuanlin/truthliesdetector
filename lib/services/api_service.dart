import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000'; // Flask 後端連線位置

  // 🔥 熱門趨勢文章
  static Future<List<dynamic>> fetchTrendingArticles() async {
    final response = await http.get(Uri.parse('$baseUrl/api/trending'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('無法取得熱門趨勢資料');
    }
  }

  // 🎯 為您推薦（推薦文章）
  static Future<List<dynamic>> fetchRecommendations() async {
    final response = await http.get(Uri.parse('$baseUrl/api/recommended'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('無法取得推薦資料');
    }
  }

  // 🏆 排行榜（依 reliability_score）
  static Future<List<dynamic>> fetchRanking() async {
    final response = await http.get(Uri.parse('$baseUrl/api/ranking'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('無法取得排行榜資料');
    }
  }

  // 📰 文章詳情（HomePage 點擊會用到）
  static Future<Map<String, dynamic>> fetchArticleDetail(int articleId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/$articleId'));
      if (response.statusCode == 200) {
      return json.decode(response.body);
  } else {
    throw Exception('無法取得文章詳情');
  }
}

}
