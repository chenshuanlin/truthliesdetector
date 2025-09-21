import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchLogService {
  /// 自動判斷 API URL
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android 模擬器
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:8000'; // iOS 模擬器
    } else {
      return dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000'; // 真機或 fallback
    }
  }

  /// 新增瀏覽紀錄
  static Future<void> addLog({
    required int userId,
    required String query,
    required String searchResult,
  }) async {
    try {
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
    } catch (e) {
      // 可以在頁面上捕捉錯誤並顯示 SnackBar
      rethrow;
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
