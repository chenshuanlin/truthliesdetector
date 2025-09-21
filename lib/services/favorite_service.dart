// lib/services/favorite_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import '../models/favorite_model.dart';

class FavoriteService {
  /// 取得 API URL，優先使用 .env，沒有再判斷模擬器/實機
  static String get apiUrl {
    final envUrl = dotenv.env['API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    // Android 模擬器使用 10.0.2.2，實機用局域網 IP
    if (Platform.isAndroid) {
      // 模擬器
      return 'http://10.0.2.2:8000';
      // 實機測試可改成你的局域網 IP，例如：
      // return 'http://192.168.0.111:8000';
    }

    // 其他平台（iOS 模擬器 / Web / Desktop）
    return 'http://localhost:8000';
  }

  /// 取得指定使用者的收藏列表
  static Future<List<Favorite>> fetchUserFavorites(int userId) async {
    final response = await http.get(Uri.parse('$apiUrl/favorites/user/$userId'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Favorite.fromJson(e)).toList();
    } else {
      throw Exception('無法取得收藏列表 (${response.statusCode})');
    }
  }

  /// 新增收藏
  static Future<bool> addFavorite(int userId, int articleId) async {
    final response = await http.post(
      Uri.parse('$apiUrl/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'article_id': articleId}),
    );

    if (response.statusCode == 200) {
      return true; // 收藏成功
    } else if (response.statusCode == 400) {
      final msg = jsonDecode(response.body)['detail'] ?? '已收藏過';
      throw Exception(msg);
    } else {
      throw Exception('收藏失敗 (${response.statusCode})');
    }
  }

  /// 取得單篇文章詳細資料
  static Future<Map<String, dynamic>?> fetchArticleById(int articleId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/articles/$articleId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('讀取文章失敗: $e');
      return null;
    }
  }
}
