import sys
import os
import warnings
import logging
import base64
import numpy as np
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

# ============================================================
# Load .env
# ============================================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(BASE_DIR, ".env")
load_dotenv(ENV_PATH)

warnings.filterwarnings("ignore", category=UserWarning, module="jieba")

# Extend paths
sys.path.extend([
    BASE_DIR,
    os.path.join(BASE_DIR, "core"),
    os.path.join(BASE_DIR, "routes")
])

# ============================================================
# Optional OpenCV
# ============================================================
try:
    import cv2
except Exception:
    cv2 = None
    logging.warning("⚠️ OpenCV 未載入")

# ============================================================
# Import Blueprints
# ============================================================
# First batch
from routes_auth import bp as auth_bp
from routes_stats import bp as stats_bp
from routes_settings import bp as settings_bp
from routes_favorites import bp as favorites_bp
from routes_search_logs import bp as search_logs_bp
from routes_articles import bp as articles_bp
from routes_comments import bp as comments_bp
from routes_reports import bp as reports_bp

# Second batch
try:
    from routes.history_routes import bp as history_bp
    from routes.chat_routes import chat_bp
    from routes.analyze_routes import analyze_bp
except Exception as e:
    logging.error(f"[routes] ❌ 第二套路由載入失敗：{e}")
    history_bp = None
    chat_bp = None
    analyze_bp = None

# Core DB utilities (TruthLiesDetector)
try:
    from core.database import init_db, get_chat_history, cleanup_old_chat_history
except Exception:
    init_db = None
    get_chat_history = None
    cleanup_old_chat_history = None

# SQLAlchemy
from config import Config
from models import db

# =====================================================================
# Create Unified Flask App
# =====================================================================
def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    app.config["SQLALCHEMY_ECHO"] = True
    app.config["DEBUG"] = True

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s]: %(message)s"
    )

    CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)
    db.init_app(app)

    # Register Blueprints (/api prefix for legacy routes)
    app.register_blueprint(auth_bp, url_prefix="/api")
    app.register_blueprint(stats_bp, url_prefix="/api")
    app.register_blueprint(settings_bp, url_prefix="/api")
    app.register_blueprint(favorites_bp, url_prefix="/api")
    app.register_blueprint(search_logs_bp, url_prefix="/api")
    app.register_blueprint(articles_bp, url_prefix="/api")
    app.register_blueprint(comments_bp, url_prefix="/api")
    app.register_blueprint(reports_bp, url_prefix="/api")

    # Additional blueprints
    if chat_bp:
        app.register_blueprint(chat_bp, url_prefix="/")
    if analyze_bp:
        app.register_blueprint(analyze_bp, url_prefix="/")
    if history_bp:
        app.register_blueprint(history_bp, url_prefix="/api")

    # Register custom image API
    register_image_route(app)

    # Ping
    @app.route("/api/ping")
    def ping():
        return jsonify({"ok": True, "message": "Flask API 運作正常 🚀"})

    # Root health check
    @app.route("/")
    def index():
        model_dir = os.path.join(BASE_DIR, "projectt", "model_auth_level")
        model_path = os.path.join(model_dir, "auth_level_lgbm.txt")
        gemini_key = os.getenv("GEMINI_API_KEY", "")
        db_ready = os.path.exists(os.path.join(BASE_DIR, "truthlies.db"))

        return jsonify({
            "api": "TruthLiesDetector",
            "status": "ok",
            "model_dir": model_dir,
            "model_loaded": os.path.exists(model_path),
            "gemini_key_loaded": bool(gemini_key),
            "database_ready": db_ready,
            "description": "Flask 後端運作正常。"
        })

    # Chat history
    @app.route("/chat/history", methods=["GET"])
    def chat_history():
        if not get_chat_history:
            return jsonify({"error": "chat history module not loaded"}), 500
        try:
            limit = int(request.args.get("limit", 50))
            history = get_chat_history(limit=limit)
            return jsonify({"status": "ok", "count": len(history), "records": history})
        except Exception as e:
            return jsonify({"status": "failed", "error": str(e)}), 500

    # Simple analyze
    @app.route("/analyze/summary", methods=["POST"])
    def analyze_summary():
        try:
            data = request.get_json(force=True)
            text = data.get("text", "")
            if not text.strip():
                return jsonify({"error": "請提供文字內容"}), 400
            result = {
                "credibility": "中",
                "score": 0.4871,
                "summary": "部分內容真實，但來源不足。",
                "suggestion": "建議查證其他來源。"
            }
            return jsonify(result)
        except Exception as e:
            return jsonify({"error": "分析錯誤", "details": str(e)}), 500

    # Connection test
    @app.route("/test/connection")
    def test_connection():
        return jsonify({"status": "connected", "message": "Flask 後端連線成功"})

    return app

# =====================================================================
# Image utilities
# =====================================================================
def _load_image_from_url(url: str):
    if cv2 is None:
        return None
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = np.frombuffer(resp.content, dtype=np.uint8)
        return cv2.imdecode(data, cv2.IMREAD_COLOR)
    except Exception:
        return None


def _load_image_from_base64(b64: str):
    if cv2 is None:
        return None
    try:
        raw = base64.b64decode(b64)
        data = np.frombuffer(raw, dtype=np.uint8)
        return cv2.imdecode(data, cv2.IMREAD_COLOR)
    except Exception:
        return None


def _analyze_image(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    variance_laplacian = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    hist = cv2.calcHist([gray], [0], None, [256], [0, 256]).flatten()
    hist_norm = hist / (hist.sum() + 1e-6)
    entropy = float(-(hist_norm * np.log(hist_norm + 1e-9)).sum())
    edges = cv2.Canny(gray, 100, 200)
    edge_ratio = float(edges.mean())
    score = min(1.0, (variance_laplacian / 300.0) * 0.6 + (entropy / 6.0) * 0.4)
    level = "高品質" if score > 0.75 else ("中等" if score > 0.5 else "低品質")

    return {
        "variance_laplacian": round(variance_laplacian, 3),
        "entropy": round(entropy, 3),
        "edge_ratio": round(edge_ratio, 3),
        "quality_score": round(score, 3),
        "quality_level": level,
    }


def register_image_route(app):
    @app.post("/api/analyze-image")
    def analyze_image():
        if cv2 is None:
            return jsonify({"ok": False, "error": "伺服器未安裝 OpenCV"}), 503

        data = request.get_json(silent=True) or {}
        url = data.get("url")
        image_b64 = data.get("imageBase64")

        img = _load_image_from_url(url) if url else _load_image_from_base64(image_b64)
        if img is None:
            return jsonify({"ok": False, "error": "無法載入圖片"}), 400

        return jsonify({"ok": True, "result": _analyze_image(img)})

    return app


# =====================================================================
# Main entry
# =====================================================================
if __name__ == "__main__":
    app = create_app()

    with app.app_context():
        try:
            db.create_all()
            if init_db:
                init_db()
            if cleanup_old_chat_history:
                cleanup_old_chat_history(30)
            logging.info("資料庫初始化完成")
        except Exception as e:
            logging.error(f"資料庫錯誤: {e}")

    app.run(host="0.0.0.0", port=5000, debug=True, use_reloader=False)
