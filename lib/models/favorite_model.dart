// lib/models/favorite_model.dart
class Favorite {
  final int favoriteId;   // 收藏紀錄的主鍵
  final int articleId;    // 收藏的文章 ID
  final int userId;       // 使用者 ID
  final DateTime favoritedAt; // 收藏時間

  Favorite({
    required this.favoriteId,
    required this.articleId,
    required this.userId,
    required this.favoritedAt,
  });

  /// 將後端回傳的 JSON 轉為 Favorite 物件
  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      favoriteId: json['favorite_id'],
      articleId: json['article_id'],
      userId: json['user_id'],
      favoritedAt: DateTime.parse(json['favorited_at']),
    );
  }
}