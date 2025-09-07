import 'package:flutter/material.dart';
import 'package:truthliesdetector/themes/app_colors.dart'; // 假設你的 AppColors 在這裡

// 這裡只保留 Article 和 Comment 類別，因為它們是 ArticleDetailPage 獨有的資料模型
// 如果你的專案中有獨立的資料模型檔案，你也可以將它們移過去。

/// 文章資料模型
class Article {
  final String title;
  final String publishDate;
  final int credibilityScore;
  final String aiAnalysis;
  final String content;
  final List<String> similarNews;

  Article({
    required this.title,
    required this.publishDate,
    required this.credibilityScore,
    required this.aiAnalysis,
    required this.content,
    required this.similarNews,
  });
}

/// 評論資料模型
class Comment {
  final String authorName;
  final String content;
  final bool isExpert;

  Comment({
    required this.authorName,
    required this.content,
    this.isExpert = false,
  });
}

class ArticleDetailPage extends StatefulWidget {
  static const String route = '/article';

  const ArticleDetailPage({super.key});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final Article _article = Article(
    title: "新冠疫苗含有微型晶片追蹤人體活動?",
    publishDate: "2025-05-20 08:30",
    credibilityScore: 15,
    aiAnalysis: "依據多項權威資料判斷，該說法屬於錯誤訊息，可信度極低。所謂“疫苗含有微型晶片”，缺乏任何科學依據，專家一致認為這是典型的謠言訊息。",
    content: "【本報訊】\n\n近期，網傳謠言稱新冠疫苗含有微型晶片可以追蹤人體活動，甚至聲稱疫苗接種卡是一種國際監控工具。...\n\n相關調查顯示，疫苗晶片說法最早出現在部分海外社群媒體，經過轉發和加工，迅速傳入國內，引發恐慌。...\n\n目前國內《疫苗管理法》《傳染病防治法》等均對疫苗管理有明確規範。醫學界強調，接種新冠疫苗的主要目的是預防感染和重症...",
    similarNews: [
      "WHO：COVID-19疫苗不含追蹤晶片，此為謠言",
      "台灣疾管署：疫苗成分公開透明，無追蹤裝置",
      "科學家解釋：疫苗微晶片說法在技術上不可能實現"
    ],
  );

  final List<Comment> _comments = [
    Comment(
      authorName: "李醫師（流行病學專家）",
      content: "疫苗不可能植入晶片，針頭直徑僅0.25~0.5mm，現有晶片技術無法藏於疫苗中且人體無感覺。",
      isExpert: true,
    ),
    Comment(
      authorName: "張小明",
      content: "感謝澄清，我差點被親戚帶偏，現在可以安心接種疫苗了。",
    ),
  ];

  final TextEditingController _commentController = TextEditingController();

  void _submitComment() {
    if (_commentController.text.isNotEmpty) {
      final newComment = Comment(
        authorName: "匿名用戶",
        content: _commentController.text,
      );
      setState(() {
        _comments.add(newComment);
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.appBarGreen,
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
        actions: [
          IconButton(
            icon: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.error_outline, color: Colors.white, size: 20),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _buildReportDialog(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {
              // TODO: 收藏功能
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 16),
                  _buildAICard(),
                  const SizedBox(height: 16),
                  _buildArticleContent(),
                  const SizedBox(height: 20),
                  _buildSimilarNews(),
                  const SizedBox(height: 20),
                  _buildCommentSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    String credibilityText;
    Color credibilityColor;
    if (_article.credibilityScore > 70) {
      credibilityText = "高可信度";
      credibilityColor = AppColors.deepGreen;
    } else if (_article.credibilityScore > 40) {
      credibilityText = "中等可信度";
      credibilityColor = Colors.orange;
    } else {
      credibilityText = "低可信度";
      credibilityColor = AppColors.dangerRed;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _article.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
            Text(
              "發布時間：${_article.publishDate}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAICard() {
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
                Text("可信度評分：${_article.credibilityScore}分",
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(width: 4),
                Text("（滿分100分）",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _article.credibilityScore / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _article.credibilityScore > 70
                      ? AppColors.deepGreen
                      : (_article.credibilityScore > 40 ? Colors.orange : AppColors.dangerRed)),
            ),
            const SizedBox(height: 12),
            Text(
              _article.aiAnalysis,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleContent() {
    return Text(
      _article.content,
      style: const TextStyle(fontSize: 14, height: 1.5),
    );
  }

  Widget _buildSimilarNews() {
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
          const Text("相似新聞比對",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepGreen)),
          const SizedBox(height: 12),
          ..._article.similarNews.map((text) => _buildFactItem(text)).toList(),
        ],
      ),
    );
  }

  Widget _buildFactItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.article_outlined, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style:
                const TextStyle(fontSize: 13, color: AppColors.darkText)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.labelGreenBG,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("官方發布",
                style: TextStyle(fontSize: 11, color: AppColors.deepGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
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
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              ..._comments.map((comment) => _buildCommentItem(comment)).toList(),
              const Divider(),
              _buildCommentInputBox(),
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
            backgroundColor: comment.isExpert ? AppColors.deepGreen : AppColors.userGray,
            radius: 16,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.authorName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: comment.isExpert ? AppColors.deepGreen : Colors.black87)),
                const SizedBox(height: 4),
                Text(comment.content,
                    style: const TextStyle(fontSize: 13, color: AppColors.darkText)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCommentInputBox() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: "留下您的評論...",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.userGray, width: 1),
                    ),
                  ),
                  onSubmitted: (_) => _submitComment(),
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
                onPressed: _submitComment,
                child: const Text("發送", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.arrow_upward, color: AppColors.deepGreen, size: 20),
              SizedBox(width: 8),
              Icon(Icons.arrow_downward, color: Colors.grey, size: 20),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReportDialog(BuildContext context) {
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
                const Text("疑慮內容回報",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
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
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
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
                onPressed: () => Navigator.pop(context),
                child: const Text("舉報", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
