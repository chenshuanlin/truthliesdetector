import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/article_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  static const route = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final Color mainGreen = const Color(0xFF8BA88E);

  // API 位置
  final String apiBaseUrl = 'http://10.0.2.2:8000';

  late Future<List<dynamic>> todayArticles;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    todayArticles = fetchTodayArticles();
  }

  Future<List<dynamic>> fetchTodayArticles() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/articles?limit=3'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('無法取得文章資料');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 搜尋框
        GestureDetector(
          onTap: () {
            print('Search bar tapped!');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 8),
                Text("搜尋文章、標籤或主題",
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 熱門趨勢
        const Text("熱門趨勢",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ArticleDetailPage(articleId: 1)), // 範例 ID
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: mainGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("#1",
                            style: TextStyle(color: mainGreen, fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text("全球經濟議題",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "支持可持續發展的政策，多家國際組織共同發表聲明。",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 為您推薦 + Tab
        const Text("為您推薦",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          labelColor: mainGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.transparent,
          labelStyle:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: "熱門"),
            Tab(text: "最新"),
            Tab(text: "專題"),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRecommendList([
                {"title": "熱門健康趨勢", "count": "50篇"},
                {"title": "熱門投資策略", "count": "75篇"},
              ]),
              _buildRecommendList([
                {"title": "最新環保新聞", "count": "30篇"},
                {"title": "最新AI技術", "count": "40篇"},
              ]),
              _buildRecommendList([
                {"title": "專題：能源轉型", "count": "20篇"},
                {"title": "專題：智慧城市", "count": "15篇"},
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 今日排行榜
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("今日排行榜",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: Text("更多", style: TextStyle(color: mainGreen)),
            )
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: todayArticles,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('取得排行榜失敗: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('目前沒有文章'));
            } else {
              final articles = snapshot.data!;
              return Column(
                children: articles.asMap().entries.map((entry) {
                  int index = entry.key;
                  var article = entry.value;
                  Color color;
                  // 根據分類選顏色示例
                  switch ((article['category'] ?? '').toString().toLowerCase()) {
                    case '國際新聞':
                      color = Colors.red;
                      break;
                    case '半導體產業':
                      color = Colors.green;
                      break;
                    case '體育賽事':
                      color = Colors.orange;
                      break;
                    default:
                      color = Colors.blueGrey;
                  }
                  return _buildRankItem(
                    article['title'] ?? '無標題',
                    "${article['category'] ?? '其他'} · ${article['published_time'] ?? ''}",
                    color,
                    article['article_id'],
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  /// 推薦卡片清單
  Widget _buildRecommendList(List<Map<String, String>> items) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ArticleDetailPage(articleId: index + 1)), // 範例 ID
            );
          },
          child: _buildRecommendCard(
              items[index]["title"]!, items[index]["count"]!),
        );
      },
    );
  }

  /// 單一卡片
  Widget _buildRecommendCard(String title, String count) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const Spacer(),
          Text(count, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  /// 排行榜項目
  Widget _buildRankItem(
      String title, String subtitle, Color color, int articleId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ArticleDetailPage(articleId: articleId)),
          );
        },
        leading: Container(
          width: 14,
          height: 14,
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.bookmark_border),
      ),
    );
  }
}
