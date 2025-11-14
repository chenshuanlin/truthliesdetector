# routes_search_logs.py
from flask import Blueprint, request, jsonify
from models import db
from sqlalchemy import text
from datetime import datetime

bp = Blueprint('search_logs', __name__)

# ✅ 取得使用者瀏覽歷史（依最近一次 searched_at 排序）
@bp.route('/history/<int:user_id>', methods=['GET'])
def get_history(user_id):
    try:
        query = text("""
            SELECT
                a.article_id,
                a.title,
                a.media_name,
                a.source_link,
                MAX(s.searched_at) AS last_viewed_at,
                a.reliability_score
            FROM search_logs s
            JOIN articles a ON s.article_id = a.article_id
            WHERE s.user_id = :user_id
            GROUP BY a.article_id, a.title, a.media_name, a.source_link, a.reliability_score
            ORDER BY last_viewed_at DESC;
        """)
        result = db.session.execute(query, {"user_id": user_id}).mappings().all()

        history = []
        for r in result:
            ts = r['last_viewed_at']
            ts_str = ts.strftime("%Y-%m-%d %H:%M:%S") if isinstance(ts, datetime) else ""
            history.append({
                "article_id": r["article_id"],
                "title": r["title"],
                "media_name": r["media_name"],
                "source_link": r["source_link"],
                "viewed_at": ts_str,
                "reliability_score": r["reliability_score"]
            })

        return jsonify(history), 200
    except Exception as e:
        print("❌ 讀取瀏覽紀錄失敗:", e)
        return jsonify({"error": str(e)}), 500


# ✅ 新增或更新一筆瀏覽紀錄（去重複）
@bp.route('/search-logs', methods=['POST'])
def add_search_log():
    try:
        data = request.get_json(silent=True) or {}
        user_id = data.get('user_id')
        article_id = data.get('article_id')

        if not user_id or not article_id:
            return jsonify({"error": "缺少 user_id 或 article_id"}), 400

        # ⭐⭐ 做去重複：如果已有紀錄，就更新時間，如果沒有就新增 ⭐⭐
        upsert_sql = text("""
            INSERT INTO search_logs (user_id, article_id, searched_at)
            VALUES (:user_id, :article_id, NOW())
            ON CONFLICT (user_id, article_id)
            DO UPDATE SET searched_at = EXCLUDED.searched_at;
        """)

        db.session.execute(upsert_sql, {
            "user_id": user_id,
            "article_id": article_id,
        })
        db.session.commit()

        return jsonify({"ok": True, "message": "已記錄瀏覽"}), 201

    except Exception as e:
        db.session.rollback()
        print("❌ 新增瀏覽紀錄失敗:", e)
        return jsonify({"error": str(e)}), 500

# ✅ 清除某使用者的瀏覽紀錄
@bp.route('/history/<int:user_id>', methods=['DELETE'])
def clear_history(user_id):
    try:
        delete_sql = text("""
            DELETE FROM search_logs WHERE user_id = :user_id;
        """)
        db.session.execute(delete_sql, {"user_id": user_id})
        db.session.commit()

        return jsonify({"ok": True, "message": "已清除瀏覽紀錄"}), 200
    except Exception as e:
        db.session.rollback()
        print("❌ 清除瀏覽紀錄錯誤:", e)
        return jsonify({"error": str(e)}), 500

