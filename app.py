from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime
import psycopg2
import psycopg2.extras

app = Flask(__name__)
CORS(app)

DB_CONFIG = {
    "host": "localhost",
    "database": "truthliesdetector",
    "user": "postgres",
    "password": "1234"
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

# ======================
# 🔥 熱門趨勢
# ======================
@app.route("/api/trending")
def get_trending_articles():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT article_id, title, category, reliability_score, media_name, source_link
        FROM articles
        WHERE reliability_score IS NOT NULL
        ORDER BY reliability_score DESC
        LIMIT 3;
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()

    results = [
        {
            "id": r[0],  # ✅ 改這裡
            "title": r[1],
            "category": r[2],
            "reliability_score": float(r[3]),
            "media_name": r[4],
            "source_link": r[5],
            "summary": f"此文章由 {r[4]} 提供，可信度 {r[3]} 分。"
        }
        for r in rows
    ]
    return jsonify(results)

# ======================
# 🎯 推薦文章
# ======================
@app.route("/api/recommended")
def get_recommended_articles():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT category, article_id, title, reliability_score, source_link
        FROM articles
        WHERE category IS NOT NULL
        ORDER BY category, reliability_score DESC;
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()

    categories = {}
    for cat, aid, title, score, link in rows:
        if cat not in categories:
            categories[cat] = []
        categories[cat].append({
            "id": aid,  # ✅ 改這裡
            "title": title,
            "reliability_score": float(score) if score else None,
            "source_link": link
        })

    flat_list = []
    for cat, articles in categories.items():
        flat_list.extend(articles[:3])  # 每類取前3篇
    return jsonify(flat_list)

# ======================
# 🏆 排行榜
# ======================
@app.route("/api/ranking")
def get_ranking_articles():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT article_id, title, category, published_time, reliability_score, source_link
        FROM articles
        WHERE reliability_score IS NOT NULL
        ORDER BY reliability_score DESC
        LIMIT 10;
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()

    ranking = [
        {
            "id": r[0],  # ✅ 改這裡
            "title": r[1],
            "category": r[2],
            "published_time": r[3].strftime("%Y-%m-%d %H:%M") if r[3] else "",
            "reliability_score": float(r[4]),
            "source_link": r[5],
        }
        for r in rows
    ]
    return jsonify(ranking)

# ======================
# 📄 文章詳情
# ======================
@app.route('/api/<int:article_id>', methods=['GET'])
def get_article(article_id):
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    cur.execute("SELECT * FROM articles WHERE article_id = %s;", (article_id,))
    article = cur.fetchone()
    if not article:
        cur.close()
        conn.close()
        return jsonify({'error': 'Article not found'}), 404

    cur.execute("""
        SELECT related_title, related_link, similarity_score
        FROM related_news
        WHERE source_article_id = %s;
    """, (article_id,))
    related = cur.fetchall()

    cur.execute("""
        SELECT content, commented_at, user_identity
        FROM comments
        WHERE article_id = %s
        ORDER BY commented_at DESC;
    """, (article_id,))
    comments = cur.fetchall()

    cur.close()
    conn.close()

    related_list = [
        {
            "title": r[0],
            "link": r[1],
            "similarity": float(r[2])
        } for r in related
    ]

    comment_list = [
        {
            "author": c[2] or "匿名用戶",
            "content": c[0],
            "is_expert": (c[2] == "專家"),
            "time": c[1].strftime("%Y-%m-%d %H:%M")
        } for c in comments
    ]

    return jsonify({
        "id": article["article_id"],  # ✅ 改這裡
        "title": article["title"],
        "content": article["content"],
        "category": article["category"],
        "media_name": article["media_name"],
        "published_time": article["published_time"].strftime("%Y-%m-%d %H:%M") if article["published_time"] else None,
        "reliability_score": float(article["reliability_score"] or 0),
        "source_link": article["source_link"],
        "related_news": related_list,
        "comments": comment_list
    })

# ======================
# 🚀 主程式
# ======================
if __name__ == "__main__":
    app.run(debug=True)
