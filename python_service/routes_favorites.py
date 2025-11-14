from flask import Blueprint, request, jsonify
from models import db
from sqlalchemy import text
from datetime import datetime

bp = Blueprint('favorites', __name__)

# ✅ 取得使用者收藏清單
@bp.route('/favorites/<int:user_id>', methods=['GET'])
def get_favorites(user_id):
    try:
        query = text("""
            SELECT a.article_id, a.title, a.media_name, a.source_link, 
                   f.favorited_at, a.reliability_score
            FROM favorites f
            JOIN articles a ON f.article_id = a.article_id
            WHERE f.user_id = :user_id
            ORDER BY f.favorited_at DESC;
        """)
        result = db.session.execute(query, {"user_id": user_id})
        rows = result.fetchall()

        favorites = []
        for r in rows:
            favorited_time = r[4]
            favorited_time_str = (
                favorited_time.strftime("%Y-%m-%d %H:%M:%S")
                if isinstance(favorited_time, datetime)
                else str(favorited_time)
            )

            favorites.append({
                "article_id": r[0],
                "title": r[1],
                "media_name": r[2],
                "source_link": r[3],
                "favorited_at": favorited_time_str,
                "reliability_score": r[5]
            })

        return jsonify(favorites), 200, {"Content-Type": "application/json"}

    except Exception as e:
        print("❌ 讀取收藏失敗:", e)
        return jsonify({"error": str(e)}), 500


# ✅ 新增收藏
@bp.route('/favorites', methods=['POST'])
def add_favorite():
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        article_id = data.get('article_id')

        if not user_id or not article_id:
            return jsonify({"error": "缺少 user_id 或 article_id"}), 400

        exists_query = text("""
            SELECT 1 FROM favorites 
            WHERE user_id = :user_id AND article_id = :article_id
        """)
        exists = db.session.execute(exists_query, {"user_id": user_id, "article_id": article_id}).fetchone()
        if exists:
            return jsonify({"message": "已收藏過"}), 409

        insert_query = text("""
            INSERT INTO favorites (user_id, article_id, favorited_at)
            VALUES (:user_id, :article_id, NOW())
        """)
        db.session.execute(insert_query, {"user_id": user_id, "article_id": article_id})
        db.session.commit()

        return jsonify({"message": "收藏成功"}), 201
    except Exception as e:
        db.session.rollback()
        print("❌ 新增收藏失敗:", e)
        return jsonify({"error": str(e)}), 500


# ✅ 取消收藏
@bp.route('/favorites', methods=['DELETE'])
def remove_favorite():
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        article_id = data.get('article_id')

        if not user_id or not article_id:
            return jsonify({"error": "缺少 user_id 或 article_id"}), 400

        delete_query = text("""
            DELETE FROM favorites 
            WHERE user_id = :user_id AND article_id = :article_id
        """)
        db.session.execute(delete_query, {"user_id": user_id, "article_id": article_id})
        db.session.commit()

        return jsonify({"message": "收藏已刪除"}), 200
    except Exception as e:
        db.session.rollback()
        print("❌ 移除收藏失敗:", e)
        return jsonify({"error": str(e)}), 500
