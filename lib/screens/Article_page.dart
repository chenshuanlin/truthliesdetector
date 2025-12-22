import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:truthliesdetector/services/api_service.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:truthliesdetector/providers/user_provider.dart';
import 'package:screenshot/screenshot.dart';

class ArticleDetailPage extends StatefulWidget {
  final int articleId;

  const ArticleDetailPage({super.key, required this.articleId});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();

  Map<String, dynamic>? _articleData;
  bool _isLoading = true;
  final List<Map<String, dynamic>> _comments = [];

  // ⭐ 新增：收藏狀態
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _fetchArticleData();
    _fetchComments();
    _addViewHistory();
    _checkFavoriteStatus(); // ⭐ 檢查收藏狀態
  }

  // ----------------------------
  // ⭐ 檢查是否已收藏
  // ----------------------------
  Future<void> _checkFavoriteStatus() async {
    try {
      final api = ApiService.getInstance();
      final baseUrl = api.baseUrl;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites/$userId'),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          _isFavorited = data.any(
            (item) => item["article_id"] == widget.articleId,
          );
        });
      }
    } catch (e) {
      print("❌ 讀取收藏狀態失敗: $e");
    }
  }

  // ----------------------------
  // ⭐ 新增/取消收藏
  // ----------------------------
  Future<void> _toggleFavorite() async {
    try {
      final api = ApiService.getInstance();
      final baseUrl = api.baseUrl;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;

      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("請先登入才能收藏")));
        return;
      }

      if (_isFavorited) {
        // ---- 取消收藏 ----
        final response = await http.delete(
          Uri.parse('$baseUrl/api/favorites'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "user_id": userId,
            "article_id": widget.articleId,
          }),
        );

        if (response.statusCode == 200) {
          setState(() => _isFavorited = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("已取消收藏")));
        }
      } else {
        // ---- 新增收藏 ----
        final response = await http.post(
          Uri.parse('$baseUrl/api/favorites'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "user_id": userId,
            "article_id": widget.articleId,
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 409) {
          setState(() => _isFavorited = true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("已加入收藏")));
        }
      }
    } catch (e) {
      print("❌ 收藏操作錯誤: $e");
    }
  }

  // ----------------------------
  // 新增瀏覽紀錄
  // ----------------------------
  Future<void> _addViewHistory() async {
    try {
      final api = ApiService.getInstance();
      final baseUrl = api.baseUrl;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;
      if (userId == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/api/search-logs'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"user_id": userId, "article_id": widget.articleId}),
      );
      print("📌 回應瀏覽紀錄：${response.body}");
    } catch (e) {
      print("❌ 新增瀏覽紀錄失敗: $e");
    }
  }

  // ----------------------------
  // 取得文章資料
  // ----------------------------
  Future<void> _fetchArticleData() async {
    try {
      final api = ApiService.getInstance();
      final baseUrl = api.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/articles/${widget.articleId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() => _articleData = data);
      } else {
        print("⚠️ 無法載入文章");
      }
    } catch (e) {
      print("❌ 取得文章失敗: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ----------------------------
  // 取得留言
  // ----------------------------
  Future<void> _fetchComments() async {
    try {
      final api = ApiService.getInstance();
      final baseUrl = api.baseUrl;

      final response = await http.get(
        Uri.parse('$baseUrl/api/articles/${widget.articleId}/comments'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          _comments
            ..clear()
            ..addAll(
              (data as List).map((e) => Map<String, dynamic>.from(e)).toList(),
            );
        });
      } else {
        print('⚠️ 無法載入留言: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 載入留言失敗: $e');
    }
  }

  // ----------------------------
  // 新增留言
  // ----------------------------
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
        _commentController.clear();
        await _fetchComments();
      } else {
        print("⚠️ 留言失敗: ${response.body}");
      }
    } catch (e) {
      print("❌ 發送留言錯誤: $e");
    }
  }

  // ----------------------------
  // 舉報文章
  // ----------------------------
  Future<void> _submitReport(String reason) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("請先登入才能舉報文章")));
      return;
    }

    try {
      final api = "${ApiService.getInstance().baseUrl}/api/reports";
      final response = await http.post(
        Uri.parse(api),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "user_id": userId,
          "article_id": widget.articleId,
          "reason": reason,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['ok'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("舉報成功")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("舉報失敗：${data['error'] ?? '未知錯誤'}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("舉報失敗：$e")));
    }
  }

  // ----------------------------
  // 舉報 Dialog
  // ----------------------------
  Widget _buildReportDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.appBarGreen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "疑慮內容回報",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "請簡要說明您對這篇文章的疑慮，例如：\n• 不實資訊\n• 不當言論\n• 垃圾訊息等",
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reportController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "請說明舉報理由...",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dangerRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final reason = _reportController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("請輸入舉報理由")));
                    return;
                  }
                  await _submitReport(reason);
                  _reportController.clear();
                  Navigator.pop(context);
                },
                child: const Text("舉報", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_articleData == null) {
      return const Scaffold(body: Center(child: Text("找不到文章資料")));
    }

    final credibility = (_articleData!['reliability_score'] ?? 0.0).toDouble();
    final credibilityColor = credibility > 3.0
        ? AppColors.deepGreen
        : (credibility > 2.0 ? Colors.orange : AppColors.dangerRed);

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

        // ⭐⭐ 這裡新增「收藏按鈕」，其他全部不動 ⭐⭐
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.report, color: Colors.white),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _buildReportDialog(),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文章標題
            Text(
              _articleData!['title'] ?? '未命名文章',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    credibility > 3.0
                        ? "高可信度"
                        : (credibility > 2.0 ? "中等可信度" : "低可信度"),
                    style: TextStyle(color: credibilityColor, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "發布時間：${_articleData!['published_time'] ?? '未知'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  "（0-5分）",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ⭐ 修正後的進度條
            LinearProgressIndicator(
              value: (credibility / 5).clamp(0.0, 1.0), // 0-5 → 0-1
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                credibility > 3.0
                    ? AppColors.deepGreen
                    : (credibility > 2.0 ? Colors.orange : AppColors.dangerRed),
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
              leading: CircleAvatar(
                backgroundColor:
                    (c['author'] != null &&
                        c['author'].toString().contains('專家'))
                    ? Colors.lightBlue
                    : null, // ← 非專家完全不設定顏色（使用預設）
                child: const Icon(Icons.person, color: Colors.white),
              ),
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
