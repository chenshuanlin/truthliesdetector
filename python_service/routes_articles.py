from flask import Blueprint, jsonify, request
from models import db
from sqlalchemy import text
from datetime import datetime

bp = Blueprint("articles", __name__)

# ======================
# 🔥 熱門趨勢
# ======================
@bp.route("/trending", methods=["GET"])
def get_trending_articles():
    try:
        query = text("""
            SELECT article_id, title, category, reliability_score, media_name, source_link
            FROM articles
            WHERE reliability_score IS NOT NULL
            ORDER BY reliability_score DESC
            LIMIT 3;
        """)
        result = db.session.execute(query)
        rows = result.fetchall()

        trending = []
        for r in rows:
            trending.append({
                "id": r[0],
                "title": r[1],
                "category": r[2],
                "reliability_score": float(r[3]),
                "media_name": r[4],
                "source_link": r[5],
                "summary": f"此文章由 {r[4]} 提供，可信度 {r[3]} 分。"
            })

        return jsonify(trending), 200

    except Exception as e:
        print("❌ 熱門趨勢查詢失敗:", e)
        return jsonify({"error": str(e)}), 500


# ======================
# 🎯 推薦文章
# ======================
@bp.route("/recommended", methods=["GET"])
def get_recommended_articles():
    try:
        query = text("""
            SELECT category, article_id, title, reliability_score, source_link
            FROM articles
            WHERE category IS NOT NULL
            ORDER BY category, reliability_score DESC;
        """)
        result = db.session.execute(query)
        rows = result.fetchall()

        categories = {}
        for cat, aid, title, score, link in rows:
            if cat not in categories:
                categories[cat] = []
            categories[cat].append({
                "id": aid,
                "title": title,
                "reliability_score": float(score) if score else None,
                "source_link": link
            })

        flat_list = []
        for cat, articles in categories.items():
            flat_list.extend(articles[:3])

        return jsonify(flat_list), 200

    except Exception as e:
        print("❌ 推薦文章查詢失敗:", e)
        return jsonify({"error": str(e)}), 500


# ======================
# 🏆 排行榜
# ======================
@bp.route("/ranking", methods=["GET"])
def get_ranking_articles():
    try:
        query = text("""
            SELECT article_id, title, category, published_time, reliability_score, source_link
            FROM articles
            WHERE reliability_score IS NOT NULL
            ORDER BY reliability_score DESC
            LIMIT 10;
        """)
        result = db.session.execute(query)
        rows = result.fetchall()

        ranking = []
        for r in rows:
            ranking.append({
                "id": r[0],
                "title": r[1],
                "category": r[2],
                "published_time": r[3].strftime("%Y-%m-%d %H:%M") if r[3] else "",
                "reliability_score": float(r[4]),
                "source_link": r[5],
            })

        return jsonify(ranking), 200

    except Exception as e:
        print("❌ 排行榜查詢失敗:", e)
        return jsonify({"error": str(e)}), 500


# ======================
# 📄 文章詳情
# ======================
@bp.route("/articles/<int:article_id>", methods=["GET"])
def get_article_detail(article_id):
    try:
        # 查主文
        query_article = text("SELECT * FROM articles WHERE article_id = :id;")
        article = db.session.execute(query_article, {"id": article_id}).fetchone()

        if not article:
            return jsonify({"error": "Article not found"}), 404

        # 查相關新聞
        related_query = text("""
            SELECT related_title, related_link, similarity_score
            FROM related_news
            WHERE source_article_id = :id;
        """)
        related_rows = db.session.execute(related_query, {"id": article_id}).fetchall()

        # 查留言
        comments_query = text("""
            SELECT content, commented_at, user_identity
            FROM comments
            WHERE article_id = :id
            ORDER BY commented_at DESC;
        """)
        comment_rows = db.session.execute(comments_query, {"id": article_id}).fetchall()

        related_list = [
            {"title": r[0], "link": r[1], "similarity": float(r[2])}
            for r in related_rows
        ]

        comment_list = [
            {
                "author": c[2] or "匿名用戶",
                "content": c[0],
                "is_expert": (c[2] == "專家"),
                "time": c[1].strftime("%Y-%m-%d %H:%M") if isinstance(c[1], datetime) else str(c[1]),
            }
            for c in comment_rows
        ]

        article_data = {
            "id": article.article_id,
            "title": article.title,
            "content": article.content,
            "category": article.category,
            "media_name": article.media_name,
            "published_time": article.published_time.strftime("%Y-%m-%d %H:%M") if article.published_time else None,
            "reliability_score": float(article.reliability_score or 0),
            "source_link": article.source_link,
            "related_news": related_list,
            "comments": comment_list,
        }

        return jsonify(article_data), 200

    except Exception as e:
        print("❌ 取得文章詳情失敗:", e)
        return jsonify({"error": str(e)}), 500
