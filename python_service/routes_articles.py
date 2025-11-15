from flask import Blueprint, jsonify, request, Response
from models import db
from sqlalchemy import text
from datetime import datetime, timedelta
import json

bp = Blueprint("articles", __name__)

# ============================================================
# 🔹 可信度數字 → 文字轉換對照表
# ============================================================
SCORE_LABELS = {
    0: "不可信",
    1: "極低可信度",
    2: "低可信度",
    3: "中可信度",
    4: "高可信度",
    5: "極高可信度",
}

# ============================================================
# 🔥 熱門趨勢
# ============================================================
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
                "credibility_label": SCORE_LABELS.get(int(r[3]), "未知"),
                "media_name": r[4],
                "source_link": r[5],
                "summary": f"此文章由 {r[4]} 提供，可信度 {SCORE_LABELS.get(int(r[3]), '未知')}。",
            })

        return jsonify(trending), 200

    except Exception as e:
        print("❌ 熱門趨勢查詢失敗:", e)
        return jsonify({"error": str(e)}), 500


# ============================================================
# 🎯 推薦文章
# ============================================================
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
                "credibility_label": SCORE_LABELS.get(int(score or 0), "未知"),
                "source_link": link
            })

        flat_list = []
        for cat, articles in categories.items():
            flat_list.extend(articles[:3])

        return jsonify(flat_list), 200

    except Exception as e:
        print("❌ 推薦文章查詢失敗:", e)
        return jsonify({"error": str(e)}), 500


# ============================================================
# 🏆 排行榜
# ============================================================
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
                "credibility_label": SCORE_LABELS.get(int(r[4]), "未知"),
                "source_link": r[5],
            })

        return jsonify(ranking), 200

    except Exception as e:
        print("❌ 排行榜查詢失敗:", e)
        return jsonify({"error": str(e)}), 500


# ============================================================
# 🔍 搜尋文章（給 Flutter 搜尋頁）
# ============================================================
@bp.route("/articles/search", methods=["GET"])
def search_articles():
    try:
        keyword = request.args.get("keyword", "").strip()
        category = request.args.get("category", "").strip()
        confidence = request.args.get("confidence", "").strip()
        time_filter = request.args.get("time_filter", "").strip()

        # SQL 組合條件
        conditions = []
        params = {}

        if keyword:
            conditions.append("(title ILIKE :kw OR content ILIKE :kw)")
            params["kw"] = f"%{keyword}%"
        if category:
            conditions.append("category ILIKE :cat")
            params["cat"] = f"%{category}%"

        if confidence:
            score = next((k for k, v in SCORE_LABELS.items() if v == confidence), None)
            if score is not None:
                conditions.append("reliability_score = :score")
                params["score"] = score

        if time_filter == "今天":
            conditions.append("published_time >= :start_time")
            params["start_time"] = datetime.now().replace(hour=0, minute=0, second=0)
        elif time_filter == "本週":
            conditions.append("published_time >= :start_time")
            params["start_time"] = datetime.now() - timedelta(days=7)
        elif time_filter == "本月":
            conditions.append("published_time >= :start_time")
            params["start_time"] = datetime.now() - timedelta(days=30)

        where_clause = " AND ".join(conditions) if conditions else "TRUE"

        query = text(f"""
            SELECT article_id, title, category, media_name, published_time, reliability_score, source_link
            FROM articles
            WHERE {where_clause}
            ORDER BY published_time DESC;
        """)
        result = db.session.execute(query, params)
        rows = result.fetchall()

        articles = []
        for r in rows:
            articles.append({
                "id": r[0],
                "title": r[1],
                "category": r[2],
                "media_name": r[3],
                "published_time": r[4].strftime("%Y-%m-%d %H:%M") if r[4] else "",
                "reliability_score": float(r[5] or 0),
                "credibility_label": SCORE_LABELS.get(int(r[5] or 0), "未知"),
                "source_link": r[6],
            })

        return jsonify(articles), 200

    except Exception as e:
        print("❌ 搜尋文章失敗:", e)
        return jsonify({"error": str(e)}), 500


# ============================================================
# 📄 文章詳情
# ============================================================
@bp.route("/articles/<int:article_id>", methods=["GET"])
def get_article_detail(article_id):
    print(f"🧭 收到文章查詢請求 article_id = {article_id}")
    try:
        # 查主文
        query_article = text("SELECT * FROM articles WHERE article_id = :id;")
        article = db.session.execute(query_article, {"id": article_id}).fetchone()

        if not article:
            print("⚠️ 查無此文章")
            return jsonify({"error": "Article not found"}), 404

        # 查留言
        comments_query = text("""
            SELECT content, commented_at, user_identity
            FROM comments
            WHERE article_id = :id
            ORDER BY commented_at DESC;
        """)
        comment_rows = db.session.execute(comments_query, {"id": article_id}).fetchall()

        # 🔹 格式化留言
        comment_list = [
            {
                "author": c[2] or "匿名用戶",
                "content": c[0] or "",
                "is_expert": (c[2] == "專家"),
                "time": c[1].strftime("%Y-%m-%d %H:%M") if hasattr(c[1], "strftime") else str(c[1]),
            }
            for c in comment_rows
        ]

        # 🔹 格式化文章資料
        content_text = article.content or ""
        if len(content_text) > 8000:
            content_text = content_text[:8000] + " ...（內容過長，請至來源連結閱讀完整文章）"

        article_data = {
            "id": article.article_id,
            "title": article.title or "無標題",
            "content": content_text,
            "category": article.category or "未分類",
            "media_name": article.media_name or "未知來源",
            "published_time": (
                article.published_time.strftime("%Y-%m-%d %H:%M")
                if hasattr(article.published_time, "strftime")
                else str(article.published_time)
            ),
            "reliability_score": float(article.reliability_score or 0),
            "credibility_label": SCORE_LABELS.get(int(article.reliability_score or 0), "未知"),
            "source_link": article.source_link or "",
            "comments": comment_list,
        }

        # ✅ 使用 Response + json.dumps（防止 jsonify 超時）
        return Response(json.dumps(article_data, ensure_ascii=False), content_type="application/json")

    except Exception as e:
        print("❌ 取得文章詳情失敗:", e)
        return jsonify({"error": str(e)}), 500