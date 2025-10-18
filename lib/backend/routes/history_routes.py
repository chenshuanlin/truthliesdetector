from flask import Blueprint, jsonify
from core.database import get_connection

bp_history = Blueprint("bp_history", __name__)

@bp_history.route("", methods=["GET"])
def history():
    conn = get_connection()
    if not conn:
        return jsonify({"error": "無法連線資料庫"}), 500
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, user_message, ai_response, created_at FROM chat_history ORDER BY id DESC LIMIT 20;")
            rows = cur.fetchall()
            result = [
                {"id": r[0], "user_message": r[1], "ai_response": r[2], "created_at": r[3].strftime("%Y-%m-%d %H:%M:%S")}
                for r in rows
            ]
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()
