import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/article_page.dart';

// import 'package:truthliesdetector/themes/app_drawer.dart';

class HomePage extends StatefulWidget {
  static const route = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  final Color mainGreen = const Color(0xFF8BA88E);
  final Color bgGrey = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 移除 Scaffold 和 AppBar，讓 MainLayout 來處理它們。
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 搜尋框
        GestureDetector(
          onTap: () {
            // 點擊搜尋框的邏輯
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
                MaterialPageRoute(builder: (_) => const ArticleDetailPage()),
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
                        child: Text("國際合作擘劃永續未來：支持可持續發展的政策聲明",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "多家國際組織的共同聲明，為全球可持續發展的進程注入了強心針。它不僅發出了明確的政策信號，也為各國政府、企業和社會提供了行動指南。展望未來，這份聲明所倡議的政策若能得到有效落實，將不僅有助於應對氣候變遷和環境挑戰，更能促進建立一個更加公平、包容和具韌性的全球經濟體系。最終，實現可持續發展不僅僅是保護地球的責任，更是為...",
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
          height: 90,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRecommendList([
                {"title": "AI醫療與穿戴裝置", "count": "50篇"},
                {"title": "半導體ETF成為台股新寵", "count": "75篇"},
                {"title": "輝達推出新一代AI晶片", "count": "80篇"},
              ]),
              _buildRecommendList([
                {"title": "歐盟碳關稅對產業影響", "count": "30篇"},
                {"title": "ChatGPT-5發布會", "count": "40篇"},
                {"title": "台灣高鐵國旅優惠方案", "count": "65篇"},
              ]),
              _buildRecommendList([
                {"title": "能源轉型下的太陽能產業前景", "count": "20篇"},
                {"title": "智慧城市如何提升市民生活品質", "count": "15篇"},
                {"title": "永續生活風潮下的電動車市場", "count": "25篇"},
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
        _buildRankItem("台積電宣布在日本設立新廠", "半導體產業 · 3小時前", Colors.green),
        _buildRankItem("新冠疫情有專家強調應該進入新階段", "國際新聞 · 5小時前", Colors.red),
        _buildRankItem("台北將舉辦2026年運動會", "體育賽事 · 2天前", Colors.orange),
        _buildRankItem("氣候變遷論壇在倫敦舉行", "環保議題 · 1小時前", Colors.blue),
        _buildRankItem("台灣新創公司推出AI翻譯軟體", "科技發展 · 4天前", Colors.grey),
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
              MaterialPageRoute(builder: (_) => const ArticleDetailPage()),
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
  Widget _buildRankItem(String title, String subtitle, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArticleDetailPage()),
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
