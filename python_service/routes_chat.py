from flask import Blueprint, request, jsonify
import logging
from datetime import datetime

from models import db, ChatHistory
from core.text_analyzer import analyze_text
from core.gemini_client import ask_gemini_chat
from core.database import (
    insert_chat_session,
    append_chat_conversation,
    get_recent_chat_sessions
)

chat_bp = Blueprint("chat_routes", __name__)


# ======================================================
# 1️⃣ /chat/start — 首次查證，建立 Session
# ======================================================
@chat_bp.route("/chat/start", methods=["POST"])
def chat_start():
    try:
        data = request.get_json(force=True)
        message = (data.get("message") or "").strip()
        user_id = data.get("user_id")

        if not message:
            return jsonify({"error": "message required"}), 400

        # ---- Step1: AI acc 可信度分析 ----
        ai_acc = analyze_text(message)
        score = ai_acc.get("score", 0)
        level = ai_acc.get("level", "未知")

        # ---- Step2: Gemini 查證 ----
        prompt = (
            f"以下內容需要查證：{message}\n"
            f"可信度：{level}（{score}）\n"
            f"請用一般人能懂的方式分析原因。"
        )

        reply = ask_gemini_chat(prompt, [])

        gemini_result = {
            "mode": "verify",
            "reply": reply,
            "scores": {
                "combined": {"score": score, "level": level},
            },
        }

        # ---- Step3: conversation 初始化 ----
        now = datetime.now().isoformat()
        conversation = [
            {"sender": "user", "text": message, "timestamp": now},
            {"sender": "system", "text": f"可信度：{level}（{score}）", "timestamp": now},
            {"sender": "ai", "text": reply, "timestamp": now},
        ]

        # ---- Step4: 存入 DB ----
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
# 2️⃣ /chat/append — 每次都跑查證模式（新版）
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

        # ---- 找 Session ----
        session = db.session.get(ChatHistory, session_id)
        if not session:
            return jsonify({"error": "session not found"}), 404

        conversation = session.conversation or []

        # ---- Step1: append user ----
        user_msg = {
            "sender": "user",
            "text": message,
            "timestamp": datetime.now().isoformat()
        }
        append_chat_conversation(session_id, user_msg)

        # ---- Step2: 建立 Gemini 上下文 ----
        context_list = []
        for c in session.conversation:  # 已包含 user_msg
            role = "user" if c["sender"] == "user" else "model"
            context_list.append({"role": role, "parts": [{"text": c["text"]}]})

        # ===========================================================
        # ⭐ Step3: 一律跑查證模式（不再需要 need_verify）
        # ===========================================================
        acc = analyze_text(message)
        level = acc.get("level", "未知")
        score = acc.get("score", 0)

        sys_msg = {
            "sender": "system",
            "text": f"可信度：{level}（{score}）",
            "timestamp": datetime.now().isoformat()
        }
        append_chat_conversation(session_id, sys_msg)

        # Gemini 查證 Prompt
        verify_prompt = (
            f"請查證以下內容：{message}\n"
            f"可信度：{level}（{score}）\n"
            f"請用一般人都能理解的方式說明。"
        )

        reply = ask_gemini_chat(verify_prompt, context_list)

        # ---- Step4: append AI 回覆 ----
        append_chat_conversation(
            session_id,
            {
                "sender": "ai",
                "text": reply,
                "timestamp": datetime.now().isoformat()
            }
        )

        return jsonify({"reply": reply})

    except Exception as e:
        logging.error(f"/chat/append error: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


# ======================================================
# 3️⃣ /chat/recent — 歷史查詢
# ======================================================
@chat_bp.route("/chat/recent", methods=["GET"])
def chat_recent():
    try:
        user_id = request.args.get("user_id", type=int)
        limit = request.args.get("limit", 5, type=int)

        rows = get_recent_chat_sessions(user_id, limit)
        return jsonify({"records": rows, "status": "ok"})

    except Exception as e:
        logging.error(f"/chat/recent error: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500
