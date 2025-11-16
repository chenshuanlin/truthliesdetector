// lib/models/article_model.dart

class RelatedNews {
  final int? relatedId;
  final String relatedTitle;
  final String relatedLink;

  RelatedNews({
    this.relatedId,
    required this.relatedTitle,
    required this.relatedLink,
  });

  factory RelatedNews.fromJson(Map<String, dynamic> json) {
    return RelatedNews(
      relatedId: json['related_id'],
      relatedTitle: json['related_title'] ?? '',
      relatedLink: json['related_link'] ?? '',
    );
  }
}

class Comment {
  final int? commentId;
  final int? userId;
  final int? articleId;
  final String content;
  final String userIdentity;
  final DateTime commentedAt;

  Comment({
    this.commentId,
    this.userId,
    this.articleId,
    required this.content,
    required this.userIdentity,
    required this.commentedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'],
      userId: json['user_id'],
      articleId: json['article_id'],
      content: json['content'] ?? '',
      userIdentity: json['user_identity'] ?? '匿名',
      commentedAt: json['commented_at'] != null
          ? DateTime.parse(json['commented_at'])
          : DateTime.now(),
    );
  }

  bool get isExpert => userIdentity.toLowerCase() == 'expert';
}

class Article {
  final int? articleId;
  final String title;
  final String content;
  final String category;
  final String sourceLink;
  final String mediaName;
  final DateTime publishedTime;
  final double reliabilityScore;
  final String aiAnalysis;
  final List<RelatedNews> relatedNews;
  final List<Comment> comments;

  Article({
    this.articleId,
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

  factory Article.fromJson(Map<String, dynamic> json) {
    // 合併 related_news_sources 與 related_news_targets
    List<RelatedNews> allRelatedNews = [];

    if (json['related_news_sources'] != null) {
      allRelatedNews.addAll(
        (json['related_news_sources'] as List<dynamic>)
            .map((e) => RelatedNews.fromJson(e)),
      );
    }

    if (json['related_news_targets'] != null) {
      allRelatedNews.addAll(
        (json['related_news_targets'] as List<dynamic>)
            .map((e) => RelatedNews.fromJson(e)),
      );
    }

    return Article(
      articleId: json['article_id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      sourceLink: json['source_link'] ?? '',
      mediaName: json['media_name'] ?? '',
      publishedTime: json['published_time'] != null
          ? DateTime.parse(json['published_time'])
          : DateTime.now(),
      reliabilityScore:
      json['reliability_score'] != null ? (json['reliability_score'] as num).toDouble() : 0.0,
      aiAnalysis: json['ai_analysis'] ?? '',
      relatedNews: allRelatedNews,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => Comment.fromJson(e))
          .toList(),
    );
  }
}
