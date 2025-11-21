# =====================================================================
# gemini_client.py - Gemini 文字 / 長對話 / 圖片 / 圖文分析封裝
# =====================================================================

import os
import logging
import mimetypes
import re

try:
    import google.generativeai as genai
except Exception:
    genai = None

# ============================================================
# 初始化 Gemini 模型
# ============================================================
API_KEY = os.getenv("GEMINI_API_KEY", "")
if not API_KEY:
    logging.warning("⚠️ 未設定 GEMINI_API_KEY")
else:
    if genai:
        try:
            genai.configure(api_key=API_KEY)
        except Exception as e:
            logging.warning(f"⚠️ 無法設定 genai API key: {e}")

def _load_model(model_name: str):
    try:
        if genai is None:
            return None
        return genai.GenerativeModel(model_name)
    except Exception as e:
        logging.warning(f"⚠️ 模型 {model_name} 載入失敗：{e}")
        return None

gemini_model = None
if genai:
    gemini_model = (
        _load_model("models/gemini-2.0-flash")
        or _load_model("models/gemini-1.5-flash")
        or _load_model("models/gemini-1.0-pro")
    )

if gemini_model:
    logging.info("✅ Gemini 模型載入完成")


# ============================================================
# 基本回答
# ============================================================
def ask_gemini(prompt: str) -> str:
    if not gemini_model:
        return "⚠️ Gemini 模型尚未載入成功。"

    try:
        resp = gemini_model.generate_content(prompt)
        text = getattr(resp, "text", "").strip()
        return text or "⚠️ 無法取得回覆。"
    except Exception as e:
        logging.error(f"Gemini 回覆錯誤：{e}", exc_info=True)
        return "⚠️ 回覆失敗，請稍後再試。"


# ============================================================
# 💬 AIchat — 長對話模式
# ============================================================
def ask_gemini_chat(message: str, history: list) -> str:
    """
    history 格式（routes_chat 提供）:
    [
        { "role": "user/model", "parts": [{"text": "..."}] },
        ...
    ]
    """
    if not gemini_model:
        return "⚠️ Gemini 模型尚未載入成功。"

    try:
        msgs = []

        # ⭐ 讀取 history（從 parts 中取 text）
        for h in history:
            try:
                part_text = h["parts"][0]["text"]
            except Exception:
                logging.warning(f"⚠️ history 格式錯誤，跳過：{h}")
                continue

            msgs.append({
                "role": h["role"],
                "parts": [{"text": part_text}]
            })

        # ⭐ 加入新訊息
        msgs.append({
            "role": "user",
            "parts": [{"text": message}]
        })

        response = gemini_model.generate_content(msgs)
        reply = getattr(response, "text", "").strip()

        return reply or "⚠️ 無回覆，請稍後再試。"

    except Exception as e:
        logging.error(f"Gemini Chat 錯誤：{e}", exc_info=True)
        return "⚠️ 聊天失敗，請稍後再試。"
