from flask import Blueprint, request, jsonify
import logging, json
from datetime import datetime

from models import db, ChatHistory
from core.text_analyzer import analyze_text
from core.gemini_client import ask_gemini_chat
from core.database import (
    insert_chat_session,
    append_chat_conversation
)

chat_bp = Blueprint("chat_routes", __name__)


# ======================================================
# 🔧 安全 JSON 處理：資料壞掉也不會 crash
# ======================================================
def safe_json(data):
    if data is None:
        return None
    try:
        if isinstance(data, str):
            return json.loads(data)
        return data
    except Exception:
        return None


# ======================================================
# 1️⃣ /chat/start — 初次查證
# ======================================================
@chat_bp.route("/chat/start", methods=["POST"])
def chat_start():
    try:
        data = request.get_json(force=True)
        message = (data.get("message") or "").strip()
        user_id = data.get("user_id")

        if not message:
            return jsonify({"error": "message required"}), 400

        # ---- Step1: AI acc ----
        ai_acc = analyze_text(message)
        score = ai_acc.get("score", 0)
        level = ai_acc.get("level", "未知")

        # ---- Step2: Gemini ----
        prompt = (
            f"以下內容需要查證：{message}\n"
            f"可信度：{level}（{score}）\n"
            f"請用一般人能懂的方式分析原因。"
        )
        reply = ask_gemini_chat(prompt, [])

        gemini_result = {
            "mode": "verify",
            "reply": reply,
            "scores": {"combined": {"score": score, "level": level}},
        }

        # ---- Step3: 建立 conversation ----
        now = datetime.utcnow().isoformat()
        conversation = [
            {"sender": "user", "text": message, "timestamp": now},
            {"sender": "system", "text": f"可信度：{level}（{score}）", "timestamp": now},
            {"sender": "ai", "text": reply, "timestamp": now},
        ]

        # ---- Step4: 寫入 DB ----
        session_id = insert_chat_session(
            user_id=user_id,
            query_text=message,
            ai_acc_result=ai_acc,
            gemini_result=gemini_result,
            conversation=conversation,
        )

        return jsonify({
            "session_id": session_id,
            "reply": reply,
            "ai_acc_result": ai_acc,
            "gemini_result": gemini_result
        })

    except Exception as e:
        logging.error(f"/chat/start error: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


# ======================================================
# 2️⃣ /chat/append — 續問查證
# ======================================================
@chat_bp.route("/chat/append", methods=["POST"])
def chat_append():
    try:
        data = request.get_json(force=True)
        session_id = data.get("session_id")
        message = (data.get("message") or "").strip()

        if not session_id:
            return jsonify({"error": "session_id required"}), 400
        if not message:
            return jsonify({"error": "message required"}), 400

        # ---- 取得 Session ----
        session = db.session.get(ChatHistory, session_id)
        if not session:
            return jsonify({"error": "session not found"}), 404

        history = safe_json(session.conversation) or []
        if not isinstance(history, list):
            history = []

        # ---- Step1: append user ----
        user_msg = {
            "sender": "user",
            "text": message,
            "timestamp": datetime.utcnow().isoformat()
        }
        append_chat_conversation(session_id, user_msg)

        # ---- Step2: Gemini 上下文 ----
        context_list = []
        for c in history:
            role = "user" if c.get("sender") == "user" else "model"
            context_list.append({"role": role, "parts": [{"text": c.get("text", "")}]})

        # ---- Step3: 可信度 ----
        acc = analyze_text(message)
        level = acc.get("level", "未知")
        score = acc.get("score", 0)

        sys_msg = {
            "sender": "system",
            "text": f"可信度：{level}（{score}）",
            "timestamp": datetime.utcnow().isoformat()
        }
        append_chat_conversation(session_id, sys_msg)

        # ---- Step4: Gemini ----
        verify_prompt = (
            f"請查證以下內容：{message}\n"
            f"可信度：{level}（{score}）\n"
            f"請用一般人都能理解的方式說明。"
        )
        reply = ask_gemini_chat(verify_prompt, context_list)

        append_chat_conversation(
            session_id,
            {
                "sender": "ai",
                "text": reply,
                "timestamp": datetime.utcnow().isoformat()
            }
        )

        return jsonify({"reply": reply})

    except Exception as e:
        logging.error(f"/chat/append error: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


# ======================================================
# 3️⃣ /chat/recent — 歷史查詢（完整修正版）
# ======================================================
@chat_bp.route("/chat/recent", methods=["GET"])
def chat_recent():
    try:
        user_id = request.args.get("user_id", type=int)
        limit = request.args.get("limit", 5, type=int)

        if not user_id:
            return jsonify({"error": "missing user_id"}), 400

        rows = (
            db.session.query(ChatHistory)
            .filter_by(user_id=user_id)
            .order_by(ChatHistory.created_at.desc())
            .limit(limit)
            .all()
        )

        results = []
        for r in rows:
            try:
                results.append({
                    "id": r.id,
                    "query_text": r.query_text,
                    "created_at": r.created_at.isoformat(),
                    "ai_acc_result": safe_json(r.ai_acc_result),
                    "gemini_result": safe_json(r.gemini_result),
                    "conversation": safe_json(r.conversation),
                })
            except Exception as e:
                logging.error("⚠ 單筆 chat_history 壞掉:", exc_info=True)
                continue

        return jsonify({"records": results, "status": "ok"})

    except Exception as e:
        logging.error(f"/chat/recent error: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500
