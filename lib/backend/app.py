# =====================================================================
# app.py - TruthLiesDetector Flask 主啟動程式（強化防呆 + 回傳精簡版）
# =====================================================================

import sys
import os
import logging
import warnings
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv

warnings.filterwarnings("ignore", category=UserWarning, module="jieba")

# ================================================================
# I. 環境設定與模組匯入
# ================================================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.extend([
    BASE_DIR,
    os.path.join(BASE_DIR, "core"),
    os.path.join(BASE_DIR, "routes")
])

# 載入 .env 設定檔
env_path = os.path.join(BASE_DIR, ".env")
if os.path.exists(env_path):
    load_dotenv(env_path)
    logging.info(f"✅ 已載入環境變數檔案：{env_path}")
else:
    logging.warning("⚠️ 找不到 .env 檔案，請確認設定檔是否存在於 backend 目錄內。")

# ================================================================
# II. 初始化 Flask App
# ================================================================
app = Flask(__name__)
CORS(app)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger(__name__)

MODEL_DIR = os.path.join(BASE_DIR, "projectt", "model_auth_level")

# ================================================================
# III. 匯入與註冊路由
# ================================================================
try:
    from routes.analyze_routes import analyze_bp
    from routes.chat_routes import chat_bp
    from core.database import init_db, get_chat_history, cleanup_old_chat_history

    app.register_blueprint(analyze_bp, url_prefix="/")
    app.register_blueprint(chat_bp, url_prefix="/")

    logging.info("✅ 已成功載入並註冊 routes 模組。")
except Exception as e:
    logging.error(f"❌ 無法載入路由模組：{e}", exc_info=True)

# ================================================================
# IV. 根路由（狀態檢查）
# ================================================================
@app.route("/")
def index():
    """
    基本狀態檢查：確認模型、金鑰與系統狀態
    """
    model_path = os.path.join(MODEL_DIR, "auth_level_lgbm.txt")

    return jsonify({
        "api": "ready",
        "status": "ok",
        "model_dir": MODEL_DIR,
        "model_loaded": os.path.exists(model_path),
        "gemini_key_loaded": bool(os.getenv("GEMINI_API_KEY")),
        "description": "✅ Flask 後端正常運行，AI 分析與 Gemini 模組已整合。"
    })

# ================================================================
# V. 聊天紀錄查詢端點（前端用）
# ================================================================
@app.route("/chat/history", methods=["GET"])
def chat_history():
    """
    提供前端查詢歷史聊天紀錄
    使用方式：GET /chat/history?limit=100
    """
    try:
        limit = int(request.args.get("limit", 50))
        from core.database import get_chat_history
        history = get_chat_history(limit=limit)
        return jsonify({
            "status": "ok",
            "count": len(history),
            "records": history
        }), 200
    except Exception as e:
        logging.error(f"⚠️ 無法讀取聊天紀錄：{e}", exc_info=True)
        return jsonify({
            "status": "failed",
            "error": str(e)
        }), 500

# ================================================================
# VI. AI 簡潔回傳測試端點（可用於前端整合驗證）
# ================================================================
@app.route("/analyze/summary", methods=["POST"])
def analyze_summary():
    """
    測試版：回傳簡潔化的 AI 分析結果
    （若前端不需詳細文字，使用這個端點）
    """
    try:
        data = request.get_json(force=True)
        text = data.get("text", "")

        # 模擬 AI 模型分析結果（未使用 Gemini，僅示範格式）
        result = {
            "credibility_level": "中",
            "score": 0.4871,
            "reason": "部分內容真實，但來源與佐證不足，可信度中等。",
            "suggestion": "請查證其他可信來源或新聞媒體。",
        }

        logging.info(f"✅ 分析完成：text={text[:30]}... score={result['score']}")
        return jsonify(result), 200

    except Exception as e:
        logging.error(f"❌ /analyze/summary 發生錯誤：{e}", exc_info=True)
        return jsonify({
            "error": "分析過程發生錯誤",
            "details": str(e)
        }), 500

# ================================================================
# VII. 啟動主程式
# ================================================================
if __name__ == "__main__":
    logging.info("🚀 TruthLiesDetector Flask API 啟動中...")

    try:
        from core.database import init_db, cleanup_old_chat_history
        init_db()  # 自動建立資料表
        cleanup_old_chat_history(30)  # 清理 30 天前紀錄
        logging.info("✅ 資料庫初始化與清理完成。")
    except Exception as e:
        logging.error(f"⚠️ 初始化資料庫時發生錯誤：{e}", exc_info=True)

    # 啟動 Flask 主伺服器
    try:
        app.run(host="0.0.0.0", port=5000, debug=True)
    except OSError as e:
        logging.error(f"❌ Flask 埠號被占用或啟動失敗：{e}")
        print("請確認是否已有相同服務在執行（如舊版 Flask 仍在背景運行）。")
