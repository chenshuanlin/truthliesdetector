import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:truthliesdetector/screens/article_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  static const String route = "/search";

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String selectedConfidence = "";
  String selectedTime = "";
  String selectedCategory = "";
  TextEditingController keywordController = TextEditingController();

  final Color mainGreen = const Color(0xFF9EB79E);
  bool showMore = false;
  bool isLoading = false;
  String errorMessage = "";
  List<Map<String, dynamic>> articles = [];

  Timer? _throttle; // ⭐ 節流器（Throttle）

  final List<String> allCategories = [
    "科技",
    "政治",
    "健康",
    "教育",
    "娛樂",
    "體育",
    "設計",
    "旅遊",
    "生活",
    "商業",
    "金融",
    "環境",
    "國際",
    "藝術",
    "社會",
    "研究",
    "美食",
    "影視",
  ];

  // ⭐ 節流版搜尋（500ms 內只允許一次）
  void _triggerSearch() {
    if (_throttle?.isActive ?? false) return; // 已在節流中 → 不執行
    _throttle = Timer(const Duration(milliseconds: 500), () {
      fetchArticles();
    });
  }

  // 從 Flask 撈資料
  Future<void> fetchArticles() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final uri = Uri.http("10.0.2.2:5000", "/api/articles/search", {
        "keyword": keywordController.text,
        "confidence": selectedConfidence,
        "category": selectedCategory,
        "time_filter": selectedTime,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          articles = List<Map<String, dynamic>>.from(data);
        });
      } else {
        setState(() {
          errorMessage = "伺服器回傳錯誤 (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "❌ 無法連線到伺服器：$e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 可信度顏色
  Color getCredibilityColor(String level) {
    switch (level) {
      case "極高可信度":
        return Colors.green[800]!;
      case "高可信度":
        return Colors.green;
      case "中可信度":
        return Colors.orange;
      case "低可信度":
        return Colors.red;
      case "極低可信度":
        return Colors.red[800]!;
      case "不可信":
        return Colors.black54;
      default:
        return Colors.grey;
    }
  }

  // 篩選按鈕組件
  Widget _buildFilterSection(
    String title,
    List<String> options,
    String selected,
    Function(String) onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: options.map((option) {
              final bool isSelected = selected == option;
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                selectedColor: mainGreen.withOpacity(0.3),
                onSelected: (_) {
                  setState(() {
                    if (isSelected) {
                      onSelected("");
                    } else {
                      onSelected(option);
                    }
                  });
                  _triggerSearch(); // ⭐ 改成節流搜尋
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 文章卡片
  Widget _buildArticleCard(Map<String, dynamic> article) {
    final cred = article["credibility_label"] ?? "未知";
    final credColor = getCredibilityColor(cred);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailPage(articleId: article["id"] ?? 0),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article["title"] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: credColor, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cred,
                      style: TextStyle(color: credColor, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "${article["media_name"] ?? "未知"}・${article["published_time"] ?? ""}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
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
    _triggerSearch(); // ⭐ init 也走節流，避免瞬間重建觸發多次 API
  }

  @override
  Widget build(BuildContext context) {
    final displayedCategories = showMore
        ? allCategories
        : allCategories.take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 搜尋框
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
                      onSubmitted: (_) => _triggerSearch(), // ⭐ 使用節流搜尋
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 篩選區塊
            _buildFilterSection(
              "可信度篩選",
              ["極高可信度", "高可信度", "中可信度", "低可信度", "極低可信度", "不可信"],
              selectedConfidence,
              (val) => selectedConfidence = val,
            ),
            _buildFilterSection(
              "發布時間",
              ["今天", "本週", "本月"],
              selectedTime,
              (val) => selectedTime = val,
            ),
            _buildFilterSection(
              "主題類別",
              displayedCategories,
              selectedCategory,
              (val) => selectedCategory = val,
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => showMore = !showMore),
                icon: Icon(showMore ? Icons.expand_less : Icons.expand_more),
                label: Text(showMore ? "收起" : "更多"),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  "搜尋結果",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  "共找到 ${articles.length} 篇報導",
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                  ? Center(child: Text(errorMessage))
                  : articles.isEmpty
                  ? const Center(child: Text("目前沒有符合的文章"))
                  : ListView.builder(
                      itemCount: articles.length,
                      itemBuilder: (context, index) =>
                          _buildArticleCard(articles[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
