import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // 篩選選擇
  String selectedConfidence = "";
  String selectedTime = "";
  String selectedCategory = "";
  TextEditingController keywordController = TextEditingController();

  // 導覽列狀態
  int _selectedIndex = 0;

  // 主綠色
  final Color mainGreen = const Color(0xFF9EB79E);

  // 動態文章列表
  List<Map<String, String>> articles = [];

  // 模擬後端搜尋
  Future<void> fetchArticles() async {
    List<Map<String, String>> result = [
      {
        "title": "「新冠肺炎特效藥」正式獲醫管署有効！",
        "subtitle": "某新藥治療效果提高87%，多國醫療團隊證實......",
        "credibility": "低可信度",
        "content":
        "某新藥治療效果據報提高87%，多國醫療團隊進行初步觀察，但尚未經過大規模臨床試驗或官方正式認證。",
        "source": "健康日報",
        "time": "3小時前",
      },
      {
        "title": "新冠肺炎特效藥研發進展：臨床試驗階段",
        "subtitle": "多種藥物進入第三階段臨床試驗，療效尚待確認......",
        "credibility": "高可信度",
        "content":
        "多種新冠肺炎治療藥物已進入第三階段臨床試驗，初步結果顯示部分藥物具有良好療效並且安全性可控。",
        "source": "醫學期刊",
        "time": "昨天",
      },
      {
        "title": "最新研究：新冠肺炎特效藥有效率分析",
        "subtitle": "數據顯示特效藥可減少30%住院率，但副作用問題......",
        "credibility": "中可信度",
        "content":
        "最新研究顯示，新冠肺炎特效藥可降低約30%的住院率，但部分患者仍可能出現副作用，包括噁心、頭痛與疲倦。",
        "source": "科學報告",
        "time": "2天前",
      },
    ];

    List<Map<String, String>> filtered = result.where((article) {
      bool matchKeyword = keywordController.text.isEmpty ||
          article["title"]!
              .toLowerCase()
              .contains(keywordController.text.toLowerCase());
      bool matchCredibility =
          selectedConfidence.isEmpty || article["credibility"] == selectedConfidence;
      bool matchCategory =
          selectedCategory.isEmpty || article["title"]!.contains(selectedCategory);
      bool matchTime = true;
      return matchKeyword && matchCredibility && matchCategory && matchTime;
    }).toList();

    setState(() {
      articles = filtered;
    });
  }

  // 可信度顏色
  Color getCredibilityColor(String level) {
    switch (level) {
      case "高可信度":
        return Colors.green;
      case "中可信度":
        return Colors.orange;
      case "低可信度":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 篩選按鈕組件
  Widget _buildFilterSection(
      String title, List<String> options, String selected, Function(String) onSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: options.map((option) {
              final bool isSelected = selected == option;
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                selectedColor: mainGreen.withOpacity(0.3),
                onSelected: (_) {
                  onSelected(option);
                  fetchArticles();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 文章卡片
  Widget _buildArticleCard(Map<String, String> article) {
    Color credColor = getCredibilityColor(article["credibility"] ?? "");
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article["title"] ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(article["subtitle"] ?? "",
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: credColor, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(article["credibility"] ?? "",
                      style: TextStyle(color: credColor, fontSize: 12)),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArticleDetailPage(article: article),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: credColor, width: 1.5),
                    ),
                    child: Icon(Icons.keyboard_arrow_down, color: credColor, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("${article["source"]}・${article["time"]}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Drawer 按鈕
  Widget _buildDrawerButton(String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: ListTile(
          title: Center(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ),
      ),
    );
  }

  // Bottom 導覽列按鈕
  Widget _buildBottomNavButton(IconData icon, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Drawer(
          backgroundColor: mainGreen,
          child: ListView(
            padding: const EdgeInsets.only(top: 40),
            children: [
              Container(
                color: mainGreen,
                height: 160,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  "lib/assets/logo1.png",
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              _buildDrawerButton("首頁"),
              _buildDrawerButton("最新消息"),
              _buildDrawerButton("新聞搜尋"),
              _buildDrawerButton("AI助手"),
              _buildDrawerButton("用戶資訊"),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: mainGreen,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Image.asset(
          "lib/assets/logo1.png",
          height: 80,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜尋框
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: keywordController,
                      decoration: const InputDecoration(
                        hintText: "搜尋關鍵字",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => fetchArticles(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterSection("可信度篩選", ["高可信度", "中可信度", "低可信度"], selectedConfidence,
                    (val) => setState(() => selectedConfidence = val)),
            _buildFilterSection("發布時間", ["今天", "本週", "本月"], selectedTime,
                    (val) => setState(() => selectedTime = val)),
            _buildFilterSection("主題類別",
                ["醫療", "研究", "新聞", "政策", "國際", "科技"], selectedCategory,
                    (val) => setState(() => selectedCategory = val)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("搜尋結果",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text("共找到 ${articles.length} 篇報導",
                    style: const TextStyle(color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  return _buildArticleCard(articles[index]);
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: mainGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavButton(Icons.home, "首頁"),
                _buildBottomNavButton(Icons.access_time, "發現"),
                const SizedBox(width: 100),
                _buildBottomNavButton(Icons.search, "搜尋"),
                _buildBottomNavButton(Icons.person, "我的"),
              ],
            ),
          ),
          // 中間 logo
          Positioned(
            top: -25,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {}, 
                child: Image.asset(
                  "lib/assets/logo2.png",
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 新聞完整頁
class ArticleDetailPage extends StatelessWidget {
  final Map<String, String> article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9EB79E),
        title: Text(article["title"] ?? "新聞詳情"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article["title"] ?? "",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("${article["source"]}・${article["time"]}",
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Text(article["content"] ?? "",
                  style: const TextStyle(fontSize: 16, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

