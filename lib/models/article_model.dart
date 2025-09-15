// models/article_model.dart

class RelatedNews {
  final int relatedId;
  final String relatedTitle;
  final String relatedLink;

  RelatedNews({
    required this.relatedId,
    required this.relatedTitle,
    required this.relatedLink,
  });

  factory RelatedNews.fromJson(Map<String, dynamic> json) {
    return RelatedNews(
      relatedId: json['related_id'],
      relatedTitle: json['related_title'],
      relatedLink: json['related_link'],
    );
  }
}

class Comment {
  final int commentId;       // 對應 comment_id
  final int userId;          // 對應 user_id
  final int articleId;       // 對應 article_id
  final String content;      // 對應 content
  final String userIdentity; // 對應 user_identity
  final DateTime commentedAt; // 對應 commented_at

  Comment({
    required this.commentId,
    required this.userId,
    required this.articleId,
    required this.content,
    required this.userIdentity,
    required this.commentedAt,
  });

  // 從 JSON 建立 Comment
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'],
      userId: json['user_id'],
      articleId: json['article_id'],
      content: json['content'],
      userIdentity: json['user_identity'],
      commentedAt: DateTime.parse(json['commented_at']),
    );
  }

  // 判斷是否專家
  bool get isExpert => userIdentity.toLowerCase() == 'expert';
}

class Article {
  final int articleId;           // 對應 article_id
  final String title;            // 對應 title
  final String content;          // 對應 content
  final String category;         // 對應 category
  final String sourceLink;       // 對應 source_link
  final String mediaName;        // 對應 media_name
  final DateTime publishedTime;  // 對應 published_time
  final double reliabilityScore; // 對應 reliability_score
  final String aiAnalysis;       // 可從 analysis_results 表抓
  final List<RelatedNews> relatedNews; // 對應 related_news 表
  final List<Comment> comments;         // 對應 comments 表

  Article({
    required this.articleId,
    required this.title,
    required this.content,
    required this.category,
    required this.sourceLink,
    required this.mediaName,
    required this.publishedTime,
    required this.reliabilityScore,
    required this.aiAnalysis,
    required this.relatedNews,
    required this.comments,
  });

  // 從 JSON 建立 Article
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      articleId: json['article_id'],
      title: json['title'],
      content: json['content'],
      category: json['category'] ?? '',
      sourceLink: json['source_link'] ?? '',
      mediaName: json['media_name'] ?? '',
      publishedTime: DateTime.parse(json['published_time']),
      reliabilityScore: (json['reliability_score'] ?? 0).toDouble(),
      aiAnalysis: json['ai_analysis'] ?? "",
      relatedNews: (json['related_news'] as List<dynamic>?)
          ?.map((e) => RelatedNews.fromJson(e))
          .toList() ??
          [],
      comments: (json['comments'] as List<dynamic>?)
          ?.map((e) => Comment.fromJson(e))
          .toList() ??
          [],
    );
  }
}
