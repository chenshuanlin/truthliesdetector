import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';
import 'dart:io';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8000";
    } else {
      return "http://127.0.0.1:8000";
    }
  }

  // 取得單篇文章
  static Future<Article> fetchArticleById(int id) async {
    final url = Uri.parse("$baseUrl/articles/$id");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Article.fromJson(data);
    } else {
      throw Exception("無法取得文章資料，statusCode: ${response.statusCode}");
    }
  }

  // 取得收藏列表
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final url = Uri.parse("$baseUrl/favorites");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // 假設回傳 {"favorites":[{favorite_id:..., article_id:..., user_id:...}, ...]}
      return List<Map<String, dynamic>>.from(data['favorites']);
    } else {
      throw Exception("無法取得收藏列表，statusCode: ${response.statusCode}");
    }
  }

  // 根據多個 articleId 批次抓文章
  static Future<List<Article>> getArticlesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final idsParam = ids.join(',');
    final url = Uri.parse("$baseUrl/articles?ids=$idsParam");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // 假設回傳 {"articles":[{...},{...}]}
      final List articlesJson = data['articles'];
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception("無法取得文章資料，statusCode: ${response.statusCode}");
    }
  }
}
