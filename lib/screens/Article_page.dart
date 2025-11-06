import 'package:flutter/material.dart';
import 'package:truthliesdetector/services/api_service.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:screenshot/screenshot.dart';
import 'package:truthliesdetector/themes/ball.dart';

class ArticleDetailPage extends StatefulWidget {
  static const String route = '/article';

  final int articleId; // ← 接收從 HomePage 傳來的 articleId

  const ArticleDetailPage({super.key, required this.articleId});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _showFab = true;

  Map<String, dynamic>? _articleData;
  bool _isLoading = true;
  final List<Map<String, String>> _comments = [];

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchArticleData();
  }

  Future<void> _fetchArticleData() async {
    try {
      final data = await ApiService.fetchArticleDetail(widget.articleId);
      setState(() {
        _articleData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 取得文章失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submitComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        _comments.add({
          'author': '匿名用戶',
          'content': _commentController.text,
        });
        _commentController.clear();
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_articleData == null) {
      return const Scaffold(
        body: Center(child: Text("找不到文章資料")),
      );
    }

    final double credibility = (_articleData!['reliability_score'] ?? 0.0).toDouble();
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
        title: const Text("文章詳情",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
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
                  // 📰 標題與可信度
                  Text(
                    _articleData!['title'] ?? '未命名文章',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: credibilityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          credibility > 0.7
                              ? "高可信度"
                              : (credibility > 0.4 ? "中等可信度" : "低可信度"),
                          style:
                              TextStyle(color: credibilityColor, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "發布時間：${_articleData!['published_time'] ?? '未知'}",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
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

          // 🔘 懸浮球
          if (_showFab)
            FloatingActionMenu(
              screenshotController: _screenshotController,
              onTap: (index) {},
              onClose: () => setState(() => _showFab = false),
            ),
          if (!_showFab)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () => setState(() => _showFab = true),
                backgroundColor: AppColors.primaryGreen,
                child: const Icon(Icons.apps, color: Colors.white),
              ),
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
            const Text("AI可信度分析",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text("可信度評分：${credibility.toStringAsFixed(2)}",
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(width: 4),
                Text("（滿分1分）",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
            Text(analysis,
                style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("用戶留言",
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepGreen)),
        const SizedBox(height: 8),
        ..._comments.map((c) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(c['author']!),
              subtitle: Text(c['content']!),
            )),
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
                  backgroundColor: AppColors.deepGreen),
              onPressed: _submitComment,
              child: const Text("發送", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}
