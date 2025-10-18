from flask import Blueprint, request, jsonify
import logging
from core.text_analyzer import analyze_text

bp_analyze = Blueprint("analyze", __name__)

@bp_analyze.route("/analyze", methods=["POST"])
def analyze():
    """
    接收來自前端（AIacc）的分析請求
    支援文字輸入與檔案上傳
    """
    try:
        text_input = request.form.get("input", "")  # 文字內容
        file = request.files.get("file")

        # 如果有上傳檔案，可以在這裡加入 OCR 處理邏輯
        if file:
            logging.info(f"📁 收到檔案：{file.filename}")

        # 呼叫核心分析模組
        result = analyze_text(text_input or "圖片內容")

        # ✅ 與 text_analyzer.py 對齊欄位名稱
        response = {
            "score": result.get("score"),
            "credibility": result.get("credibility"),
            "level": result.get("level"),
            "summary": result.get("analysis_summary"),  # ✅ 改這裡
            "features_used": result.get("features_used"),
            "text_preview": result.get("text_preview"),
        }

        logging.info(f"✅ /analyze 成功回傳：{response}")
        return jsonify(response), 200

    except Exception as e:
        logging.error(f"❌ /analyze 發生錯誤：{e}", exc_info=True)
        return jsonify({"error": str(e)}), 500
