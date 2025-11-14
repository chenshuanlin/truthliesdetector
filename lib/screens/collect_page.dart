import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:truthliesdetector/providers/user_provider.dart';
import 'package:truthliesdetector/screens/article_page.dart'; // ✅ 文章詳情頁

class CollectPage extends StatefulWidget {
  static const String route = '/collect';
  const CollectPage({super.key});

  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage> {
  List<Map<String, dynamic>> favoriteArticles = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteArticles();
  }

  /// ✅ 從後端抓取使用者收藏清單
  Future<void> _loadFavoriteArticles() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.userId;

      if (userId == null) {
        print("⚠️ 無法取得 userId，請確認使用者登入狀態");
        setState(() {
          isLoading = false;
          isError = true;
        });
        return;
      }

      // ✅ Android 模擬器請用 10.0.2.2
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/favorites/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          favoriteArticles = data
              .map(
                (item) => {
                  "article_id": item["article_id"],
                  "title": item["title"],
                  "media_name": item["media_name"] ?? "",
                  "url": item["source_link"] ?? "",
                  "date": item["favorited_at"] ?? "", // ✅ 修正欄位名
                  "score": item["reliability_score"]?.toString() ?? "N/A",
                },
              )
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 載入收藏失敗: $e");
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  /// ✅ 取消收藏 (DELETE)
  Future<void> _removeFavorite(int articleId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.userId;

      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("⚠️ 未登入狀態無法取消收藏")));
        return;
      }

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:5000/api/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"user_id": userId, "article_id": articleId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          favoriteArticles.removeWhere((a) => a["article_id"] == articleId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ 已移除收藏")));
      } else {
        throw Exception("刪除失敗 (HTTP ${response.statusCode})");
      }
    } catch (e) {
      print("❌ 移除收藏失敗: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ 無法移除收藏")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9EB79E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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

      /// ✅ 主體內容
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
          ? const Center(child: Text("載入收藏資料時發生錯誤 😢"))
          : favoriteArticles.isEmpty
          ? const Center(child: Text("目前沒有收藏的文章"))
          : ListView.builder(
              itemCount: favoriteArticles.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final article = favoriteArticles[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                      // 左側綠線
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
                              // 文章標題
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
                                  GestureDetector(
                                    onTap: () =>
                                        _removeFavorite(article["article_id"]),
                                    child: const Icon(
                                      Icons.bookmark_remove,
                                      color: Color(0xFF9EB79E),
                                      size: 22,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "收藏於：${article["date"] ?? ""}",
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
                                          builder: (context) => ArticleDetailPage(
                                            articleId:
                                                article["article_id"], // ✅ 正確傳遞
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
    );
  }
}
