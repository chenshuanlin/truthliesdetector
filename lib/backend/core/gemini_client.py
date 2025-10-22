# =====================================================================
# gemini_client.py - Gemini 文字 / 圖片分析封裝（多模態 + 防呆 + 回覆精簡）
# =====================================================================

import os
import logging
import mimetypes
import re
import google.generativeai as genai

# ============================================================
# 初始化 Gemini 模型
# ============================================================
API_KEY = os.getenv("GEMINI_API_KEY", "")
if not API_KEY:
    logging.warning("⚠️ 未設定 GEMINI_API_KEY，請在 .env 中設定。")
else:
    genai.configure(api_key=API_KEY)

def _load_model(model_name: str):
    try:
        return genai.GenerativeModel(model_name)
    except Exception as e:
        logging.warning(f"⚠️ 模型 {model_name} 載入失敗：{e}")
        return None

# ✅ 模型自動降級
gemini_model = (
    _load_model("models/gemini-2.0-flash")
    or _load_model("models/gemini-1.5-flash")
    or _load_model("models/gemini-1.0-pro")
)

if gemini_model:
    logging.info("✅ Gemini 模型載入完成")
else:
    logging.error("❌ 無法載入任何 Gemini 模型，請確認 API_KEY 或版本設定。")

# ============================================================
# 🧠 文字分析
# ============================================================
def ask_gemini(prompt: str) -> str:
    """傳送文字 prompt 至 Gemini 並取得回覆（自動防呆）"""
    if not gemini_model:
        return "⚠️ Gemini 模型尚未載入成功。"

    try:
        response = gemini_model.generate_content(prompt)
        text = getattr(response, "text", "").strip()
        if not text:
            return "⚠️ 無法取得回覆，請稍後再試。"
        return text
    except Exception as e:
        logging.error(f"❌ Gemini 回覆錯誤：{e}", exc_info=True)
        return f"❌ 無法取得回覆：{e}"

# ============================================================
# 👁️ 圖片分析（Vision 模式 + 可信度推估）
# ============================================================
def ask_gemini_vision_score(prompt: str, image_path: str) -> dict:
    if not API_KEY:
        return {"text": "⚠️ 未設定 GEMINI_API_KEY。", "score": 0.0}

    model = (
        _load_model("models/gemini-2.0-flash")
        or _load_model("models/gemini-1.5-flash")
        or _load_model("models/gemini-1.0-pro-vision")
    )

    if not model:
        return {"text": "❌ 無法載入 Vision 模型。", "score": 0.0}

    try:
        mime_type, _ = mimetypes.guess_type(image_path)
        mime_type = mime_type or "image/jpeg"
        with open(image_path, "rb") as f:
            image_data = {"mime_type": mime_type, "data": f.read()}

        full_prompt = (
            f"{prompt}\n請判斷這張圖片是否真實，並在最後附上 0~1 的可信度分數（例如：0.85）。"
        )
        response = model.generate_content([full_prompt, image_data])
        result_text = getattr(response, "text", "").strip()
        match = re.search(r"([01](?:\.\d{1,2})?)", result_text)
        score = float(match.group(1)) if match else 0.5
        return {"text": result_text, "score": round(score, 2)}
    except Exception as e:
        logging.error(f"❌ Vision 模型錯誤：{e}", exc_info=True)
        return {"text": f"❌ 圖片分析失敗：{e}", "score": 0.0}

# ============================================================
# 🧩 綜合模式（文字 + 圖片）
# ============================================================
def ask_gemini_combined(prompt: str, image_path: str) -> dict:
    if not API_KEY:
        return {"text": "⚠️ 未設定 GEMINI_API_KEY。", "score": 0.0}
    try:
        model = (
            _load_model("models/gemini-2.0-flash")
            or _load_model("models/gemini-1.5-flash")
            or _load_model("models/gemini-1.0-pro-vision")
        )
        mime_type, _ = mimetypes.guess_type(image_path)
        mime_type = mime_type or "image/jpeg"
        with open(image_path, "rb") as f:
            image_data = {"mime_type": mime_type, "data": f.read()}
        full_prompt = (
            f"{prompt}\n這是一則文字搭配圖片的內容，請綜合分析是否真實，最後附上 0~1 的可信度分數。"
        )
        response = model.generate_content([full_prompt, image_data])
        result_text = getattr(response, "text", "").strip()
        match = re.search(r"([01](?:\.\d{1,2})?)", result_text)
        score = float(match.group(1)) if match else 0.5
        return {"text": result_text, "score": round(score, 2)}
    except Exception as e:
        logging.error(f"❌ 綜合分析錯誤：{e}", exc_info=True)
        return {"text": f"❌ 綜合分析失敗：{e}", "score": 0.0}
