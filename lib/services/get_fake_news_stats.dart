import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = "http://10.0.2.2:5000"; // 👈 放這裡！

Future<Map<String, dynamic>?> getFakeNewsStats() async {
  final url = Uri.parse('$baseUrl/api/fake-news-stats');
  try {
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  } catch (e) {
    return null;
  }
}
