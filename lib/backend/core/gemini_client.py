import os
import logging

try:
    from google import genai
except ImportError:
    genai = None

GEMINI_API_KEY = os.getenv(
    "GEMINI_API_KEY",
    "AIzaSyCT2yOK8ELSJWQ6X3IW3pQww0MqzLmGHTY"
)

_client = None
if genai is not None:
    try:
        _client = genai.Client(api_key=GEMINI_API_KEY)
        logging.info("✅ Gemini 客戶端初始化成功。")
    except Exception as e:
        _client = None
        logging.warning(f"⚠️ Gemini 初始化失敗：{e}")
else:
    logging.warning("⚠️ 未安裝 google-genai 套件，Gemini 模組停用。")


def ask_gemini(prompt: str) -> str:
    """呼叫 Gemini 生成回覆"""
    if not _client:
        logging.warning("⚠️ Gemini 未啟動，使用模擬回答。")
        return f"【模擬回答】妳剛剛說：{prompt[:80]}..."

    try:
        response = _client.models.generate_content(
            model="gemini-2.0-flash",
            contents=[prompt]
        )
        return response.text or "（Gemini 無回應）"
    except Exception as e:
        logging.error(f"❌ Gemini 呼叫錯誤: {e}")
        return f"【錯誤回退】無法連線 Gemini：{e}"
