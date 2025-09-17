import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';
import 'dart:io';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8000"; // Android 模擬器
    } else {
      return "http://127.0.0.1:8000"; // iOS 模擬器或桌機
    }
  }

  // 取得單篇文章
  static Future<Article> fetchArticleById(int id) async {
    final url = Uri.parse("$baseUrl/articles/$id");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic> && data.containsKey("article")) {
        return Article.fromJson(data["article"]);
      }
      if (data is Map<String, dynamic>) {
        return Article.fromJson(data);
      }

      throw Exception("文章格式錯誤: ${response.body}");
    } else {
      throw Exception("無法取得文章資料，statusCode: ${response.statusCode}");
    }
  }

  // 取得收藏文章 IDs
  static Future<List<int>> getFavoriteArticleIds() async {
    final url = Uri.parse("$baseUrl/favorites");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final favorites = List<Map<String, dynamic>>.from(data['favorites']);
      return favorites.map((f) => f['article_id'] as int).toList();
    } else {
      throw Exception("無法取得收藏列表");
    }
  }

  // 批次取得文章
  static Future<List<Article>> getArticlesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final url = Uri.parse("$baseUrl/articles?ids=${ids.join(',')}");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic> && data.containsKey("articles")) {
        final List articlesJson = data["articles"];
        return articlesJson.map((json) => Article.fromJson(json)).toList();
      }

      if (data is List) {
        return data.map((json) => Article.fromJson(json)).toList();
      }

      throw Exception("文章列表格式錯誤: ${response.body}");
    } else {
      throw Exception("無法取得文章資料，statusCode: ${response.statusCode}");
    }
  }
}
