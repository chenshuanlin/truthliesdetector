import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchLogService {
  // 從 .env 讀取後端 API
  static final String baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000';

  /// 新增瀏覽紀錄
  static Future<void> addLog({
    required int userId,
    required String query,
    required String searchResult,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/search_logs/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'query': query,
        'search_result': searchResult,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('新增瀏覽紀錄失敗：${response.statusCode}');
    }
  }

  /// 取得指定使用者的瀏覽紀錄
  static Future<List<dynamic>> fetchUserLogs(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/search_logs/$userId'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('取得瀏覽紀錄失敗：${res.statusCode}');
    }
  }
}
