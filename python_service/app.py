from flask import Flask, request, jsonify
from flask_cors import CORS
from config import Config
from models import db

# 🔹 匯入所有 Blueprint
from routes_auth import bp as auth_bp
from routes_stats import bp as stats_bp
from routes_settings import bp as settings_bp
from routes_favorites import bp as favorites_bp
from routes_search_logs import bp as search_logs_bp
from routes_articles import bp as articles_bp   # ✅ 包含 /api/articles/search
from routes_comments import bp as comments_bp
from routes_reports import bp as reports_bp

import base64, cv2, numpy as np, requests

# ---------------------------------------------------------
# 建立 Flask App
# ---------------------------------------------------------
def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.config["DEBUG"] = True

    # ✅ 印出目前使用的資料庫 URI（方便除錯）
    print("📡 目前使用的資料庫連線 URI:", app.config["SQLALCHEMY_DATABASE_URI"])

    # ✅ 啟用跨域 (讓 Flutter 可連線)
    CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

    # ✅ 初始化資料庫
    db.init_app(app)

    # ✅ 註冊藍圖 (Blueprint)
    app.register_blueprint(auth_bp, url_prefix="/api")
    app.register_blueprint(stats_bp, url_prefix="/api")
    app.register_blueprint(settings_bp, url_prefix="/api")
    app.register_blueprint(favorites_bp, url_prefix="/api")
    app.register_blueprint(search_logs_bp, url_prefix="/api")
    app.register_blueprint(articles_bp, url_prefix="/api")   # ✅ 搜尋功能在這裡
    app.register_blueprint(comments_bp, url_prefix="/api")
    app.register_blueprint(reports_bp, url_prefix="/api/reports")

    # ✅ 註冊影像分析路由（可留用）
    app = register_image_route(app)

    # ✅ 提供健康檢查 API（前後端連線測試）
    @app.route("/api/ping")
    def ping():
        return jsonify({"ok": True, "message": "Flask API 運作正常 🚀"}), 200

    return app

# ---------------------------------------------------------
# 影像處理與品質分析函式區
# ---------------------------------------------------------
def _load_image_from_url(url: str):
    """從 URL 載入圖片"""
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = np.frombuffer(resp.content, dtype=np.uint8)
        img = cv2.imdecode(data, cv2.IMREAD_COLOR)
        return img
    except Exception:
        return None


def _load_image_from_base64(b64: str):
    """從 Base64 字串載入圖片"""
    try:
        raw = base64.b64decode(b64)
        data = np.frombuffer(raw, dtype=np.uint8)
        img = cv2.imdecode(data, cv2.IMREAD_COLOR)
        return img
    except Exception:
        return None


def _analyze_image(img: np.ndarray):
    """分析圖片清晰度與品質"""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    variance_laplacian = float(cv2.Laplacian(gray, cv2.CV_64F).var())

    # 直方圖分散度
    hist = cv2.calcHist([gray], [0], None, [256], [0, 256]).flatten()
    hist_norm = hist / (hist.sum() + 1e-6)
    entropy = float(-(hist_norm * np.log(hist_norm + 1e-9)).sum())

    # 邊緣密度
    edges = cv2.Canny(gray, 100, 200)
    edge_ratio = float(edges.mean())

    # 粗略品質分數
    score = min(1.0, (variance_laplacian / 300.0) * 0.6 + (entropy / 6.0) * 0.4)
    level = "高品質" if score > 0.75 else ("中等" if score > 0.5 else "可疑/低品質")

    return {
        "variance_laplacian": round(variance_laplacian, 3),
        "entropy": round(entropy, 3),
        "edge_ratio": round(edge_ratio, 3),
        "quality_score": round(score, 3),
        "quality_level": level,
    }

# ---------------------------------------------------------
# Flask 路由註冊區：影像分析 API
# ---------------------------------------------------------
def register_image_route(app):
    @app.post("/analyze-image")
    def analyze_image():
        """上傳圖片後自動分析品質"""
        data = request.get_json(silent=True) or {}
        url = data.get("url")
        image_b64 = data.get("imageBase64")

        img = None
        if url:
            img = _load_image_from_url(url)
        elif image_b64:
            img = _load_image_from_base64(image_b64)

        if img is None:
            return jsonify({"ok": False, "error": "無法載入圖片"}), 400

        result = _analyze_image(img)
        return jsonify({"ok": True, "result": result})

    return app

# ---------------------------------------------------------
# 主程式入口
# ---------------------------------------------------------
if __name__ == "__main__":
    app = create_app()

    # ✅ 初始化資料庫
    with app.app_context():
        try:
            db.create_all()
            print("✅ 資料表初始化完成。")
        except Exception as e:
            print("❌ 資料庫連線或建立資料表失敗：", e)

    # ✅ 啟動 Flask 伺服器
    app.run(host="0.0.0.0", port=5000, debug=True)