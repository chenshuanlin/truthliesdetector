import requests
from bs4 import BeautifulSoup
import pyperclip
import re
import urllib.parse
import time
import json
import os
import argparse
import logging
from typing import List, Dict, Tuple, Optional
import numpy as np
import lightgbm as lgb
from pathlib import Path
import psycopg2
from psycopg2 import sql

# optional imports for external services
try:
    from duckduckgo_search import DDGS
except Exception:
    DDGS = None
try:
    from serpapi import GoogleSearch
except Exception:
    GoogleSearch = None
try:
    import google.generativeai as genai
except Exception:
    genai = None
    types = None

# ==============================================================================
# I. 系統配置與服務金鑰
# ==============================================================================

DOMAIN_CREDIBILITY_MAP = {
    'cna.com.tw': 5.0, 'udn.com': 4.5, 'setn.com': 3.0, 'www.facebook.com': 2.5,
    'ptt.cc': 2.0, 'bogus-news.xyz': 1.0
}
EMOTIONAL_INDICATORS = [
    '驚人', '絕對', '震驚', '離譜', '不可思議', '大爆發', '小心', '慘了',
    '怒吼', '崩潰', '獨家', '急轉直下', '馬上看', '瘋傳', '秘密'
]

SERPAPI_API_KEY = "d74cf3f39503404c0426005f0c23cc59246f60084b198b8dcbee955b04448452"
GEMINI_API_KEY = "AIzaSyBZoPr5y8AM3c9VcM5ahIAqfw0ODtRAtQk"

# === 新增：資料庫設定 ===
DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "truthliesdetector",
    "user": "postgres",
    "password": "1234",
}

# === 修改後：所有文章一律寫入爬取當下時間（選項 B）
from datetime import datetime

def insert_article_to_db(
    *,
    title: str,
    content: str,
    category: Optional[str],
    source_link: Optional[str],
    media_name: Optional[str],
    reliability_score: Optional[int],
    published_time: Optional[str] = None,
) -> None:
    """
    將文章寫入資料庫。
    ✔ 選項 B：published_time 一律為「現在時間」，不抓真正新聞發布時間。
    """
    try:
        crawled_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")  # ← 修改點（固定時間來源）

        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()

        insert_sql = """
            INSERT INTO public.articles
                (title, content, category, source_link, media_name, published_time, reliability_score)
            VALUES
                (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (source_link)
            DO UPDATE SET
                reliability_score = EXCLUDED.reliability_score,
                title = EXCLUDED.title,
                content = EXCLUDED.content,
                media_name = EXCLUDED.media_name,
                published_time = EXCLUDED.published_time;
        """

        cur.execute(insert_sql, (
            title, content, category, source_link, media_name, crawled_time, reliability_score
        ))

        conn.commit()
        cur.close()
        conn.close()

        print(f"📝 已寫入資料庫：{(title or '')[:30]}... (score={reliability_score}, time={crawled_time})")

    except Exception as e:
        print(f"❌ 寫入資料庫失敗：{e}")
# ==============================================================================
# II. 內容擷取與預處理模組 (Extraction & Preprocessing)
# ==============================================================================

def preprocess_document_text(text: str) -> str:
    """清理常見的網頁噪音、廣告和冗餘空間。"""
    text = re.sub(r'\(C\) 版權所有|All rights reserved|分享給好友|點擊下載|繼續閱讀|相關新聞.*', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\n{2,}', '\n', text)
    text = re.sub(r'\s{2,}', ' ', text).strip()
    return text


def fetch_and_clean_url(url: str) -> Tuple[str, str, str, Optional[str]]:
    """
    從 URL 抓取標題、網域和淨化後的主文本。
    （published_time 目前不處理 → 固定回傳 None）
    """
    print(f"-> 正在擷取網址內容: {url}")
    domain = urllib.parse.urlparse(url).netloc

    headers = {
        'User-Agent': (
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        )
    }

    max_attempts = 3
    for attempt in range(1, max_attempts + 1):
        try:
            time.sleep(1.0 * attempt)
            response = requests.get(url, headers=headers, timeout=10, allow_redirects=True)
            response.raise_for_status()
            response.encoding = response.apparent_encoding

            soup = BeautifulSoup(response.text, 'html.parser')

            # 標題
            title = soup.title.string.strip() if soup.title and soup.title.string else "未偵測到標題"

            # 主內容
            main_text = ""
            content_selectors = [
                'article',
                'div[itemprop="articleBody"]',
                'div.article-content',
                'div.entry-content',
                'div#main-content'
            ]

            for selector in content_selectors:
                article_body = soup.select_one(selector)
                if article_body and len(article_body.get_text(strip=True)) > 200:
                    main_text = article_body.get_text(separator='\n', strip=True)
                    break

            if not main_text and soup.body:
                main_text = soup.body.get_text(separator='\n', strip=True)

            main_text = preprocess_document_text(main_text)

            # ⭐ 固定回傳 published_time=None
            return title, domain, main_text, None

        except requests.exceptions.RequestException as e:
            logging.debug(f"fetch attempt {attempt} failed for {url}: {e}")
            if attempt == max_attempts:
                return "提取失敗", domain, f"ERR: {e}", None
            continue

        except Exception as e:
            logging.debug(f"processing error for {url}: {e}")
            return "提取失敗", domain, f"ERR: {e}", None


# ==============================================================================
# III. 搜尋與備援模組 (Search & Fallback)
# ==============================================================================

def perform_ddgs_search(query: str, max_results: int = 20) -> List[Dict[str, str]]:
    """使用 DuckDuckGo (DDGS) 進行關鍵字搜尋。"""
    print(f"-> 正在執行 DuckDuckGo 關鍵字搜尋: {query} (最多 {max_results} 筆)")
    results = []

    try:
        with DDGS() as ddgs:
            ddgs_results = ddgs.text(q=query, region='tw-zh', max_results=max_results)

            for r in ddgs_results:
                results.append({
                    'title': r.get('title'),
                    'link': r.get('href'),
                    'snippet': r.get('body', '無摘要')
                })
            time.sleep(3)
    except Exception as e:
        print(f"  > DDGS 搜尋失敗: {e}")

    return results


def perform_serpapi_fallback(query: str, max_results: int = 10) -> List[Dict[str, str]]:
    """SerpApi (Google) 備援搜尋。"""
    print(f"-> 正在執行 SerpApi 備用搜尋: {query} (最多 {max_results} 筆)")

    if not SERPAPI_API_KEY:
        print("  > ❌ SerpApi 金鑰未設置！跳過備援搜尋。")
        return []

    params = {
        "engine": "google",
        "q": query,
        "api_key": SERPAPI_API_KEY,
        "gl": "tw",
        "hl": "zh-tw",
        "num": max_results
    }

    results = []
    try:
        search = GoogleSearch(params)
        data = search.get_dict()

        for item in data.get("organic_results", []):
            results.append({
                "title": item.get("title"),
                "link": item.get("link"),
                "snippet": item.get("snippet", "")
            })
        return results

    except Exception as e:
        print(f"  > ❌ SerpApi 搜尋失敗: {e}")
        return []
# ==============================================================================
# IV. 特徵工程模組 (Feature Engineering)
# ==============================================================================

def get_domain_credibility(domain: str) -> float:
    """根據預設對應表獲取網域可信度分數。"""
    normalized_domain = domain.replace("www.", "")
    return DOMAIN_CREDIBILITY_MAP.get(normalized_domain, 3.0)


def calculate_article_features(url: str, title: str, content: str, domain: str) -> Dict[str, float]:
    """計算文章內容的結構化特徵，供 LLM 判別參考。"""
    
    # 若擷取失敗，直接回傳最低特徵
    if "提取失敗" in title or not content:
        return {
            "score_source": 1.0,
            "emotion_ratio": 0.0,
            "text_length": 0.0,
            "final_crawler_score": 1.0,
            "punctuation_density": 0.0
        }

    features = {}

    # (1) 來源可信度（data source credibility）
    features["score_source"] = get_domain_credibility(domain)

    # (2) 文章長度
    text_len = len(content)
    features["text_length"] = float(text_len)

    # (3) 情緒化詞彙比例
    emo_count = sum(content.count(kw) for kw in EMOTIONAL_INDICATORS)
    features["emotion_ratio"] = (emo_count / (text_len / 100)) if text_len > 100 else float(emo_count)

    # (4) 標點密度
    exclamation = content.count("!") + content.count("！")
    question = content.count("?") + content.count("？")
    features["punctuation_density"] = (
        (exclamation + question) / (text_len / 100)
        if text_len > 100 else float(exclamation + question)
    )

    # (5) 基礎可信度計算（你的原始邏輯：來源分數 - 情緒 - 標點）
    crawler_score = features["score_source"]
    crawler_score -= features["emotion_ratio"] * 0.5
    crawler_score -= features["punctuation_density"] * 0.2

    features["final_crawler_score"] = max(1.0, min(5.0, crawler_score))

    return features


# ==============================================================================
# V. LLM 判別模組（Gemini or 模擬模式）
# ==============================================================================

class AnalysisOutput:
    """LLM 輸出的結構化結果。"""

    def __init__(self, confidence_score: float, credibility_level: str, summary: str):
        self.confidence_score = confidence_score
        self.credibility_level = credibility_level
        self.summary = summary


class CredibilityAnalyzerClient:
    """LLM 客戶端：負責與 Gemini API 溝通，或在無 API 模式下進行模擬。"""

    def __init__(self, api_key: str):
        if api_key == "YOUR_GEMINI_API_KEY_HERE":
            self.client = None
            print("❌ Gemini API 金鑰未設置，使用模擬模式")
            return

        # 嘗試啟動 Gemini
        try:
            if genai is not None:
                genai.configure(api_key=api_key)
                self.client = genai
                print("[OK] Gemini 初始化成功")
            else:
                self.client = None
                print("❌ 找不到 google-generativeai 套件，改用模擬模式")
        except Exception as e:
            print(f"❌ Gemini 初始化失敗: {e}")
            self.client = None

    # ---------------------------
    # 主要 LLM API 呼叫
    # ---------------------------
    def perform_llm_analysis(self, title: str, content: str, features: Dict[str, float]) -> AnalysisOutput:

        # =====================
        # 模擬模式
        # =====================
        if self.client is None:
            time.sleep(1)  # 模擬延遲

            score = min(1.0, features["final_crawler_score"] / 5.0 + 0.1)
            level = "中度可信/可疑 (模擬)" if score > 0.5 else "低度可信 (模擬)"
            summary = f"模擬分析：文章爬蟲分數 {features['final_crawler_score']:.2f}"

            return AnalysisOutput(score, level, summary)

        # =====================
        # 實際 Gemini LLM
        # =====================
        prompt = f"""
        你是一位專業的新聞可信度分析師。
        請依文章內容與特徵輸出 JSON。

        標題：{title}
        主內容（前1500字）：{content[:1500]}
        基礎爬蟲分數(1-5)：{features['final_crawler_score']:.2f}
        來源可信度：{features['score_source']:.2f}
        情緒化比例：{features['emotion_ratio']:.2f}

        請輸出 JSON：
        {{
            "credibility_level": "...",
            "confidence_score": 0.0~1.0,
            "summary": "..."
        }}
        """

        try:
            model = self.client.GenerativeModel(
                "gemini-2.0-flash",
                generation_config={
                    "response_mime_type": "application/json"
                }
            )

            response = model.generate_content(prompt)
            data = json.loads(response.text)

            return AnalysisOutput(
                confidence_score=data.get("confidence_score", 0.5),
                credibility_level=data.get("credibility_level", "LLM 分析失敗"),
                summary=data.get("summary", "")
            )

        except Exception as e:
            print("LLM 錯誤，啟用 fallback 模式:", e)

            score = min(1.0, features["final_crawler_score"] / 5.0)
            return AnalysisOutput(
                confidence_score=score,
                credibility_level="模擬回退",
                summary="LLM 失敗，使用爬蟲評估替代。"
            )
# ==============================================================================
# VI. 報告生成模組 (Report Generation Module)
# ==============================================================================

def generate_final_report(
    user_input: str,
    mode: str,
    llm_report: Optional[AnalysisOutput] = None,
    features: Optional[Dict[str, float]] = None,
    all_analyses: Optional[List[Dict]] = None,
    content: str = ""
) -> str:
    """根據分析模式生成結構化報告。"""

    report = ["\n" + "=" * 80]
    report.append("                 【資訊可信度分析報告】")
    report.append(f"生成時間: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("=" * 80)

    # -------------------------------
    # 單一網址報告
    # -------------------------------
    if mode == "URL":
        report.append(f"【分析類型】: 單一網址深度分析")
        report.append(f"【目標網址】: {user_input}")
        report.append(f"【網頁標題】: {content[:80]}...")
        report.append("-" * 40)

        if llm_report:
            report.append("--- 🤖 LLM 深度分析結果 ---")
            report.append(f"可信度等級: {llm_report.credibility_level}")
            report.append(f"可信度分數: {llm_report.confidence_score:.3f}")
            report.append(f"分析摘要:\n{llm_report.summary}")

        if features:
            report.append("\n--- 📊 爬蟲特徵 ---")
            for k, v in features.items():
                report.append(f"  - {k}: {v}")

        report.append("\n--- 📄 內容片段 ---")
        report.append(content[:1500] + "...")

    # -------------------------------
    # 關鍵字批量分析報告
    # -------------------------------
    elif mode == "KEYWORD" and all_analyses:
        report.append(f"【分析類型】: 關鍵字批量分析")
        report.append(f"【搜尋關鍵字】: {user_input}")
        report.append(f"【成功分析文章數】: {len(all_analyses)}")
        report.append("-" * 80)
        report.append("  索引 | 分數 | 可信等級 | 網域 | 標題")
        report.append("-" * 80)

        for item in all_analyses:
            idx = item["index"]
            score = item.get("ai_score", 0.0)
            level = item.get("ai_level", "未知")
            domain = item.get("domain", "-")
            title = item.get("title", "無標題")[:40]

            report.append(
                f"{idx:<5} | {score:.3f} | {level:<10} | {domain:<15} | {title}"
            )

    else:
        report.append("⚠ 未找到可分析的內容。")

    report.append("\n" + "=" * 80)
    return "\n".join(report)


# ==============================================================================
# VII. 主應用邏輯 (Main Application Logic)
# ==============================================================================

def is_valid_url(text: str) -> bool:
    """檢查輸入字串是否為 URL。"""
    return text.startswith(("http://", "https://"))


def run_analysis_system():
    """主流程：網址模式 + 關鍵字模式"""

    # argparse 設定
    parser = argparse.ArgumentParser(description="新聞可信度分析系統")
    parser.add_argument("--max-results", type=int, default=20)
    parser.add_argument("--min-length", type=int, default=100)
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--query", default=None)
    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)

    print("\n--- 資訊可信度分析系統啟動 ---\n")

    analyzer = CredibilityAnalyzerClient(api_key=GEMINI_API_KEY)

    if args.query:
        user_input = args.query.strip()
    else:
        user_input = input("請輸入網址或關鍵字：").strip()

    # ================================
    # 🔥 模式 A：URL 深度分析
    # ================================
    if is_valid_url(user_input):
        print(f"→ 開始擷取網址: {user_input}")

        title, domain, content = fetch_and_clean_url(user_input)

        if "提取失敗" in title or len(content) < args.min_length:
            print("❌ 文章擷取失敗或內容過短")
            return

        # 特徵工程
        features = calculate_article_features(user_input, title, content, domain)

        # LLM 深度分析
        llm_report = analyzer.perform_llm_analysis(title, content, features)

        # ⭐ 發布時間（簡易：抓取時間）
        crawled_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # 寫入資料庫（含 reliability_score）
        insert_article_to_db(
            title=title,
            content=content,
            category=None,
            source_link=user_input,
            media_name=domain,
            reliability_score=int(features["final_crawler_score"]),
            published_time=crawled_time,
        )

        print("🟢 分析完成！文章已存入資料庫。")

        # 顯示報告
        final_report = generate_final_report(
            user_input,
            mode="URL",
            llm_report=llm_report,
            features=features,
            content=content
        )

        print(final_report)
        return

    # ================================
    # 🔥 模式 B：關鍵字搜尋批次分析
    # ================================
    print(f"→ 進行搜尋: {user_input}")

    results = perform_ddgs_search(user_input, max_results=args.max_results)
    if not results:
        results = perform_serpapi_fallback(user_input, max_results=10)

    all_items = []

    for index, item in enumerate(results, start=1):
        url = item.get("link")
        if not url:
            continue

        print(f"[{index}] 擷取文章：{url}")

        title, domain, content = fetch_and_clean_url(url)

        if "提取失敗" in title or len(content) < args.min_length:
            print("  → 跳過（擷取失敗或內容太短）")
            continue

        features = calculate_article_features(url, title, content, domain)

        # LLM 分析（或 fallback）
        llm_report = analyzer.perform_llm_analysis(title, content, features)

        # ⭐ 可靠度分數（使用基礎爬蟲分數）
        reliability_int = int(features["final_crawler_score"])

        crawled_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # 寫入資料庫
        insert_article_to_db(
            title=title,
            content=content,
            category=user_input,
            source_link=url,
            media_name=domain,
            reliability_score=reliability_int,
            published_time=crawled_time,
        )

        all_items.append({
            "index": index,
            "title": title,
            "domain": domain,
            "ai_score": llm_report.confidence_score,
            "ai_level": llm_report.credibility_level,
        })

    # 顯示總結報告
    final_report = generate_final_report(
        user_input,
        mode="KEYWORD",
        all_analyses=all_items,
        content=""
    )

    print(final_report)
# ==============================================================================
# V. AI 判別服務客戶端 (LLM Client Interface)
# ==============================================================================

class AnalysisOutput:
    """LLLLM 服務的結構化輸出物件。"""
    def __init__(self, confidence_score: float, credibility_level: str, summary: str):
        self.confidence_score = confidence_score
        self.credibility_level = credibility_level
        self.summary = summary


class CredibilityAnalyzerClient:
    """用於與 Gemini 呼叫，產生深度可信度分析。"""

    def __init__(self, api_key: str):
        if api_key == "YOUR_GEMINI_API_KEY_HERE":
            self.client = None
            print("❌ Gemini 金鑰未設定 → 模擬模式")
        else:
            try:
                if genai is not None:
                    genai.configure(api_key=api_key)
                    self.client = genai
                    print("⭐ Gemini 模型已啟動")
                else:
                    self.client = None
                    print("⚠ google-generativeai 模組未安裝 → 模擬模式")
            except Exception as e:
                self.client = None
                print(f"⚠ Gemini 初始化失敗：{e} → 模擬模式")

    # --------------------------------------------------------------
    # perform_llm_analysis(): 給 URL 或關鍵字主流程使用（維持原樣）
    # --------------------------------------------------------------
    def perform_llm_analysis(self, title: str, content: str, features: Dict[str, float]) -> AnalysisOutput:

        if self.client is None:
            # fallback 模式
            score = min(1.0, features["final_crawler_score"] / 5.0 + 0.1)
            level = "可疑（模擬）" if score < 0.5 else "可信（模擬）"
            summary = f"模擬 LLM：依 crawler_score={features['final_crawler_score']:.2f} 推估。"
            return AnalysisOutput(score, level, summary)

        # 呼叫 Gemini
        prompt = f"""
你是一位新聞可信度分析師。請根據內容和特徵輸出 JSON：

格式如下：
{{
    "credibility_level": "...",
    "confidence_score": 0.0~1.0,
    "summary": "..."
}}

文章標題: {title}
文章內容（前1500字）: {content[:1500]}
基礎分數: {features['final_crawler_score']:.2f}
        """

        try:
            model = self.client.GenerativeModel(
                "gemini-2.0-flash",
                generation_config={
                    "response_mime_type": "application/json"
                }
            )
            resp = model.generate_content(prompt)
            data = json.loads(resp.text)

            return AnalysisOutput(
                confidence_score=data.get("confidence_score", 0.5),
                credibility_level=data.get("credibility_level", "未知"),
                summary=data.get("summary", "")
            )

        except Exception as e:
            print(f"⚠ LLM 呼叫失敗：{e}")
            score = min(1.0, features["final_crawler_score"] / 5.0)
            return AnalysisOutput(score, "模擬回退", "Gemini 呼叫失敗 → 使用爬蟲分數")

    # --------------------------------------------------------------
    # 🧠 annotate_features() — 你的超完整版本（完整保留）
    # --------------------------------------------------------------
    def annotate_features(self, title: str, content: str, url: str = "") -> Tuple[Dict[str, float], str]:
        """
        讓 Gemini（或模擬模式）輸出：
        - 8個特徵欄位（0–1 小數值）
        - short_judgement（不超過 30 字）

        ⭐ 這段是你原本的運算邏輯，我完整保留，只修小 bug，不動邏輯
        """

        # -------------------------------
        # 若沒有 LLM → 使用 heuristics 模擬
        # -------------------------------
        if self.client is None:
            domain = urllib.parse.urlparse(url).netloc if url else ""
            dscore = get_domain_credibility(domain) / 5.0

            # 標題與內文重疊度
            title_tokens = set(re.findall(r"\w+", title.lower()))
            body_tokens = set(re.findall(r"\w+", content.lower()))
            overlap = (
                len(title_tokens & body_tokens) / max(1, len(title_tokens))
                if title_tokens and body_tokens else 0.0
            )

            # 情緒化字詞密度
            emotion_count = sum(content.count(w) for w in EMOTIONAL_INDICATORS)
            text_len = max(1, len(content))
            emotive_density = min(1.0, emotion_count / (text_len / 100))

            # 證據品質（有數字、DOI、網址）
            evidence = 0.0
            if re.search(r"\b\d{4}\b", content): evidence += 0.3
            if re.search(r"doi\.org|pubmed|arxiv", content, flags=re.I): evidence += 0.5
            if re.search(r"https?://\S+", content): evidence += 0.2
            evidence = min(1.0, evidence)

            # 廣告密度
            ad = 0.0
            if re.search(r"(購買|贊助|廣告|buy now|discount)", content, flags=re.I):
                ad = 0.7

            features = {
                "source_entity_score": dscore,
                "domain_score": dscore,
                "title_body_consistency": min(1.0, overlap * 1.2),
                "evidence_quality": evidence,
                "ad_promo_intensity": ad,
                "hyperbole_score": min(1.0, emotive_density * 0.8),
                "emotive_clickbait_density": emotive_density,
                "title_body_embedding_cosine": min(1.0, overlap),
            }

            # 30字內短評
            if features["domain_score"] > 0.8 and features["evidence_quality"] >= 0.6:
                short = "高度可信"
            elif features["emotive_clickbait_density"] > 0.6:
                short = "可疑（情緒化內容）"
            elif features["title_body_consistency"] < 0.4:
                short = "標題與內容不符 → 可疑"
            else:
                short = "中度可信"

            return features, short

        # -------------------------------
        # 真正呼叫 Gemini
        # -------------------------------
        try:
            prompt = (
                "請以 JSON 回傳這些特徵（0~1 小數），"
                "且回傳 short_judgement（中文 30 字內）。\n\n"
                f"title: {title}\n\n"
                f"content: {content[:2000].replace('\n', ' ')}...\n\n"
                "必須輸出：\n"
                "{"
                "\"source_entity_score\":0.0,"
                "\"domain_score\":0.0,"
                "\"title_body_consistency\":0.0,"
                "\"evidence_quality\":0.0,"
                "\"ad_promo_intensity\":0.0,"
                "\"hyperbole_score\":0.0,"
                "\"emotive_clickbait_density\":0.0,"
                "\"title_body_embedding_cosine\":0.0,"
                "\"short_judgement\":\"...\""
                "}"
            )

            model = self.client.GenerativeModel(
                "gemini-2.0-flash",
                generation_config={
                    "response_mime_type": "application/json",
                    "response_schema": {
                        "type": "object",
                        "properties": {
                            "source_entity_score": {"type": "number"},
                            "domain_score": {"type": "number"},
                            "title_body_consistency": {"type": "number"},
                            "evidence_quality": {"type": "number"},
                            "ad_promo_intensity": {"type": "number"},
                            "hyperbole_score": {"type": "number"},
                            "emotive_clickbait_density": {"type": "number"},
                            "title_body_embedding_cosine": {"type": "number"},
                            "short_judgement": {"type": "string"},
                        },
                        "required": [
                            "source_entity_score",
                            "domain_score",
                            "title_body_consistency",
                            "evidence_quality",
                            "ad_promo_intensity",
                            "hyperbole_score",
                            "emotive_clickbait_density",
                            "title_body_embedding_cosine",
                            "short_judgement",
                        ]
                    }
                }
            )

            resp = model.generate_content(prompt)
            data = json.loads(resp.text)

            features = {
                key: float(data.get(key, 0.0))
                for key in [
                    "source_entity_score",
                    "domain_score",
                    "title_body_consistency",
                    "evidence_quality",
                    "ad_promo_intensity",
                    "hyperbole_score",
                    "emotive_clickbait_density",
                    "title_body_embedding_cosine"
                ]
            }

            short = data.get("short_judgement", "")[:30]
            return features, short

        except Exception as e:
            print(f"⚠ annotate_features LLM 失敗 → fallback: {e}")

            # fallback 模擬結果
            return {
                "source_entity_score": 0.5,
                "domain_score": 0.5,
                "title_body_consistency": 0.6,
                "evidence_quality": 0.5,
                "ad_promo_intensity": 0.3,
                "hyperbole_score": 0.4,
                "emotive_clickbait_density": 0.3,
                "title_body_embedding_cosine": 0.7
            }, "模擬結果"
# ==============================================================================
# VII. 主應用程式邏輯 (Main Application Logic)
# ==============================================================================

def is_valid_url(text: str) -> bool:
    return text.startswith(("http://", "https://"))


def run_analysis_system():
    # 自動尋找 LightGBM 模型
    discovered_model = None
    try:
        candidates = list(Path(".").rglob("*auth_level*.txt"))
        if candidates:
            discovered_model = str(candidates[0].as_posix())
    except Exception:
        discovered_model = None

    parser = argparse.ArgumentParser(description="資訊可信度輔助系統")
    parser.add_argument("--max-results", type=int, default=20)
    parser.add_argument("--min-length", type=int, default=100)
    parser.add_argument("--save", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--model", default=(discovered_model or "model_auth_level/auth_level_lgbm.txt"))
    parser.add_argument("--query", default=None)
    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    print("--- 資訊可信度系統：擷取 + LLM 分析 ---")

    analyzer = CredibilityAnalyzerClient(api_key=GEMINI_API_KEY)

    # -------------------------------------------------------
    # 載入 LightGBM 模型
    # -------------------------------------------------------
    booster = None
    model_path = Path(args.model)

    if not model_path.exists():
        print(f"⚠ 模型不存在: {model_path} → 自動搜尋中...")
        candidates = list(Path(".").rglob("*auth_level*.txt"))
        if candidates:
            model_path = candidates[0]
            print(f"⭐ 自動找到模型: {model_path}")
        else:
            print("❌ 找不到模型 → 略過模型預測。")

    if model_path.exists():
        try:
            booster = lgb.Booster(model_file=str(model_path))
            print(f"[OK] 已載入模型 {model_path}")
        except Exception as e:
            print(f"❌ 模型載入失敗: {e}")

    # -------------------------------------------------------
    # 使用者輸入
    # -------------------------------------------------------
    if args.query:
        user_input = args.query.strip()
    else:
        user_input = input("請輸入網址或關鍵字：").strip()

    output_content = ""
    skipped = []

    # =====================================================================
    # 🟦 A 模式 — 直接分析單一網址
    # =====================================================================
    if is_valid_url(user_input):

        # 取回標題 / 內容 / domain / 發布時間
        title, domain, content, published_time = fetch_and_clean_url(user_input)

        if "提取失敗" in title or not content or len(content) < args.min_length:
            print("❌ 擷取失敗或內容不足")
            items = []
        else:
            items = [{
                "title": title,
                "url": user_input,
                "domain": domain,
                "content": content,
                "published_time": published_time
            }]

        enriched = []

        for it in items:
            # ----------------------------------------------------------
            # LLM 特徵標註
            # ----------------------------------------------------------
            feats_ann, short = analyzer.annotate_features(it["title"], it["content"], it["url"])
            it["ann_features"] = feats_ann
            it["short_judgement"] = short

            # ----------------------------------------------------------
            # LightGBM 模型預測
            # ----------------------------------------------------------
            if booster is not None:
                feat_order = [
                    "source_entity_score", "domain_score", "title_body_consistency",
                    "evidence_quality", "ad_promo_intensity", "hyperbole_score",
                    "emotive_clickbait_density", "title_body_embedding_cosine"
                ]
                x = np.array([feats_ann.get(k, 0.0) for k in feat_order], dtype=float).reshape(1, -1)
                try:
                    proba = booster.predict(x, num_iteration=booster.best_iteration or None)
                    pred = int(np.argmax(proba, axis=1)[0]) + 1
                    it["model_score"] = int(pred)
                    it["model_proba"] = proba[0].tolist()
                except Exception:
                    it["model_score"] = 0
                    it["model_proba"] = []

            reliability = int(it.get("model_score") or 0)

            print(f"🧠 Debug: model_score={reliability}")

            # ----------------------------------------------------------
            # 寫入資料庫（含 published_time）
            # ----------------------------------------------------------
            insert_article_to_db(
                title=it["title"],
                content=it["content"],
                category=None,
                source_link=it["url"],
                media_name=it["domain"],
                reliability_score=reliability,
                published_time=it.get("published_time")
            )

            enriched.append(it)

        output_content = json.dumps(
            {"mode": "URL", "items": enriched},
            ensure_ascii=False,
            indent=2
        )

        print("\n[OK] URL 分析完成：")
        print(output_content)

    # =====================================================================
    # 🟦 B 模式 — 搜尋 + 批量分析
    # =====================================================================
    else:
        results = perform_ddgs_search(user_input, max_results=args.max_results)

        if not results:
            results = perform_serpapi_fallback(user_input, max_results=10)

        items = []

        if results:
            print("→ 開始批量擷取 ...")

            for i, item in enumerate(results, 1):
                url = item.get("link")
                if not url:
                    skipped.append((str(item), "no link"))
                    continue

                # 抓內容
                title, domain, content, published_time = fetch_and_clean_url(url)

                if "提取失敗" in title:
                    skipped.append((url, "fetch failed"))
                    continue

                if not content or len(content) < args.min_length:
                    skipped.append((url, "content too short"))
                    continue

                entry = {
                    "index": i,
                    "title": title,
                    "url": url,
                    "domain": domain,
                    "content": content,
                    "published_time": published_time
                }

                # ----------------------------------------------------------
                # LLM 特徵
                # ----------------------------------------------------------
                feats_ann, short = analyzer.annotate_features(title, content, url)
                entry["ann_features"] = feats_ann
                entry["short_judgement"] = short

                # ----------------------------------------------------------
                # LightGBM 預測
                # ----------------------------------------------------------
                if booster is not None:
                    feat_order = [
                        "source_entity_score", "domain_score", "title_body_consistency",
                        "evidence_quality", "ad_promo_intensity", "hyperbole_score",
                        "emotive_clickbait_density", "title_body_embedding_cosine"
                    ]
                    x = np.array([feats_ann.get(k, 0.0) for k in feat_order], dtype=float).reshape(1, -1)
                    try:
                        proba = booster.predict(x, num_iteration=booster.best_iteration or None)
                        pred = int(np.argmax(proba, axis=1)[0]) + 1
                        entry["model_score"] = int(pred)
                        entry["model_proba"] = proba[0].tolist()
                    except Exception:
                        entry["model_score"] = None
                        entry["model_proba"] = []

                reliability = int(entry.get("model_score") or 0)

                # ----------------------------------------------------------
                # DB 寫入
                # ----------------------------------------------------------
                insert_article_to_db(
                    title=title,
                    content=content,
                    category=user_input,
                    source_link=url,
                    media_name=domain,
                    reliability_score=reliability,
                    published_time=published_time
                )

                items.append(entry)
                print(f"[OK] {i}. {domain} 擷取完成")

            output_content = json.dumps(
                {"mode": "KEYWORD", "items": items, "skipped": len(skipped)},
                ensure_ascii=False,
                indent=2
            )

            print("\n⭐ 批量分析完成")
            print(output_content)

        else:
            output_content = json.dumps(
                {"mode": "KEYWORD", "items": [], "skipped": 0},
                ensure_ascii=False
            )
            print("⚠ 無搜尋結果")

    # =====================================================================
    # 儲存到 reports/
    # =====================================================================
    try:
        os.makedirs("reports", exist_ok=True)
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        fname = f"reports/raw_{timestamp}.json"
        with open(fname, "w", encoding="utf-8") as f:
            f.write(output_content)
        print(f"📁 已寫入：{fname}")
    except Exception as e:
        print(f"❌ 無法輸出 JSON：{e}")

    # =====================================================================
    # 複製到剪貼簿
    # =====================================================================
    try:
        pyperclip.copy(output_content)
        print("🎉 已複製到剪貼簿！")
    except Exception:
        print("⚠ 剪貼簿無法使用")



if __name__ == "__main__":
    run_analysis_system()
