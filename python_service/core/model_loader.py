import os
import lightgbm as lgb
from dotenv import load_dotenv
import logging

# ============================================================
# 模型載入模組（跨版本通用）
# ============================================================

load_dotenv()

# 讀取環境變數 MODEL_PATH（若有）
CUSTOM_PATH = os.getenv("MODEL_PATH")

# 專案根目錄：python_service/core/../../.. → truthliesdetector
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))

# 你的模型實際位置：
# C:\Users\USER\Desktop\truthliesdetector\projectt\model_auth_level\auth_level_lgbm.txt
DEFAULT_MODEL = os.path.join(
    BASE_DIR, "projectt", "model_auth_level", "auth_level_lgbm.txt"
)

# 其它備用候選路徑（以防以後調整）
CANDIDATE_PATHS = [
    CUSTOM_PATH,  # .env 指定
    DEFAULT_MODEL,
    os.path.join(BASE_DIR, "projectt", "model_auth_level", "lightgbm_model.txt"),
    os.path.join(BASE_DIR, "projectt", "model_auth_level", "model.pkl"),
]

_model = None


def _find_model_path():
    """自動尋找模型檔案"""
    for path in CANDIDATE_PATHS:
        if path and os.path.exists(path):
            logging.info(f"✅ 找到模型檔案：{path}")
            return path

    logging.error(
        "❌ 找不到任何 LightGBM 模型檔案，"
        "請確認 auth_level_lgbm.txt 是否存在於 projectt/model_auth_level/，"
        "或在 .env 中設定 MODEL_PATH。"
    )
    return None


def load_lightgbm_model():
    """載入 LightGBM 模型"""
    global _model
    if _model is not None:
        return _model

    model_path = _find_model_path()
    if not model_path:
        logging.error("❌ 模型路徑為空，模型無法載入！")
        return None

    try:
        _model = lgb.Booster(model_file=model_path)
        logging.info(f"🎯 LightGBM 模型載入成功：{model_path}")
        return _model
    except Exception as e:
        logging.error(f"❌ LightGBM 模型載入失敗：{e}")
        return None


def get_model():
    """取得模型實例"""
    global _model
    if _model is None:
        _model = load_lightgbm_model()

    if _model is None:
        logging.error("⚠️ get_model() 無法取得模型（目前為 None）")
    return _model
