import sys, os
sys.path.append(os.path.dirname(__file__))

from flask import Flask, jsonify
from flask_cors import CORS
import logging
from dotenv import load_dotenv

# ================================================================
# I. 基礎設定
# ================================================================

# ✅ 載入 .env 檔案（放在 lib/backend 目錄）
load_dotenv()

# ✅ 建立 Flask 應用
app = Flask(__name__)
CORS(app)

# ✅ Logging 設定
logging.basicConfig(level=logging.INFO, format="%(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# ✅ 模型資料夾位置
MODEL_DIR = os.path.join(os.getcwd(), 'projectt', 'model_auth_level')

# ================================================================
# II. 匯入並註冊路由（注意順序）
# ================================================================

try:
    from routes.analyze_routes import bp_analyze
    from routes.chat_routes import bp_chat

    app.register_blueprint(bp_analyze, url_prefix='/')
    app.register_blueprint(bp_chat, url_prefix='/')

    logging.info("✅ 已成功載入 routes 模組。")
except Exception as e:
    logging.error(f"❌ 無法載入路由模組：{e}", exc_info=True)

# ================================================================
# III. 根路由（API 狀態檢查）
# ================================================================

@app.route('/')
def index():
    return jsonify({
        "api": "ready",
        "status": "ok",
        "model_dir": MODEL_DIR,
        "gemini_key_loaded": bool(os.getenv("GEMINI_API_KEY")),
        "description": "✅ Flask 後端正常運行，AI 分析與對話模組已整合。"
    })

# ================================================================
# IV. 啟動伺服器
# ================================================================

if __name__ == '__main__':
    logging.info("✅ TruthLiesDetector Flask API 已啟動：http://127.0.0.1:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)
