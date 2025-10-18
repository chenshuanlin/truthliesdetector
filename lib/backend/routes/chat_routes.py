# =====================================================================
# chat_routes.py - 負責處理 AI 對話（Gemini 模型）
# =====================================================================

from flask import Blueprint, request, jsonify
import os
import logging
import google.generativeai as genai  # ✅ 修正匯入方式

# 初始化 blueprint
bp_chat = Blueprint("bp_chat", __name__)

# 設定 API 金鑰
API_KEY = os.getenv("GEMINI_API_KEY", "")
if not API_KEY:
    logging.warning("⚠️ 未設定 GEMINI_API_KEY，請在環境變數中加入金鑰。")
else:
    genai.configure(api_key=API_KEY)

# 建立模型實例
try:
    model = genai.GenerativeModel("models/gemini-2.5-flash")
    logging.info("✅ 已成功載入 Gemini 模型")
except Exception as e:
    logging.error(f"❌ 載入 Gemini 模型時發生錯誤：{e}")
    model = None


# =====================================================================
# 路由：AI 聊天回覆
# =====================================================================
@bp_chat.route("/chat", methods=["POST"])
def chat_with_ai():
    """
    接收前端文字訊息，傳給 Gemini 模型，回傳 AI 生成的內容。
    """
    try:
        data = request.get_json()
        user_message = data.get("message", "").strip()

        if not user_message:
            return jsonify({"error": "缺少訊息內容"}), 400

        if model is None:
            return jsonify({"error": "模型尚未載入成功"}), 500

        # 呼叫 Gemini 模型生成回覆
        response = model.generate_content(user_message)
        reply = response.text if hasattr(response, "text") else str(response)

        return jsonify({
            "user": user_message,
            "reply": reply,
            "status": "ok"
        })

    except Exception as e:
        logging.error(f"❌ AI 聊天發生錯誤：{e}")
        return jsonify({
            "error": str(e),
            "status": "failed"
        }), 500


# =====================================================================
# 健康檢查用 API
# =====================================================================
@bp_chat.route("/chat/status", methods=["GET"])
def chat_status():
    """
    提供前端確認 AI 模型是否可用。
    """
    status = "ready" if model else "not_ready"
    return jsonify({
        "model": "gemini-1.5-flash",
        "status": status
    })
