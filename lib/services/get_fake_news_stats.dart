  Future<Map<String, dynamic>?> getFakeNewsStats() async {
    final url = Uri.parse('$baseUrl/api/fake-news-stats');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
