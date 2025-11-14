import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl {
    final envUrl = dotenv.env['API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    if (kIsWeb) return "http://127.0.0.1:8000";
    if (Platform.isAndroid) return "http://10.0.2.2:8000";
    return "http://127.0.0.1:8000";
  }

  static Future<Article> fetchArticleById(int id) async {
    final url = Uri.parse("$baseUrl/articles/$id");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data.containsKey("article")) {
        return Article.fromJson(data["article"]);
      }
      if (data is Map<String, dynamic>) return Article.fromJson(data);
      throw Exception("文章格式錯誤: ${response.body}");
    } else {
      throw Exception("無法取得文章資料，statusCode: ${response.statusCode}");
    }
  }
}