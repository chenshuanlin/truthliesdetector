# =====================================================================
# gemini_client.py - Gemini 文字 / 長對話 / 穩定封裝（最新版）
# =====================================================================

import os
import logging

try:
    import google.generativeai as genai
except Exception:
    genai = None
    logging.error("⚠️ 無法載入 google.generativeai 套件，請確認已安裝： pip install google-generativeai")

# ============================================================
# 讀取環境變數中的 API KEY
# ============================================================
API_KEY = os.getenv("GEMINI_API_KEY", "")

if not API_KEY:
    logging.warning("⚠️ GEMINI_API_KEY 未設定，Gemini 功能將無法使用。")
else:
    if genai:
        try:
            genai.configure(api_key=API_KEY)
        except Exception as e:
            logging.error(f"⚠️ 設定 Gemini API key 失敗：{e}")


# ============================================================
# 嘗試載入多種模型，優先使用最新版本
# ============================================================

def _load_model(name: str):
    """嘗試載入指定 Gemini 模型"""
    try:
        if genai is None:
            return None
        return genai.GenerativeModel(name)
    except Exception as e:
        logging.warning(f"⚠️ 模型載入失敗 {name}：{e}")
        return None


gemini_model = None

if genai:
    # 按優先順序載入
    gemini_model = (
        _load_model("models/gemini-2.0-flash") or
        _load_model("models/gemini-1.5-flash") or
        _load_model("models/gemini-1.0-pro")
    )

if gemini_model:
    logging.info("✅ Gemini 模型載入成功")
else:
    logging.warning("⚠️ 所有 Gemini 模型載入失敗，將無法使用 LLM。")


# ============================================================
# 基本回覆
# ============================================================
def ask_gemini(prompt: str) -> str:
    """單句文字回答（非對話模式）"""
    if not gemini_model:
        return "⚠️ 無法使用 Gemini（模型未載入）"

    try:
        resp = gemini_model.generate_content(prompt)
        text = getattr(resp, "text", "").strip()
        return text or "⚠️ 無法取得回覆"
    except Exception as e:
        logging.error(f"Gemini 回覆錯誤：{e}", exc_info=True)
        return "⚠️ 回覆失敗，請稍後再試。"


# ============================================================
# 長對話模式（Chat）
# ============================================================
def ask_gemini_chat(message: str, history: list) -> str:
    """
    Gemini 長對話模式
    history 格式（由 routes_chat 傳入）:
    [
        { "role": "user/model", "parts": [{"text": "..."}] },
        ...
    ]
    """
    if not gemini_model:
        return "⚠️ 無法使用 Gemini（模型未載入）"

    try:
        msgs = []

        # ---- 從歷史紀錄建立上下文 ----
        for h in history:
            try:
                text = h["parts"][0]["text"]
            except Exception:
                logging.warning(f"⚠️ history 格式錯誤：{h}")
                continue

            msgs.append({
                "role": h["role"],
                "parts": [{"text": text}]
            })

        # ---- 加入新訊息 ----
        msgs.append({
            "role": "user",
            "parts": [{"text": message}]
        })

        # ---- 呼叫 Gemini ----
        resp = gemini_model.generate_content(msgs)
        reply = getattr(resp, "text", "").strip()

        return reply or "⚠️ 暫時無法取得回覆"

    except Exception as e:
        logging.error(f"Gemini Chat 錯誤：{e}", exc_info=True)
        return "⚠️ 查證時發生錯誤，請稍後再試"
