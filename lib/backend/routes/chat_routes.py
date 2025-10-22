# =====================================================================
# chat_routes.py - Gemini 對話與聊天紀錄路由（含延伸查證 + 智慧補充 Smart Verify Mode）
# ✅ 修正版：整合「文字 + 圖片 + 綜合可信度」一致顯示，避免分數矛盾
# =====================================================================

from flask import Blueprint, request, jsonify
import logging
import re
from core.gemini_client import ask_gemini
from core.text_analyzer import analyze_text
from core.database import insert_chat_history, get_chat_history

chat_bp = Blueprint("chat", __name__)

# ============================================================
# 🧠 Gemini 主路由
# ============================================================
@chat_bp.route("/chat", methods=["POST"])
def chat_with_gemini():
    """
    根據輸入內容自動判斷意圖：
    🔹 查證類（Verification）→ 啟動可信度分析與查證模式
    🔹 查詢類（Inquiry）→ 直接啟動 Gemini 搜尋或解釋模式
    支援延伸查證 + 智慧補充（Smart Verify Mode）
    並顯示「整體 + 文字 + 圖片」三段可信度結果
    """
    try:
        # ① 驗證輸入
        if not request.is_json:
            return jsonify({"error": "請求格式錯誤，必須為 JSON"}), 400

        data = request.get_json(force=True) or {}
        message = (data.get("message") or "").strip()
        context = data.get("context", "")
        user_id = data.get("user_id")
        ai_acc_result = data.get("ai_acc_result") or {}

        if not message:
            return jsonify({"error": "請輸入訊息內容"}), 400

        logging.info(f"💬 收到訊息：{message[:80]}... (user_id={user_id})")

        # ============================================================
        # ② 判斷「查詢型」或「查證型」意圖
        # ============================================================
        inquiry_keywords = r"(介紹|資料|說明|原理|是什麼|有哪些|請推薦|幫我找|有沒有|如何|特色|應用)"
        verify_keywords = r"(真假|真實|可信|查證|來源|報導|謠言|假新聞|是否真|可不可信)"

        if re.search(verify_keywords, message):
            intent = "verification"
        elif re.search(inquiry_keywords, message):
            intent = "inquiry"
        else:
            intent = "inquiry" if "?" in message or "？" in message else "verification"

        logging.info(f"🎯 判定意圖：{intent}")

        # ============================================================
        # ③ 查證型 → 啟動可信度分析
        # ============================================================
        ai_acc_result = ai_acc_result or {}
        vision_result = ai_acc_result.get("vision_result") or {}

        if intent == "verification":
            try:
                if not ai_acc_result:
                    ai_acc_result = analyze_text(message)
                    logging.info(f"✅ 自動分析完成：level={ai_acc_result.get('level')}")
            except Exception as e:
                logging.warning(f"⚠️ 自動分析失敗：{e}")
                ai_acc_result = {"level": "未知", "score": 0, "error": str(e)}

            # 模式判定
            url_pattern = re.compile(r"https?://[^\s]+")
            if re.search(url_pattern, message):
                mode = "網址"
            elif vision_result:
                mode = "圖片"
            else:
                mode = "文字"

            # 各項分數
            text_score = round(float(ai_acc_result.get("score") or 0.0), 2)
            vision_score = round(float(vision_result.get("score") or 0.0), 2)
            combined_score = (
                round((text_score + vision_score) / 2, 2)
                if vision_result
                else text_score
            )

            # 根據分數決定可信度等級
            def score_to_level(score: float) -> str:
                if score >= 0.85:
                    return "極高"
                elif score >= 0.7:
                    return "高"
                elif score >= 0.4:
                    return "中"
                elif score > 0:
                    return "低"
                else:
                    return "未知"

            text_level = score_to_level(text_score)
            vision_level = score_to_level(vision_score) if vision_score else "無"
            combined_level = score_to_level(combined_score)

            logging.info(
                f"🧩 模式判定：{mode}, 文字可信度={text_level}({text_score}), 圖片可信度={vision_level}({vision_score}), 綜合={combined_level}({combined_score})"
            )

            # ------------------------------------------------------------
            # 🧠 Smart Verify Mode（查證類 prompt）
            # ------------------------------------------------------------
            if re.search(r"(新聞|查證|來源|報導|事實)", message):
                prompt = (
                    f"請協助查找「{context or message}」的相關新聞或資料來源，"
                    "列出5項以內的可信媒體報導或官方聲明，含日期與一句摘要。"
                    "若無資料請明確說明查無，並於最後補充正確的背景知識與官方資料來源。"
                )
            else:
                prompt = (
                    f"你是一位媒體識讀專家。文字可信度為「{text_level}」（{text_score}），"
                    f"圖片可信度為「{vision_level}」（{vision_score}），整體綜合可信度為「{combined_level}」（{combined_score}）。\n"
                    f"請在三句內說明整體可信度原因、主要依據與查證建議，"
                    f"最後補充正確背景知識與官方資料來源。"
                )

        # ============================================================
        # ④ 查詢型 → 啟動資料搜尋或科普模式
        # ============================================================
        else:
            mode = "查詢"
            ai_acc_result = {"level": "不適用", "score": 0.0}
            text_score = vision_score = combined_score = 0.0
            text_level = vision_level = combined_level = "不適用"

            prompt = (
                f"請根據使用者問題「{message}」提供清楚且具體的資料或背景說明。"
                f"若是學術、科技、社會議題，請以專業但淺顯的方式回答。"
                f"禁止生成假資料，若無資料請說明無相關可信來源。"
                f"若主題涉及公共議題、醫療或氣候等，請於回答最後補充正確的背景知識與官方資料來源。"
            )

        # ============================================================
        # ⑤ 呼叫 Gemini
        # ============================================================
        try:
            gemini_reply = ask_gemini(prompt)
        except Exception as e:
            logging.error(f"❌ Gemini 回覆錯誤：{e}")
            gemini_reply = ""

        if not gemini_reply or gemini_reply.strip() == "":
            gemini_reply = (
                "目前無法取得相關資料，建議您參考事實查核中心、官方媒體或學術來源。"
            )

        # ============================================================
        # ⑥ 結構化輸出 + 統一可信度說明
        # ============================================================
        comment_map = {
            "極高": "此內容高度可信，可作為可靠參考來源。",
            "高": "此內容可信度高，但仍建議多方查證。",
            "中": "此內容可信度中等，請保持懷疑思考。",
            "低": "此內容可信度偏低，建議查核再分享。",
            "極低": "此內容極可能不實，請勿輕信或轉傳。",
            "未知": "無法判斷內容真偽，請查閱更多來源。",
            "不適用": "這是查詢型問題，無須判斷可信度。",
        }

        ai_comment = f"💬 {comment_map.get(combined_level, '請保持批判性思考。')}"

        # 統一輸出
        gemini_result = {
            "mode": mode,
            "intent": intent,
            "reply": gemini_reply.strip(),
            "scores": {
                "text": {"score": text_score, "level": text_level},
                "vision": {"score": vision_score, "level": vision_level},
                "combined": {"score": combined_score, "level": combined_level},
            },
            "comment": ai_comment,
        }

        # ============================================================
        # ⑦ 寫入資料庫
        # ============================================================
        try:
            insert_chat_history(
                query_text=message,
                ai_acc_result=ai_acc_result,
                gemini_result=gemini_result,
                user_id=user_id,
            )
            logging.info(f"💾 已寫入 chat_history（模式={mode}, 意圖={intent}, user_id={user_id}）")
        except Exception as e:
            logging.warning(f"⚠️ 寫入 chat_history 失敗：{e}")

        # ============================================================
        # 🔚 回傳結果
        # ============================================================
        return jsonify({
            "mode": mode,
            "intent": intent,
            "query": message,
            "ai_acc_result": ai_acc_result,
            "gemini_result": gemini_result,
            "status": "ok"
        }), 200

    except Exception as e:
        logging.error(f"❌ /chat 發生錯誤：{e}", exc_info=True)
        return jsonify({"error": str(e), "status": "failed"}), 500


# ============================================================
# 💬 聊天紀錄查詢端點
# ============================================================
@chat_bp.route("/chat/history", methods=["GET"])
def chat_history():
    """查詢最近聊天紀錄，可指定 user_id"""
    try:
        limit = int(request.args.get("limit", 50))
        user_id = request.args.get("user_id")
        records = get_chat_history(limit=limit, user_id=user_id)
        return jsonify({"status": "ok", "count": len(records), "records": records}), 200
    except Exception as e:
        logging.error(f"⚠️ /chat/history 發生錯誤：{e}")
        return jsonify({"status": "failed", "error": str(e)}), 500


# ============================================================
# 🔍 模型狀態檢查端點
# ============================================================
@chat_bp.route("/chat/status", methods=["GET"])
def chat_status():
    """檢查 Gemini 模型狀態"""
    try:
        from core.gemini_client import gemini_model
        status = "ready" if gemini_model else "not_ready"
        return jsonify({"model": "gemini-2.0-flash", "status": status}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
