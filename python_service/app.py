import os
import logging
import base64
import numpy as np
import requests

from flask import Flask, request, jsonify
from flask_cors import CORS
from config import Config
from models import db

# ============================================================
# 🔥 強制載入 .env（避免讀不到）
# ============================================================
from dotenv import load_dotenv

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(BASE_DIR, ".env")
load_dotenv(ENV_PATH)

print("DEBUG >>> GEMINI_API_KEY =", os.getenv("GEMINI_API_KEY"))
print("DEBUG >>> MODEL_PATH =", os.getenv("MODEL_PATH"))

# ============================================================
# OpenCV — 可裝可不裝
# ============================================================
try:
    import cv2  # type: ignore
except Exception:
    cv2 = None
    logging.warning("⚠️ OpenCV 未載入（cv2=None）。如需圖片分析，請安裝 opencv-python-headless")

# ============================================================
# 匯入第一批 Blueprint（後端 API）
# ============================================================
from routes_auth import bp as auth_bp
from routes_stats import bp as stats_bp
from routes_settings import bp as settings_bp
from routes_favorites import bp as favorites_bp
from routes_search_logs import bp as search_logs_bp
from routes_articles import bp as articles_bp
from routes_comments import bp as comments_bp
from routes_reports import bp as reports_bp

# ============================================================
# 匯入第二批 Blueprint（chat / analyze / history）
# ============================================================
try:
    from routes.history_routes import bp as history_bp
    from routes.chat_routes import chat_bp
    from routes.analyze_routes import analyze_bp
except Exception as e:
    logging.error(f"[routes] ❌ 第二套路由載入失敗：{e}")
    history_bp = None
    chat_bp = None
    analyze_bp = None


# ============================================================
# 建立 Flask App
# ============================================================
def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    app.config["SQLALCHEMY_ECHO"] = True
    app.config["DEBUG"] = True

    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s [%(levelname)s]: %(message)s"
    )

    print("📡 使用資料庫:", app.config["SQLALCHEMY_DATABASE_URI"])

    CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

    db.init_app(app)

    # ---- 註冊第一批 API ----
    app.register_blueprint(auth_bp, url_prefix="/api")
    app.register_blueprint(stats_bp, url_prefix="/api")
    app.register_blueprint(settings_bp, url_prefix="/api")
    app.register_blueprint(favorites_bp, url_prefix="/api")
    app.register_blueprint(search_logs_bp, url_prefix="/api")
    app.register_blueprint(articles_bp, url_prefix="/api")
    app.register_blueprint(comments_bp, url_prefix="/api")
    app.register_blueprint(reports_bp, url_prefix="/api/reports")

    # ---- 註冊第二批（可選）----
    if chat_bp:
        app.register_blueprint(chat_bp, url_prefix="/")
    if analyze_bp:
        app.register_blueprint(analyze_bp, url_prefix="/")
    if history_bp:
        app.register_blueprint(history_bp, url_prefix="/api")

    # ---- 註冊圖片分析 API ----
    register_image_route(app)

    @app.route("/api/ping")
    def ping():
        return jsonify({"ok": True, "message": "Flask API 運作正常 🚀"})

    return app


# ============================================================
# 圖片載入工具 — URL / Base64
# ============================================================
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


# ============================================================
# 圖片品質分析（cv2 存在才會執行）
# ============================================================
def _analyze_image(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    variance_laplacian = float(cv2.Laplacian(gray, cv2.CV_64F).var())

    hist = cv2.calcHist([gray], [0], None, [256], [0, 256]).flatten()
    hist_norm = hist / (hist.sum() + 1e-6)
    entropy = float(-(hist_norm * np.log(hist_norm + 1e-9)).sum())

    edges = cv2.Canny(gray, 100, 200)
    edge_ratio = float(edges.mean())

    score = min(1.0, (variance_laplacian / 300.0) * 0.6 + (entropy / 6.0) * 0.4)
    level = "高品質" if score > 0.75 else ("中等" if score > 0.5 else "可疑/低品質")

    return {
        "variance_laplacian": round(variance_laplacian, 3),
        "entropy": round(entropy, 3),
        "edge_ratio": round(edge_ratio, 3),
        "quality_score": round(score, 3),
        "quality_level": level,
    }


# ============================================================
# 註冊影像 API
# ============================================================
def register_image_route(app):
    @app.post("/analyze-image")
    def analyze_image():
        if cv2 is None:
            return (
                jsonify(
                    {
                        "ok": False,
                        "error": "伺服器未安裝 OpenCV，無法進行圖像品質分析。",
                    }
                ),
                503,
            )

        data = request.get_json(silent=True) or {}
        url = data.get("url")
        image_b64 = data.get("imageBase64")

        img = _load_image_from_url(url) if url else _load_image_from_base64(image_b64)

        if img is None:
            return jsonify({"ok": False, "error": "無法載入圖片"}), 400

        return jsonify({"ok": True, "result": _analyze_image(img)})

    return app


# ============================================================
# 主程式入口
# ============================================================
if __name__ == "__main__":
    app = create_app()

    with app.app_context():
        try:
            db.create_all()
            print("✅ 資料表初始化完成")
        except Exception as e:
            print("❌ 資料庫連線失敗:", e)

    app.run(host="0.0.0.0", port=5000, debug=True, use_reloader=False)
