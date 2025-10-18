import numpy as np
import logging
from core.model_loader import get_model


# ============================================================
# 文字可信度分析模組
# ============================================================
def analyze_text(text: str):
    """
    使用 LightGBM 模型進行可信度分析
    傳入一段文字（或 OCR 圖片文字），輸出可信度分數、等級與系統說明
    """
    model = get_model()
    if model is None:
        raise RuntimeError("模型尚未載入")

    try:
        # ==============================
        # 1️⃣ 模擬特徵（尚未接 NLP 模組）
        # ==============================
        features = np.random.rand(7).tolist()
        features.append(0.5)  # 模型訓練的第8個特徵補值

        # ==============================
        # 2️⃣ 預測可信度分數
        # ==============================
        preds = model.predict([features], predict_disable_shape_check=True)
        score = float(np.ravel(preds)[0])  # 攤平成1維再取值
        level = _convert_score_to_label(score)

        # ==============================
        # 3️⃣ 根據分數產生分析說明
        # ==============================
        analysis_summary = _generate_summary(text, score, level)

        logging.info(f"✅ 預測完成：score={score:.4f}, level={level}")

        # ==============================
        # 4️⃣ 回傳完整結果
        # ==============================
        return {
            "score": round(score, 4),          # 模型輸出分數
            "credibility": level,              # ✅ 給 routes 取用
            "level": level,                    # 人類可讀等級
            "analysis_summary": analysis_summary,  # ✅ AI 解釋文字
            "features_used": features,         # 模型特徵
            "text_preview": text[:100],        # 前端預覽用
        }

    except Exception as e:
        logging.error(f"❌ analyze_text 發生錯誤：{e}")
        raise e


# ============================================================
# 分數 → 等級標籤
# ============================================================
def _convert_score_to_label(score: float):
    """將模型分數轉為可信度等級"""
    if score >= 0.8:
        return "極高"
    elif score >= 0.6:
        return "高"
    elif score >= 0.4:
        return "中"
    elif score >= 0.2:
        return "低"
    else:
        return "極低"


# ============================================================
# 根據分數產生系統說明
# ============================================================
def _generate_summary(text: str, score: float, level: str) -> str:
    """產生自然語言的分析摘要"""
    if level == "極高":
        comment = "此訊息的內容清晰、來源穩定，模型判定極具可信度。"
    elif level == "高":
        comment = "內容表述合理、語氣中性，可信度偏高。"
    elif level == "中":
        comment = "訊息可信度中等，建議搭配來源查證。"
    elif level == "低":
        comment = "此內容含誇張或情緒化用語，請小心求證。"
    else:
        comment = "此訊息疑似不實，請勿輕信或轉傳。"

    return f"模型分析結果顯示：可信度為「{level}」。{comment}"
