# analyze_routes.py - integrated analyze route
from flask import Blueprint, request, jsonify
import logging
from core.text_analyzer import analyze_text
from core.gemini_client import ask_gemini

analyze_bp = Blueprint("analyze_bp", __name__)

@analyze_bp.route("/analyze", methods=["POST"])
def analyze():
    try:
        text = ""
        file = None
        filename = None

        if "file" in request.files:
            file = request.files["file"]
            filename = file.filename
            text = (request.form.get("input") or "").strip()
            upload_dir = "uploads"
            import os
            os.makedirs(upload_dir, exist_ok=True)
            image_path = os.path.join(upload_dir, filename)
            file.save(image_path)
            logging.info(f"📸 收到檔案：{filename}")
        else:
            image_path = None

        if request.is_json:
            data = request.get_json(silent=True) or {}
            text = (data.get("text") or text).strip()

        if not text and not file:
            return jsonify({"error": "請輸入文字或上傳圖片"}), 400

        result = analyze_text(text, image_path=image_path)
        score = float(result.get("score", 0.0))
        level = result.get("level", "未知")
        summary = result.get("summary", "尚未提供摘要")
        mode = result.get("mode", "文字")

        gemini_prompt = (
            f"請根據以下分析結果提供一段簡短見解：\n"
            f"分析類型：{mode}\n可信度等級：{level}\n分數：{score:.3f}\n"
            f"摘要：{summary}\n"
            "請以一般使用者能懂的語氣回覆，讓人了解為何是這個可信度。"
        )
        try:
            gemini_response = ask_gemini(gemini_prompt)
        except Exception as e:
            logging.warning(f"Gemini explain failed: {e}")
            gemini_response = ""

        color_level = (
            "green" if level in ["極高", "高"]
            else "yellow" if level == "中"
            else "red" if level in ["低", "極低"]
            else "gray"
        )

        concise_result = {
            "type": "analyze_result",
            "mode": mode,
            "level": level,
            "score": round(score, 3),
            "color_level": color_level,
            "summary": summary,
            "gemini_explanation": gemini_response,
            "ai_summary": f"🔍 模型分析摘要：{summary}\n💡 AI 見解：{(gemini_response or '')[:400]}",
        }

        return jsonify(concise_result), 200

    except Exception as e:
        logging.exception("❌ /analyze 發生錯誤：")
        return jsonify({"status": "failed", "error": str(e)}), 500