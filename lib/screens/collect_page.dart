import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'article_page.dart'; // 文章詳情頁

class CollectPage extends StatefulWidget {
  static const String route = '/collect';
  const CollectPage({super.key});

  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage> {
  List<Map<String, dynamic>> favoriteArticles = [];
  bool isLoading = true;

  // 這裡請換成登入後的實際 userId
  final int currentUserId = 1;
  // 你的後端 FastAPI 伺服器位址
  final String apiBaseUrl = 'http://192.168.0.111:8000';

  @override
  void initState() {
    super.initState();
    _loadFavoriteArticles();
  }

  Future<void> _loadFavoriteArticles() async {
    try {
      final url = Uri.parse('$apiBaseUrl/favorites/user/$currentUserId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        // 如果後端的 favorites 只回傳 article_id，這裡再用另一個 API 抓文章細節
        List<Map<String, dynamic>> fetched = [];
        for (var fav in data) {
          final articleRes =
              await http.get(Uri.parse('$apiBaseUrl/articles/${fav["article_id"]}'));
          if (articleRes.statusCode == 200) {
            final article = jsonDecode(articleRes.body);
            fetched.add({
              "id": article["article_id"],
              "title": article["title"],
              "date": article["published_time"] ?? "",
              "content": article["content"] ?? "",
            });
          }
        }

        setState(() {
          favoriteArticles = fetched;
          isLoading = false;
        });
      } else {
        throw Exception('取得收藏失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('讀取收藏失敗: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9EB79E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "收藏文章",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteArticles.isEmpty
              ? const Center(child: Text("目前沒有收藏的文章"))
              : ListView.builder(
                  itemCount: favoriteArticles.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final article = favoriteArticles[index];
                    return Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 80,
                            color: const Color(0xFF9EB79E),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article["title"] ?? "",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.bookmark,
                                        color: Color(0xFF9EB79E),
                                        size: 20,
                                      ),
                                      const Spacer(),
                                      Text(
                                        "發布時間：${article["date"] ?? ""}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF003366),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ArticleDetailPage(
                                                articleId: article["id"],
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          "查看詳情 >>",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }
}
