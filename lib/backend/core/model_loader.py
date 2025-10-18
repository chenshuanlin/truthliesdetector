import os
import lightgbm as lgb
from dotenv import load_dotenv
import logging

# ============================================================
# 模型載入模組：支援自動路徑偵測 + .env 指定
# ============================================================

load_dotenv()

# 從環境變數讀取（若有）
CUSTOM_PATH = os.getenv("MODEL_PATH")

# 推算專案根目錄
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))

# 模型候選清單（會自動偵測最可能的）
CANDIDATE_PATHS = [
    CUSTOM_PATH,
    os.path.join(BASE_DIR, "projectt", "model_auth_level", "auth_level_lgbm.txt"),
    os.path.join(BASE_DIR, "projectt", "model_auth_level", "lightgbm_model.txt"),
    os.path.join(BASE_DIR, "projectt", "model_auth_level", "model.pkl"),
    os.path.join(BASE_DIR, "lib", "backend", "projectt", "model_auth_level", "auth_level_lgbm.txt"),
]

_model = None


def _find_model_path():
    """自動尋找模型檔案"""
    for path in CANDIDATE_PATHS:
        if path and os.path.exists(path):
            logging.info(f"✅ 找到模型檔案：{path}")
            return path
    logging.error("❌ 找不到任何模型檔案，請確認檔案存在於 projectt/model_auth_level/")
    return None


def load_lightgbm_model():
    """載入 LightGBM 模型"""
    global _model
    if _model is not None:
        return _model

    model_path = _find_model_path()
    if not model_path:
        return None

    try:
        _model = lgb.Booster(model_file=model_path)
        logging.info(f"✅ 模型載入成功：{model_path}")
        return _model
    except Exception as e:
        logging.error(f"❌ 模型載入失敗：{e}")
        return None


def get_model():
    """取得模型實例"""
    global _model
    if _model is None:
        return load_lightgbm_model()
    return _model
