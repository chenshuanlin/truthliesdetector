import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:truthliesdetector/services/api_service.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:screenshot/screenshot.dart';
import 'package:truthliesdetector/themes/ball.dart';
import 'package:provider/provider.dart';
import 'package:truthliesdetector/providers/user_provider.dart';

class ArticleDetailPage extends StatefulWidget {
  final int articleId;

  const ArticleDetailPage({super.key, required this.articleId});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _showFab = true;

  Map<String, dynamic>? _articleData;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print("📰 開啟文章詳情頁，articleId = ${widget.articleId}");

    _fetchArticleData();
    _fetchComments();

    // ⭐⭐⭐ 自動新增瀏覽紀錄 ⭐⭐⭐
    _addViewHistory();
  }

  // ============================================================
  // ⭐ 新增瀏覽紀錄 POST /api/search-logs
  // ============================================================
  Future<void> _addViewHistory() async {
    try {
      final api = ApiService.getInstance();
      final baseUrl = api.baseUrl;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;

      if (userId == null) {
        print("⚠ 無法記錄瀏覽（尚未登入）");
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/search-logs'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"user_id": userId, "article_id": widget.articleId}),
      );

      print("📌 已送出瀏覽紀錄 user=$userId article=${widget.articleId}");
      print("📌 回應：${response.body}");
    } catch (e) {
      print("❌ 新增瀏覽紀錄失敗: $e");
    }
  }

  // ============================================================
  // 📰 抓文章資料
  // ============================================================
  Future<void> _fetchArticleData() async {
    try {
      final api = ApiService.getInstance();
      final baseUrl = api.baseUrl;

      final response = await http
          .get(Uri.parse('$baseUrl/api/articles/${widget.articleId}'))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        setState(() {
          _articleData = data;
        });

        await _fetchComments();
      } else {
        print('⚠️ 無法載入文章 (${response.statusCode})');
      }
    } catch (e) {
      print('❌ 取得文章失敗: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // 💬 抓留言
  // ============================================================
  Future<void> _fetchComments() async {
    try {
      final api = ApiService.getInstance();
      final baseUrl = api.baseUrl;

      final response = await http
          .get(Uri.parse('$baseUrl/api/articles/${widget.articleId}/comments'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _comments
            ..clear()
            ..addAll(data.map((e) => Map<String, dynamic>.from(e)));
        });
      } else {
        print('⚠️ 無法載入留言: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 載入留言錯誤: $e');
    }
  }

  // ============================================================
  // ✏ 新增留言
  // ============================================================
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      final api = ApiService.getInstance();
      final baseUrl = api.baseUrl;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;
      final username = userProvider.username ?? "匿名用戶";

      final response = await http.post(
        Uri.parse('$baseUrl/api/articles/${widget.articleId}/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "author": username,
          "user_id": userId,
          "content": content,
        }),
      );

      if (response.statusCode == 201) {
        print('✅ 留言新增成功');
        _commentController.clear();
        await _fetchComments();
      } else {
        print('⚠️ 留言失敗: ${response.body}');
      }
    } catch (e) {
      print('❌ 發送留言錯誤: $e');
    }
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_articleData == null) {
      return const Scaffold(body: Center(child: Text("找不到文章資料")));
    }

    final double credibility = (_articleData!['reliability_score'] ?? 0.0)
        .toDouble();
    final Color credibilityColor = credibility > 0.7
        ? AppColors.deepGreen
        : (credibility > 0.4 ? Colors.orange : AppColors.dangerRed);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "文章詳情",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Screenshot(
            controller: _screenshotController,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 標題
                  Text(
                    _articleData!['title'] ?? '未命名文章',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: credibilityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          credibility > 0.7
                              ? "高可信度"
                              : (credibility > 0.4 ? "中等可信度" : "低可信度"),
                          style: TextStyle(
                            color: credibilityColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "發布時間：${_articleData!['published_time'] ?? '未知'}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _buildAICard(credibility, _articleData!['ai_analysis'] ?? ''),

                  const SizedBox(height: 16),
                  Text(
                    _articleData!['content'] ?? '暫無內容',
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),

                  const SizedBox(height: 20),
                  _buildCommentSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          /// 懸浮球
          if (_showFab)
            FloatingActionMenu(
              screenshotController: _screenshotController,
              onTap: (index) {},
              onClose: () => setState(() => _showFab = false),
            ),
        ],
      ),
    );
  }

  Widget _buildAICard(double credibility, String analysis) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AI可信度分析",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "可信度評分：${credibility.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(width: 4),
                Text(
                  "（滿分1分）",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: credibility,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                credibility > 0.7
                    ? AppColors.deepGreen
                    : (credibility > 0.4 ? Colors.orange : AppColors.dangerRed),
              ),
            ),
            const SizedBox(height: 12),
            Text(analysis, style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "用戶留言",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.deepGreen,
          ),
        ),
        const SizedBox(height: 8),

        if (_comments.isEmpty)
          const Text("暫無留言", style: TextStyle(color: Colors.grey))
        else
          ..._comments.map(
            (c) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(c['author'] ?? '匿名用戶'),
              subtitle: Text(c['content'] ?? ''),
              trailing: Text(
                c['time'] ?? '',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),

        const Divider(),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "留下您的評論...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepGreen,
              ),
              onPressed: _submitComment,
              child: const Text("發送", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}
