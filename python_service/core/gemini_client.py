# =====================================================================
# gemini_client.py —— 最終「快速啟動」無 ListModels 版（2025）
# =====================================================================

import os
import logging
import google.generativeai as genai
from google.api_core.exceptions import ResourceExhausted

print("🔍 [DEBUG] gemini_client loaded from:", __file__)

# ---------------------------------------------------------
# 讀取 API KEY
# ---------------------------------------------------------
API_KEY = os.getenv("GEMINI_API_KEY", "")
if not API_KEY:
    logging.warning("⚠️ GEMINI_API_KEY 未設定，Gemini 功能將無法使用。")
else:
    genai.configure(api_key=API_KEY)

# ---------------------------------------------------------
# ✔ 直接指定模型（不再 ListModels）
# ---------------------------------------------------------
DEFAULT_MODEL_NAME = "models/gemini-2.5-flash"   # ← 最推薦（快／便宜／精準）

try:
    MODEL = genai.GenerativeModel(DEFAULT_MODEL_NAME)
    print(f"✅ 已載入 Gemini 模型：{DEFAULT_MODEL_NAME}")
except Exception as e:
    print(f"❌ 無法載入模型：{e}")
    MODEL = None


# ---------------------------------------------------------
# 單輪查詢
# ---------------------------------------------------------
def ask_gemini(prompt: str) -> str:
    if not MODEL:
        return "⚠️ Gemini 模型不可用"

    try:
        resp = MODEL.generate_content(prompt)
        return getattr(resp, "text", "").strip() or "⚠️ 無法取得回覆"

    except ResourceExhausted:
        return "⚠️ 帳號額度已用完，請稍後再試。"

    except Exception as e:
        logging.error(f"Gemini 錯誤：{e}")
        return "⚠️ 查詢時發生錯誤。"


# ---------------------------------------------------------
# 多輪查證 Chat
# ---------------------------------------------------------
def ask_gemini_chat(message: str, history: list) -> str:
    if not MODEL:
        return "⚠️ Gemini 模型不可用"

    msgs = []

    # 整理多輪對話格式
    for h in history:
        try:
            msgs.append({
                "role": h["role"],
                "parts": [{"text": h["parts"][0]["text"]}]
            })
        except:
            continue

    msgs.append({"role": "user", "parts": [{"text": message}]})

    try:
        resp = MODEL.generate_content(msgs)
        reply = getattr(resp, "text", "").strip()
        return reply or "⚠️ 暫時無法取得回覆"

    except ResourceExhausted:
        return "⚠️ 數據額度不足，請稍後再試。"

    except Exception as e:
        logging.error(f"Gemini Chat 錯誤：{e}", exc_info=True)
        return "⚠️ 查證功能遇到錯誤。"
