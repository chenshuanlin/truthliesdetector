import 'package:flutter/material.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import '../models/article_model.dart';
import '../services/article_service.dart';

class ArticleDetailPage extends StatefulWidget {
  static const String route = '/article';

  final int articleId; // ✅ 必填文章 ID

  const ArticleDetailPage({super.key, required this.articleId});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late Future<Article> _futureArticle;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureArticle = ApiService.fetchArticleById(widget.articleId);
  }

  void _submitComment(List<Comment> comments) {
    if (_commentController.text.isNotEmpty) {
      final newComment = Comment(
        commentId: DateTime.now().millisecondsSinceEpoch, // 臨時 ID
        userId: 0, // 匿名
        articleId: widget.articleId,
        content: _commentController.text,
        userIdentity: "匿名",
        commentedAt: DateTime.now(),
      );
      setState(() {
        comments.add(newComment);
        _commentController.clear();
      });
      // TODO: 這裡可以再呼叫 API 發送評論
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.appBarGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("文章詳情",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
      ),
      body: FutureBuilder<Article>(
        future: _futureArticle,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("錯誤：${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("找不到文章"));
          }

          final article = snapshot.data!;
          final comments = article.comments;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(article),
                const SizedBox(height: 16),
                _buildAICard(article),
                const SizedBox(height: 16),
                Text(article.content,
                    style: const TextStyle(fontSize: 14, height: 1.5)),
                const SizedBox(height: 20),
                _buildRelatedNews(article),
                const SizedBox(height: 20),
                _buildCommentSection(comments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitle(Article article) {
    String credibilityText;
    Color credibilityColor;
    if (article.reliabilityScore > 70) {
      credibilityText = "高可信度";
      credibilityColor = AppColors.deepGreen;
    } else if (article.reliabilityScore > 40) {
      credibilityText = "中等可信度";
      credibilityColor = Colors.orange;
    } else {
      credibilityText = "低可信度";
      credibilityColor = AppColors.dangerRed;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(article.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: credibilityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                credibilityText,
                style: TextStyle(color: credibilityColor, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text("發布時間：${article.publishedTime.toString()}",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildAICard(Article article) {
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
                Text("可信度評分：${article.reliabilityScore}分",
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(width: 4),
                Text("（滿分100分）",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: article.reliabilityScore / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  article.reliabilityScore > 70
                      ? AppColors.deepGreen
                      : (article.reliabilityScore > 40
                      ? Colors.orange
                      : AppColors.dangerRed)),
            ),
            const SizedBox(height: 12),
            Text(article.aiAnalysis,
                style:
                const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedNews(Article article) {
    if (article.relatedNews.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreenBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("相關新聞",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepGreen)),
          const SizedBox(height: 12),
          ...article.relatedNews
              .map((news) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.article_outlined,
                    size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(news.relatedTitle,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.darkText)),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    // TODO: 打開相關新聞連結
                  },
                  child: const Icon(Icons.open_in_new,
                      size: 18, color: AppColors.deepGreen),
                ),
              ],
            ),
          ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildCommentSection(List<Comment> comments) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.lightGreenBG,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text("用戶互動區",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepGreen)),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              ...comments.map((comment) => _buildCommentItem(comment)).toList(),
              const Divider(),
              _buildCommentInputBox(comments),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.userGray,
            radius: 16,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.userIdentity,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(comment.content,
                    style:
                    const TextStyle(fontSize: 13, color: AppColors.darkText)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCommentInputBox(List<Comment> comments) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "留下您的評論...",
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  const BorderSide(color: AppColors.userGray, width: 1),
                ),
              ),
              onSubmitted: (_) => _submitComment(comments),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _submitComment(comments),
            child: const Text("發送", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
