# =====================================================================
# gemini_client.py - Gemini 文字 / 長對話 / 圖片 / 圖文分析封裝
# =====================================================================

import os
import logging
import mimetypes
import re

# optional import - guard if google.generativeai not installed
try:
    import google.generativeai as genai
except Exception:
    genai = None

# ============================================================
# 初始化 Gemini 模型
# ============================================================
API_KEY = os.getenv("GEMINI_API_KEY", "")
if not API_KEY:
    logging.warning("⚠️ 未設定 GEMINI_API_KEY，請在 .env 中設定。")
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

# 自動降級模型
gemini_model = None
if genai:
    gemini_model = (
        _load_model("models/gemini-2.0-flash")
        or _load_model("models/gemini-1.5-flash")
        or _load_model("models/gemini-1.0-pro")
    )

if gemini_model:
    logging.info("✅ Gemini 模型載入完成")
else:
    logging.info("ℹ️ Gemini 模型未載入（缺少依賴或金鑰）")

# ============================================================
# 文字查證 / 摘要回答
# ============================================================

def ask_gemini(prompt: str) -> str:
    if not gemini_model:
        return "⚠️ Gemini 模型尚未載入成功。"

    try:
        response = gemini_model.generate_content(prompt)
        text = getattr(response, "text", "").strip()
        if not text:
            return "⚠️ 無法取得回覆。"
        return text
    except Exception as e:
        logging.error(f"Gemini 回覆錯誤：{e}", exc_info=True)
        return "⚠️ 回覆失敗，請稍後再試。"

# ============================================================
# Vision 單圖片分析
# ============================================================

def ask_gemini_vision_score(prompt: str, image_path: str) -> dict:
    if not API_KEY or genai is None:
        return {"text": "⚠️ 未設定 GEMINI_API_KEY", "score": 0.0}

    model = (
        _load_model("models/gemini-2.0-flash")
        or _load_model("models/gemini-1.5-flash")
        or _load_model("models/gemini-1.0-pro-vision")
    )

    if not model:
        return {"text": "❌ 無法載入 Vision 模型", "score": 0.0}

    try:
        mime_type, _ = mimetypes.guess_type(image_path)
        mime_type = mime_type or "image/jpeg"

        with open(image_path, "rb") as f:
            image_data = {"mime_type": mime_type, "data": f.read()}

        response = model.generate_content([prompt, image_data])
        text = getattr(response, "text", "").strip()

        match = re.search(r"([01](?:\.\d{1,2})?)", text)
        score = float(match.group(1)) if match else 0.5

        return {"text": text, "score": round(score, 2)}
    except Exception as e:
        logging.error(f"Vision 分析錯誤：{e}", exc_info=True)
        return {"text": "❌ 分析失敗", "score": 0.0}

# ============================================================
# 圖文綜合分析
# ============================================================

def ask_gemini_combined(prompt: str, image_path: str) -> dict:
    if not API_KEY or genai is None:
        return {"text": "⚠️ 未設定金鑰", "score": 0.0}

    try:
        model = (
            _load_model("models/gemini-2.0-flash")
            or _load_model("models/gemini-1.5-flash")
            or _load_model("models/gemini-1.0-pro-vision")
        )

        mime_type, _ = mimetypes.guess_type(image_path)
        mime_type = mime_type or "image/jpeg"

        with open(image_path, "rb") as f:
            img = {"mime_type": mime_type, "data": f.read()}

        full_prompt = prompt + "\n請在最後附上一個 0~1 的整體可信度分數。"

        response = model.generate_content([full_prompt, img])
        text = getattr(response, "text", "").strip()

        match = re.search(r"([01](?:\.\d{1,2})?)", text)
        score = float(match.group(1)) if match else 0.5

        return {"text": text, "score": round(score, 2)}

    except Exception as e:
        logging.error(f"綜合分析錯誤：{e}", exc_info=True)
        return {"text": "❌ 分析失敗", "score": 0.0}

# ============================================================
# 💬 AIchat 用的長對話聊天模式
# ============================================================

def ask_gemini_chat(message: str, history: list) -> str:
    """
    Gemini 一般聊天模式（不做可信度分析）
    支援上下文，專門給 AIchat.dart 使用
    history: [{'role': 'user'/'assistant', 'content': '...'}]
    """
    if not gemini_model:
        return "⚠️ Gemini 模型尚未載入成功。"

    try:
        msgs = []

        # 加入歷史紀錄
        for h in history:
            msgs.append({
                "role": h["role"],
                "parts": [{"text": h["content"]}]
            })

        # 使用者訊息
        msgs.append({
            "role": "user",
            "parts": [{"text": message}]
        })

        response = gemini_model.generate_content(msgs)
        reply = getattr(response, "text", "").strip()

        if not reply:
            return "⚠️ 無回覆，請稍後再試。"

        return reply

    except Exception as e:
        logging.error(f"Gemini Chat 錯誤：{e}", exc_info=True)
        return "⚠️ 聊天失敗，請稍後再試。"
