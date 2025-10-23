# Python Flask + OpenCV microservice

This service provides a simple image analysis endpoint using OpenCV.

## Endpoints
- POST /analyze-image
  - JSON body: { "url": "<image-url>" } or { "imageBase64": "<base64>" }
  - Response: { ok: true, result: { variance_laplacian, entropy, edge_ratio, quality_score, quality_level } }

## Run locally
1. Create venv and install deps
   - python -m venv .venv
   - .venv\\Scripts\\activate
   - pip install -r requirements.txt
2. Start service
   - python app.py  # listens on http://localhost:5001

## Node integration
- Set PY_SERVICE_BASE_URL=http://localhost:5001 for the Node server (or keep default).
- Node exposes /api/image-check which proxies to this Flask service.
