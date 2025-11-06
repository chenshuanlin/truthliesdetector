import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:truthliesdetector/providers/user_provider.dart';
import 'package:truthliesdetector/screens/article_page.dart';

class HistoryPage extends StatefulWidget {
  static const String route = '/history';
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> viewHistory = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _loadViewHistory();
  }

  Future<void> _loadViewHistory() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;

      if (userId == null) {
        setState(() {
          isLoading = false;
          isError = true;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/history/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          viewHistory = data.map((item) {
            return {
              "article_id": item["article_id"],
              "title": item["title"],
              "url": item["source_link"],
              "date": item["last_viewed_at"], // ✅ 後端傳這個欄位
              "score": item["reliability_score"],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("❌ 載入瀏覽紀錄失敗: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("載入瀏覽資料失敗，請稍後再試")));
      }
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9EB79E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "瀏覽歷史",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
          ? const Center(child: Text("載入瀏覽資料時發生錯誤"))
          : viewHistory.isEmpty
          ? const Center(child: Text("目前沒有瀏覽紀錄"))
          : RefreshIndicator(
              onRefresh: _loadViewHistory,
              child: ListView.builder(
                itemCount: viewHistory.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final article = viewHistory[index];
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
                                    Text(
                                      "瀏覽時間：${article["date"] ?? ""}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1A3D7A),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "可信度：${article["score"] ?? '未知'}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ArticleDetailPage(
                                                articleId:
                                                    article["article_id"],
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
            ),
    );
  }
}
