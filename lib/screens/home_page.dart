import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/Article_page.dart';
import 'package:truthliesdetector/services/api_service.dart';

class HomePage extends StatefulWidget {
  static const route = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  TabController? _tabController;

  final Color mainGreen = const Color(0xFF8BA88E);

  List<dynamic> trendingArticles = [];
  Map<String, List<dynamic>> categorizedRecommendations = {};
  List<dynamic> rankingArticles = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final api = ApiService.getInstance();
      final trending = await api.fetchTrendingArticles();
      final recommend = await api.fetchRecommendations();
      final ranking = await api.fetchRanking();

      ranking.sort(
        (a, b) => (b['reliability_score'] ?? 0)
            .compareTo(a['reliability_score'] ?? 0),
      );

      Map<String, List<dynamic>> grouped = {};
      for (var article in recommend) {
        String cat = article['category'] ?? '其他';
        grouped.putIfAbsent(cat, () => []).add(article);
      }

      _tabController?.dispose();
      _tabController = TabController(
        length: grouped.keys.isNotEmpty ? grouped.keys.length : 1,
        vsync: this,
      );

      setState(() {
        trendingArticles = trending;
        categorizedRecommendations = grouped;
        rankingArticles = ranking;
        isLoading = false;
      });
    } catch (e) {
      print("❌ 無法從 Flask 抓資料: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 🔥🔥 搜尋列已完全移除 🔥🔥

        const Text(
          "熱門趨勢",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        trendingArticles.isNotEmpty
            ? _buildTrendingCard(trendingArticles[0])
            : const Text("目前沒有熱門文章"),

        const SizedBox(height: 24),
        const Text(
          "為您推薦",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (categorizedRecommendations.isNotEmpty &&
            _tabController != null &&
            _tabController!.length == categorizedRecommendations.keys.length)
          Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: mainGreen,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                tabs: categorizedRecommendations.keys
                    .map((cat) => Tab(text: cat))
                    .toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: TabBarView(
                  controller: _tabController,
                  children: categorizedRecommendations.keys
                      .map(
                        (cat) => _buildRecommendList(
                          categorizedRecommendations[cat] ?? [],
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          )
        else
          const Text("目前沒有推薦資料"),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "今日排行榜",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            
          ],
        ),

        const SizedBox(height: 12),
        rankingArticles.isNotEmpty
            ? Column(
                children: rankingArticles.map((a) {
                  return _buildRankItem(
                    a['title'] ?? '未命名文章',
                    "${a['category'] ?? '未知'} · ${a['reliability_score'] ?? 0} 分",
                    mainGreen,
                    a['id'],
                  );
                }).toList(),
              )
            : const Text("目前沒有排行資料"),
      ],
    );
  }

  // ------------------ 下方元件保持不動 ------------------

  Widget _buildTrendingCard(Map<String, dynamic> article) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ArticleDetailPage(articleId: article['id'] ?? 0),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article['title'] ?? '未命名文章',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                article['summary'] ?? '暫無摘要內容',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendList(List<dynamic> articles) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: articles.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final a = articles[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ArticleDetailPage(articleId: a['id'] ?? 0),
              ),
            );
          },
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a['title'] ?? '未命名文章',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "可信度分數：${a['reliability_score'] ?? 'N/A'}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankItem(
    String title,
    String subtitle,
    Color color,
    int? articleId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ArticleDetailPage(articleId: articleId ?? 0),
            ),
          );
        },
        leading: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle:
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
