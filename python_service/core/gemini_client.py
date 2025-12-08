# =====================================================================
# gemini_client.py —— 最終完整修正版（2025）
# 使用你的 Google ListModels 實際可用模型：
#  - models/gemini-2.5-flash  ←（建議預設）
#  - models/gemini-2.0-flash
#  - models/gemini-2.0-flash-lite
# =====================================================================

import os
import logging
import google.generativeai as genai
from google.api_core.exceptions import ResourceExhausted

# ---------------------------------------------------------
# DEBUG：顯示實際載入路徑
# ---------------------------------------------------------
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
# 🔥 使用你 ListModels 裡真正存在的模型
# （這些模型全部出現在你貼的 API 回傳列表）
# ---------------------------------------------------------
MODEL_CANDIDATES = [
    "models/gemini-2.5-flash",       # 🚀 最推薦（免費 / 新版 / 穩定）
    "models/gemini-2.0-flash",       # 備用
    "models/gemini-2.0-flash-lite",  # 最省額度
]


def load_models():
    """讀取可用模型並列出 Google ListModels 結果"""
    models = []

    # 顯示 Google API 回傳模型清單
    try:
        print("\n📌 [DEBUG] Google ListModels 回傳：")
        available = genai.list_models()
        for m in available:
            print("  -", m.name)
        print("\n")
    except Exception as e:
        print("❌ [DEBUG] 無法讀取 ListModels：", e)

    # 測試候選模型是否可用
    for name in MODEL_CANDIDATES:
        try:
            m = genai.GenerativeModel(name)
            models.append(m)
            logging.info(f"✅ 模型可用：{name}")
        except Exception as e:
            logging.warning(f"⚠️ 模型不可用：{name} → {e}")

    return models


AVAILABLE_MODELS = load_models()
if not AVAILABLE_MODELS:
    logging.error("❌ 沒有找到任何可用模型（請檢查 API Key 或額度）。")


# ---------------------------------------------------------
# 單輪查詢
# ---------------------------------------------------------
def ask_gemini(prompt: str) -> str:
    if not AVAILABLE_MODELS:
        return "⚠️ Gemini 模型不可用"

    for model in AVAILABLE_MODELS:
        try:
            resp = model.generate_content(prompt)
            return getattr(resp, "text", "").strip() or "⚠️ 無法取得回覆"

        except ResourceExhausted:
            logging.error(f"❌ 模型額度耗盡：{model.model_name}")
            continue

        except Exception as e:
            logging.error(f"❌ Gemini 錯誤：{e}")

    return "⚠️ 查證時發生錯誤。"


# ---------------------------------------------------------
# 多輪查證 Chat
# ---------------------------------------------------------
def ask_gemini_chat(message: str, history: list) -> str:
    if not AVAILABLE_MODELS:
        return "⚠️ Gemini 模型不可用"

    # 整理對話格式
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

    # 嘗試所有模型直到成功
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

    return "⚠️ 查證功能目前額度不足，請稍後再試。"
