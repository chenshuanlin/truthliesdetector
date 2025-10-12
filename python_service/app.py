
from flask import Flask, request, jsonify
from flask_cors import CORS
from config import Config
from models import db
from routes_auth import bp as auth_bp
from routes_stats import bp as stats_bp
import base64, cv2, numpy as np, requests

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.config['DEBUG'] = True
    CORS(app, supports_credentials=True)
    db.init_app(app)
    app.register_blueprint(auth_bp, url_prefix='/api')
    app.register_blueprint(stats_bp, url_prefix='/api')
    # register image analysis route for flask run
    app = register_image_route(app)
    return app


def _load_image_from_url(url: str):
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = np.frombuffer(resp.content, dtype=np.uint8)
        img = cv2.imdecode(data, cv2.IMREAD_COLOR)
        return img
    except Exception:
        return None


def _load_image_from_base64(b64: str):
    try:
        raw = base64.b64decode(b64)
        data = np.frombuffer(raw, dtype=np.uint8)
        img = cv2.imdecode(data, cv2.IMREAD_COLOR)
        return img
    except Exception:
        return None


def _analyze_image(img: np.ndarray):
    # 簡單的品質/偽影指標：拉普拉斯變異 (清晰度)、灰階直方圖分散度、JPEG 區塊感 (DCT 邊)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    variance_laplacian = float(cv2.Laplacian(gray, cv2.CV_64F).var())

    # 直方圖分散度 (越分散代表對比度較高)
    hist = cv2.calcHist([gray], [0], None, [256], [0, 256]).flatten()
    hist_norm = hist / (hist.sum() + 1e-6)
    entropy = float(-(hist_norm * np.log(hist_norm + 1e-9)).sum())

    # 邊緣密度 (偵測過度銳化或偽影)
    edges = cv2.Canny(gray, 100, 200)
    edge_ratio = float(edges.mean())  # 0~1

    # 粗略可信度 (僅示意)：清晰度與對比度越高，越可能為自然照片
    score = min(1.0, (variance_laplacian / 300.0) * 0.6 + (entropy / 6.0) * 0.4)

    level = '高品質' if score > 0.75 else ('中等' if score > 0.5 else '可疑/低品質')

    return {
        'variance_laplacian': round(variance_laplacian, 3),
        'entropy': round(entropy, 3),
        'edge_ratio': round(edge_ratio, 3),
        'quality_score': round(score, 3),
        'quality_level': level,
    }



def register_image_route(app):
    @app.post('/analyze-image')
    def analyze_image():
        data = request.get_json(silent=True) or {}
        url = data.get('url')
        image_b64 = data.get('imageBase64')
        img = None
        if url:
            img = _load_image_from_url(url)
        elif image_b64:
            img = _load_image_from_base64(image_b64)
        if img is None:
            return jsonify({'ok': False, 'error': '無法載入圖片，請提供有效的 url 或 imageBase64'}), 400
        result = _analyze_image(img)
        return jsonify({'ok': True, 'result': result})

    return app


if __name__ == '__main__':
    app = create_app()
    app = register_image_route(app)
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000, debug=True)
