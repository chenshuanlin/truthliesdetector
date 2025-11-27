# =====================================================================
# analyze_routes.py - 智慧分析端點（整合模式：模型 + Gemini 說明 + Flutter 懸浮球支援）
# =====================================================================

from flask import Blueprint, request, jsonify
import logging
import os
from flask_cors import CORS
from core.text_analyzer import analyze_text
from core.gemini_client import ask_gemini
from core.database import insert_analysis_result

analyze_bp = Blueprint("analyze_bp", __name__)
CORS(analyze_bp)  # ✅ 開放跨域給 Flutter

@analyze_bp.route("/analyze", methods=["POST"])
def analyze():
    """
    接收前端輸入（文字 / 圖片 / 網址 / 混合），
    自動進行可信度判定 + Gemini 整合說明，
    支援 Flutter App（JSON / multipart 上傳）。
    """
    try:
        text = ""
        file = None
        filename = None
        image_path = None

        # --------------------------------------------------------
        # ✅ 支援 multipart/form-data（image or file）
        # --------------------------------------------------------
        if "image" in request.files or "file" in request.files:
            file = request.files.get("image") or request.files.get("file")
            filename = file.filename
            text = (request.form.get("text") or request.form.get("input") or "").strip()

            upload_dir = "uploads"
            os.makedirs(upload_dir, exist_ok=True)
            image_path = os.path.join(upload_dir, filename)
            file.save(image_path)
            logging.info(f"📸 收到檔案：{filename}，儲存於 {image_path}")

        # --------------------------------------------------------
        # ✅ 支援 JSON 格式
        # --------------------------------------------------------
        if request.is_json:
            data = request.get_json(silent=True) or {}
            text = (data.get("text") or text).strip()
            # 可擴充支援 base64 圖片
            # base64_image = data.get("image_base64")

        # --------------------------------------------------------
        # 防呆：若都沒有輸入
        # --------------------------------------------------------
        if not text and not file:
            return jsonify({"error": "請輸入文字或上傳圖片"}), 400

        # --------------------------------------------------------
        # ✅ 呼叫核心分析模型
        # --------------------------------------------------------
        result = analyze_text(text, image_path=image_path)
        score = float(result.get("score", 0.0))
        level = result.get("level", "未知")
        summary = result.get("summary", "尚未提供摘要")
        mode = result.get("mode", "文字")

        # --------------------------------------------------------
        # ✅ Gemini AI 解釋強化
        # --------------------------------------------------------
        gemini_prompt = (
            f"請根據以下分析結果提供一段簡短見解：\n"
            f"分析類型：{mode}\n可信度等級：{level}\n分數：{score:.3f}\n"
            f"摘要：{summary}\n"
            "請以一般使用者能懂的語氣回覆，讓人了解為何是這個可信度。"
        )
        gemini_response = ask_gemini(gemini_prompt) or "Gemini 未提供回覆"

        # --------------------------------------------------------
        # ✅ 顏色標記對應
        # --------------------------------------------------------
        color_level = (
            "green" if level in ["極高", "高"]
            else "yellow" if level == "中"
            else "red" if level in ["低", "極低"]
            else "gray"
        )

        # --------------------------------------------------------
        # ✅ 寫入資料庫
        # --------------------------------------------------------
        try:
            insert_analysis_result(text[:200], score, level, summary)
        except Exception as e:
            logging.warning(f"⚠️ 資料庫寫入失敗：{e}")

        # --------------------------------------------------------
        # ✅ 回傳整合結果（含懸浮球相容欄位）
        # --------------------------------------------------------
        combined_summary = (
            f"🔍 模型摘要：{summary}\n"
            f"💡 Gemini 見解：{gemini_response[:300]}"
        )

        response_payload = {
            "type": "analyze_result",
            "credibility": level,              # 🔹 給 Flutter 懸浮球用
            "summary": summary,                # 🔹 給 Flutter 顯示用
            "mode": mode,
            "level": level,
            "score": round(score, 3),
            "color_level": color_level,
            "gemini_explanation": gemini_response,
            "ai_summary": combined_summary,
        }

        logging.info(f"✅ /analyze 成功回傳：{response_payload}")
        return jsonify(response_payload), 200

    except Exception as e:
        logging.exception("❌ /analyze 發生錯誤：")
        return jsonify({"status": "failed", "error": str(e)}), 500