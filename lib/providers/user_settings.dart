import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://10.0.2.2:5000'; // ✅ 改成你的 Flask 後端位址

/// 取得使用者設定
Future<Map<String, dynamic>?> getUserSettings(int userId) async {
  final url = Uri.parse('$baseUrl/api/settings/$userId');
  try {
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      print('❌ 無法取得設定: ${resp.statusCode}');
    }
  } catch (e) {
    print('❌ 錯誤: $e');
  }
  return null;
}

/// 更新使用者設定
Future<bool> updateUserSettings(
  int userId,
  Map<String, dynamic> settings,
) async {
  final url = Uri.parse('$baseUrl/api/settings/$userId');
  try {
    final resp = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(settings),
    );
    if (resp.statusCode == 200) {
      print('✅ 設定更新成功');
      return true;
    } else {
      print('❌ 設定更新失敗: ${resp.statusCode}');
    }
  } catch (e) {
    print('❌ 更新錯誤: $e');
  }
  return false;
}
