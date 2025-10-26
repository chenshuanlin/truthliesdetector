# =====================================================================
# text_analyzer.py - AI 多模態可信度分析（自動偵測文字 / 圖片 / 網址 / 混合）
# =====================================================================

import os
import re
import logging
import numpy as np
try:
    import jieba
except Exception:
    jieba = None

try:
    import requests
except Exception:
    requests = None

from urllib.parse import urlparse
try:
    from bs4 import BeautifulSoup
except Exception:
    BeautifulSoup = None

try:
    from sentence_transformers import SentenceTransformer
except Exception:
    SentenceTransformer = None

from core.model_loader import get_model

# ✅ 匯入 Gemini 功能（自動含 Vision 模式）
try:
    from core.gemini_client import (
        ask_gemini_vision_score,
        ask_gemini_combined
    )
except ImportError:
    ask_gemini_vision_score = None
    ask_gemini_combined = None


# ==========================================================
# 模型初始化
# ==========================================================
try:
    logging.info("📦 載入語意模型 SentenceTransformer all-MiniLM-L6-v2...")
    _semantic_model = SentenceTransformer("all-MiniLM-L6-v2")
    logging.info("✅ 語意模型載入完成")
except Exception as e:
    logging.error(f"❌ 語意模型載入失敗：{e}")
    _semantic_model = None


# ==========================================================
# 🧠 主分析函式（自動判斷模態）
# ==========================================================
def analyze_text(text: str, image_path: str = None) -> dict:
    """
    智慧分析流程：
    1️⃣ 自動判斷輸入是網址 / 圖片 / 純文字 / 混合
    2️⃣ 自動爬取新聞文字內容（若為網址）
    3️⃣ LightGBM 模型預測文字可信度
    4️⃣ 呼叫 Gemini 進行圖片 / 混合真偽分析
    5️⃣ 分數融合 + 生成摘要
    """
    model = get_model()
    if model is None:
        raise RuntimeError("❌ LightGBM 模型未載入")

    text = (text or "").strip()
    if not text and not image_path:
        return {"error": "未輸入任何內容"}

    # ======================================================
    # Step 1️⃣ 判斷內容類型
    # ======================================================
    mode = "文字"
    if re.match(r"^https?://", text):
        mode = "網址"
    elif image_path and text:
        mode = "混合"
    elif image_path:
        mode = "圖片"

    logging.info(f"🧩 偵測輸入模式：{mode}")

    # ======================================================
    # Step 2️⃣ 若是網址 → 爬取文字
    # ======================================================
    if mode == "網址":
        try:
            logging.info(f"🌐 偵測到網址，開始爬取內容：{text}")
            text = fetch_url_text(text)
            logging.info(f"✅ 網頁文字擷取完成（長度 {len(text)}）")
        except Exception as e:
            logging.warning(f"⚠️ 網頁爬取失敗：{e}")
            text = f"（無法擷取網頁內容）{text}"

    # ======================================================
    # Step 3️⃣ LightGBM 文字預測
    # ======================================================
    features = extract_features(text)
    score, level = predict_credibility(features)
    summary = generate_summary(text, score, level)

    # ======================================================
    # Step 4️⃣ 圖片分析（若有）
    # ======================================================
    vision_result = None
    final_score = score  # 預設為文字可信度

    try:
        if mode == "圖片" and ask_gemini_vision_score:
            logging.info("🖼️ 進行 Gemini 單張圖片分析")
            vision_result = ask_gemini_vision_score(
                "請判斷這張圖片是否真實或被篡改，並簡短說明理由。",
                image_path
            )

            v_score = vision_result["score"]
            final_score = v_score
            summary += f"\n📸 圖片分析可信度：{v_score:.2f}"

        elif mode == "混合" and ask_gemini_combined:
            logging.info("🧠 進行 Gemini 圖文綜合分析")
            combined_result = ask_gemini_combined(
                "這是一則圖文內容，請綜合評估真實性與一致性。",
                image_path
            )

            vision_result = combined_result
            v_score = combined_result["score"]
            final_score = round((score + v_score) / 2, 4)
            summary += (
                f"\n🧩 圖文綜合分析：可信度 {final_score:.2f}。"
            )

    except Exception as e:
        logging.warning(f"⚠️ Gemini 圖像分析失敗：{e}")

    # ======================================================
    # Step 5️⃣ 回傳結果
    # ======================================================
    return {
        "mode": mode,
        "score": round(final_score, 4),
        "level": convert_score_to_label(final_score),
        "summary": summary,
        "features_used": features,
        "keywords": extract_keywords(text),
        "category": guess_category(text),
        "text_preview": text[:120],
        "has_media": bool(image_path),
        "vision_result": vision_result,
        "status": "ok",
    }


# ==========================================================
# 🔍 LightGBM 預測
# ==========================================================
def predict_credibility(features):
    model = get_model()
    try:
        features_array = np.array([features], dtype=float)
        raw_score = model.predict(features_array)

        if len(raw_score.shape) > 1 and raw_score.shape[1] > 1:
            class_probs = raw_score[0]
            top_idx = int(np.argmax(class_probs))
            score = float(class_probs[top_idx])
            label_map = ["極低", "低", "中", "高", "極高", "未知"]
            level = label_map[top_idx] if top_idx < len(label_map) else "未知"
        else:
            score = float(np.ravel(raw_score)[0])
            score = float(np.clip(score, 0.0, 1.0))
            level = convert_score_to_label(score)
    except Exception as e:
        logging.error(f"⚠️ 模型預測失敗：{e}")
        score, level = 0.0, "未知"

    return score, level


# ==========================================================
# 🌐 自動爬取新聞文字
# ==========================================================
def fetch_url_text(url: str) -> str:
    headers = {"User-Agent": "Mozilla/5.0 (compatible; TruthLiesDetector/1.0)"}
    resp = requests.get(url, headers=headers, timeout=8)
    resp.encoding = resp.apparent_encoding
    soup = BeautifulSoup(resp.text, "html.parser")

    for selector in [
        "article",
        "div.article-content__editor",
        "div#story_body_content",
        "div.story",
        "section.article-body",
    ]:
        node = soup.select_one(selector)
        if node:
            text = node.get_text(separator=" ", strip=True)
            if len(text) > 100:
                return text

    return " ".join(
        [p.get_text(strip=True) for p in soup.find_all("p") if len(p.get_text()) > 10]
    )


# ==========================================================
# ✨ 特徵抽取
# ==========================================================
def extract_features(text: str) -> list:
    try:
        tokens = list(jieba.cut(text))
        word_count = len(tokens)
        url_match = re.search(r'https?://[^\s]+', text)
        has_url = 1 if url_match else 0
        domain_score = 0.5

        if has_url:
            domain = urlparse(url_match.group()).netloc
            domain_score = get_domain_score(domain)

        hyperbole_words = ["驚人", "爆料", "震撼", "絕對", "真相", "曝光"]
        emotive_words = ["氣炸", "哭了", "怒了", "慘了", "超扯"]
        hyperbole_score = sum(w in text for w in hyperbole_words) / len(hyperbole_words)
        emotive_score = sum(w in text for w in emotive_words) / len(emotive_words)

        semantic_strength = 0.0
        if _semantic_model:
            emb = _semantic_model.encode(text)
            semantic_strength = float(np.mean(np.abs(emb))) / 10

        return [
            round(domain_score, 2),
            1.0 if word_count > 50 else 0.5,
            round(hyperbole_score, 2),
            round(emotive_score, 2),
            has_url,
            semantic_strength,
            min(word_count / 200, 1.0),
            np.random.uniform(0.3, 0.9)
        ]
    except Exception as e:
        logging.error(f"⚠️ 特徵擷取失敗：{e}")
        return [0.5] * 8


# ==========================================================
# 🔧 輔助函式群
# ==========================================================
def get_domain_score(domain: str) -> float:
    trusted = {
        "cna.com.tw": 5.0, "udn.com": 4.8, "ettoday.net": 4.2,
        "setn.com": 3.5, "businesstoday.com.tw": 3.8, "ltn.com.tw": 4.5
    }
    return trusted.get(domain, 2.5)


def convert_score_to_label(score: float) -> str:
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


def generate_summary(text: str, score: float, level: str) -> str:
    desc = {
        "極高": "內容清晰、來源穩定，可信度極高。",
        "高": "語氣中性、引用來源明確，可信度偏高。",
        "中": "可信度中等，建議搭配來源進一步查證。",
        "低": "含誇張或情緒化用語，請小心求證。",
        "極低": "疑似不實或釣魚訊息，請勿輕信或轉傳。",
        "未知": "目前無法明確判斷可信度。"
    }.get(level, "未知可信度。")
    return f"模型分析結果顯示：可信度為「{level}」（分數 {score:.2f}）。{desc}"


def extract_keywords(text: str, top_k=5):
    words = [w for w in jieba.cut(text) if len(w) > 1]
    freq = {}
    for w in words:
        freq[w] = freq.get(w, 0) + 1
    keywords = sorted(freq, key=freq.get, reverse=True)[:top_k]
    return ", ".join(keywords)


def guess_category(text: str):
    if any(k in text for k in ["選舉", "政府", "政策", "總統"]):
        return "政治"
    elif any(k in text for k in ["影劇", "偶像", "電影", "藝人", "演唱會"]):
        return "娛樂"
    elif any(k in text for k in ["詐騙", "疫情", "健康", "醫療", "犯罪"]):
        return "社會"
    else:
        return "其他"
