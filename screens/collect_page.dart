import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/favorite_model.dart';
import '../services/favorite_service.dart';
import 'article_page.dart'; // 文章詳情頁

// 新增 DTO：收藏 + 文章資料
class FavoriteArticle {
  final int articleId;
  final String title;
  final DateTime favoritedAt;

  FavoriteArticle({
    required this.articleId,
    required this.title,
    required this.favoritedAt,
  });
}

class CollectPage extends StatefulWidget {
  static const String route = '/collect';
  const CollectPage({super.key});

  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage> {
  List<FavoriteArticle> favoriteArticles = [];
  bool isLoading = true;

  // 這裡請換成登入後的實際 userId
  final int currentUserId = 1;

  late String apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _setupApiUrl();
    _loadFavoriteArticles();
  }

  void _setupApiUrl() {
    if (kIsWeb) {
      apiBaseUrl = 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      apiBaseUrl = 'http://10.0.2.2:8000'; // 模擬器
      // apiBaseUrl = 'http://192.168.0.111:8000'; // 實機測試時取消註解
    } else {
      apiBaseUrl = 'http://localhost:8000';
    }
  }

  Future<void> _loadFavoriteArticles() async {
    setState(() => isLoading = true);
    try {
      final favorites = await FavoriteService.fetchUserFavorites(currentUserId);

      List<FavoriteArticle> fetched = [];
      for (var fav in favorites) {
        // 取得文章資料
        final article = await FavoriteService.fetchArticleById(fav.articleId);
        if (article != null) {
          fetched.add(FavoriteArticle(
            articleId: article['article_id'],
            title: article['title'] ?? '無標題',
            favoritedAt: fav.favoritedAt,
          ));
        }
      }

      setState(() {
        favoriteArticles = fetched;
        isLoading = false;
      });
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
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          article.title,
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
                              "收藏時間：${article.favoritedAt.toLocal()}",
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
                                            articleId:
                                            article.articleId),
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
