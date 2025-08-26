import 'package:flutter/material.dart';
import 'Article_page.dart'; // ✅ 文章細節頁面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  final Color mainGreen = const Color(0xFF8BA88E);
  final Color bgGrey = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,

      // ✅ 加上 Drawer
      drawer: _buildDrawer(),

      appBar: AppBar(
        backgroundColor: mainGreen,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // 打開 Drawer
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔍 搜尋框
          Container(
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

          const SizedBox(height: 24),

          // 🔥 熱門趨勢
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
                              style:
                              TextStyle(color: mainGreen, fontSize: 14)),
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

          // 🎯 為您推薦 + Tab
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

          // 🏆 今日排行榜
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
        ],
      ),

      // ⬇️ 自訂導覽列
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  /// 側邊 Drawer
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: mainGreen,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LOGO
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      "logo.png", // ✅ 你的 logo 圖片
                      height: 60,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 功能選單
              _buildDrawerItem(Icons.home, "首頁"),
              _buildDrawerItem(Icons.fiber_new, "最新消息"),
              _buildDrawerItem(Icons.search, "新聞搜尋"),
              _buildDrawerItem(Icons.smart_toy, "AI助手"),
              _buildDrawerItem(Icons.person, "用戶資訊"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context); // 點擊後關閉 Drawer
      },
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

/// ⬇️ 自訂導覽列 Widget
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color mainGreen = const Color(0xFF8BA88E);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: mainGreen,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 左右四個選項
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "首頁", 0, mainGreen),
              _buildNavItem(Icons.access_time, "發現", 1, mainGreen),
              const SizedBox(width: 60), // 中間空出位置
              _buildNavItem(Icons.search, "搜尋", 3, mainGreen),
              _buildNavItem(Icons.person, "我的", 4, mainGreen),
            ],
          ),

          // 中間凸起的圓形按鈕
          Positioned(
            top: -25,
            left: MediaQuery.of(context).size.width / 2 - 45,
            child: GestureDetector(
              onTap: () => onTap(2), // index = 2
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: mainGreen, width: 4),
                ),
                child: Center(
                  child: Icon(Icons.gpp_maybe, color: mainGreen, size: 40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color mainGreen) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
