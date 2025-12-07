# =====================================================================
# gemini_client.py  —— 方案 B：自動降級模型 + 安全錯誤處理
# =====================================================================

import os
import logging
import google.generativeai as genai
from google.api_core.exceptions import ResourceExhausted

# ---------------------------------------------------------
# 讀取 API KEY
# ---------------------------------------------------------
API_KEY = os.getenv("GEMINI_API_KEY", "")

if not API_KEY:
    logging.warning("⚠️ GEMINI_API_KEY 未設定，Gemini 功能將無法使用。")
else:
    genai.configure(api_key=API_KEY)

# ---------------------------------------------------------
# 可用模型（依優先順序）
# ---------------------------------------------------------
MODEL_CANDIDATES = [
    "models/gemini-2.0-flash",
    "models/gemini-1.5-flash",
    "models/gemini-1.0-pro",
]


def load_models():
    """依序嘗試載入所有模型，能用的就加入列表"""
    models = []
    for name in MODEL_CANDIDATES:
        try:
            m = genai.GenerativeModel(name)
            models.append(m)
            logging.info(f"✅ 模型可用：{name}")
        except Exception as e:
            logging.warning(f"⚠️ 模型不可用：{name} → {e}")
    return models


# 可用模型清單（至少一個）
AVAILABLE_MODELS = load_models()

if not AVAILABLE_MODELS:
    logging.error("❌ 沒有任何 Gemini 模型可用。")


# ---------------------------------------------------------
# 單次訊息（簡單模式）
# ---------------------------------------------------------
def ask_gemini(prompt: str) -> str:
    if not AVAILABLE_MODELS:
        return "⚠️ Gemini 模型不可用"

    for model in AVAILABLE_MODELS:
        try:
            resp = model.generate_content(prompt)
            return getattr(resp, "text", "").strip() or "⚠️ 無法取得回覆"
        except ResourceExhausted:
            logging.error(f"❌ 模型無額度，嘗試下一個模型：{model.model_name}")
            continue
        except Exception as e:
            logging.error(f"❌ Gemini 錯誤：{e}")

    return "⚠️ 查證時發生錯誤（額度可能不足），請稍後再試。"


# ---------------------------------------------------------
# Chat 模式（多輪對話）
# ---------------------------------------------------------
def ask_gemini_chat(message: str, history: list) -> str:
    if not AVAILABLE_MODELS:
        return "⚠️ Gemini 模型不可用"

    # 組合 Gemini Chat 格式
    msgs = []
    for h in history:
        try:
            msgs.append({
                "role": h["role"],
                "parts": [{"text": h["parts"][0]["text"]}]
            })
        except:
            continue

    msgs.append({"role": "user", "parts": [{"text": message}]})

    # -----------------------------------------------------
    # 依序嘗試所有模型，直到成功
    # -----------------------------------------------------
    for model in AVAILABLE_MODELS:
        try:
            resp = model.generate_content(msgs)
            reply = getattr(resp, "text", "").strip()
            return reply or "⚠️ 暫時無法取得回覆"

        except ResourceExhausted:
            logging.error(f"❌ 模型額度不足：{model.model_name} → 換下一個")
            continue

        except Exception as e:
            logging.error(f"Gemini Chat 錯誤：{e}", exc_info=True)

    # -----------------------------------------------------
    # 全部模型都失敗 → 回傳友善錯誤
    # -----------------------------------------------------
    return "⚠️ 查證功能目前額度不足，請稍後再試。"
