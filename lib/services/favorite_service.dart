// lib/services/favorite_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/favorite_model.dart';

class FavoriteService {
  /// 取得指定使用者的收藏列表
  static Future<List<Favorite>> fetchUserFavorites(int userId) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000';
    final response =
        await http.get(Uri.parse('$apiUrl/favorites/user/$userId'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Favorite.fromJson(e)).toList();
    } else {
      throw Exception('無法取得收藏列表 (${response.statusCode})');
    }
  }

  /// 新增收藏
  static Future<bool> addFavorite(int userId, int articleId) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'article_id': articleId}),
    );

    if (response.statusCode == 200) {
      return true; // 收藏成功
    } else if (response.statusCode == 400) {
      // 後端重複收藏會回傳 {"detail":"已收藏過"}
      final msg = jsonDecode(response.body)['detail'] ?? '已收藏過';
      throw Exception(msg);
    } else {
      throw Exception('收藏失敗 (${response.statusCode})');
    }
  }
}
