from flask import Blueprint, request, jsonify
import logging
import re

from core.gemini_client import ask_gemini, ask_gemini_chat
from core.text_analyzer import analyze_text
from core.database import insert_chat_history, get_chat_history

chat_bp = Blueprint("chat", __name__)

# ============================================================
# 1️⃣ /chat — 查證 + 可信度分析（AIchat 初始查詢 or 有關鍵字）
# ============================================================

@chat_bp.route("/chat", methods=["POST"])
def chat_verify():
    try:
        if not request.is_json:
            return jsonify({"error": "必須為 JSON"}), 400

        data = request.get_json(force=True)
        message = (data.get("message") or "").strip()
        user_id = data.get("user_id")

        if not message:
            return jsonify({"error": "缺少 message"}), 400

        logging.info(f"🔍 查證訊息: {message[:60]}... user_id={user_id}")

        # -------------------------------
        # 判斷意圖：查證 or 一般查詢
        # -------------------------------
        verify_kw = r"(真假|查證|可信|謠言|來源|報導|是否真|可不可信|造假|假新聞)"
        inquiry_kw = r"(介紹|說明|如何|什麼是|有哪些|原理)"

        if re.search(verify_kw, message):
            intent = "verification"
        elif re.search(inquiry_kw, message):
            intent = "inquiry"
        else:
            intent = "verification" if "?" not in message else "inquiry"

        # -------------------------------
        # 執行可信度分析
        # -------------------------------
        if intent == "verification":
            try:
                ai_acc_result = analyze_text(message)
            except Exception as e:
                ai_acc_result = {"level": "未知", "score": 0, "error": str(e)}
        else:
            ai_acc_result = {"level": "不適用", "score": 0}

        score_value = ai_acc_result.get("score", 0)
        level_value = ai_acc_result.get("level", "未知")

        # -------------------------------
        # Gemini 回覆
        # -------------------------------
        prompt = (
            f"以下內容請協助查證：{message}。\n"
            f"可信度分析：{level_value}（{score_value}）。\n"
            "請以一般人能看懂的方式說明，並提供查證邏輯或來源。"
        )

        gemini_reply = ask_gemini(prompt)

        gemini_result = {
            "mode": "查證" if intent == "verification" else "查詢",
            "intent": intent,
            "reply": gemini_reply,
            "scores": {
                "text": score_value,
                "combined": {
                    "score": score_value,
                    "level": level_value
                },
                "vision": {"score": 0, "level": "無"},
            },
        }

        # -------------------------------
        # 寫入資料庫
        # -------------------------------
        insert_chat_history(
            query_text=message,
            ai_acc_result=ai_acc_result,
            gemini_result=gemini_result,
            user_id=user_id,
        )

        return jsonify({
            "query": message,
            "ai_acc_result": ai_acc_result,
            "gemini_result": gemini_result,
            "status": "ok"
        })

    except Exception as e:
        logging.error(f"/chat 錯誤：{e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


# ============================================================
# 2️⃣ /chat/text — 一般聊天（AIchat 第二句之後）
# ============================================================

@chat_bp.route("/chat/text", methods=["POST"])
def chat_text():
    try:
        data = request.get_json(force=True)
        message = (data.get("message") or "").strip()
        history = data.get("history") or []
        user_id = data.get("user_id")

        if not message:
            return jsonify({"error": "message required"}), 400

        logging.info(f"💬 聊天訊息：{message}")

        reply = ask_gemini_chat(message, history)

        insert_chat_history(
            query_text=message,
            ai_acc_result={"level": "不適用", "score": 0},
            gemini_result={"reply": reply, "mode": "chat"},
            user_id=user_id,
        )

        return jsonify({
            "reply": reply,
            "status": "ok"
        })

    except Exception as e:
        logging.error(f"/chat/text 錯誤：{e}", exc_info=True)
        return jsonify({"error": str(e)}), 500


# ============================================================
# 3️⃣ /chat/history — 查詢歷史紀錄（可用於前端聊天紀錄）
# ============================================================

@chat_bp.route("/chat/history", methods=["GET"])
def chat_history():
    try:
        limit = int(request.args.get("limit", 20))
        user_id = request.args.get("user_id")

        # user_id 不一定是 int → 嘗試轉換
        try:
            user_id = int(user_id)
        except:
            user_id = None

        records = get_chat_history(limit=limit, user_id=user_id)

        return jsonify({"records": records, "status": "ok"})

    except Exception as e:
        logging.error(f"/chat/history 錯誤：{e}")
        return jsonify({"error": str(e)}), 500
