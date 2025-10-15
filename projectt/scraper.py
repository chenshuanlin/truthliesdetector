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

# 💡 SerpApi 金鑰 (您的 Google 搜尋備援金鑰)
SERPAPI_API_KEY = "d74cf3f39503404c0426005f0c23cc59246f60084b198b8dcbee955b04448452"

# ⚠️ Gemini API 金鑰 (用於 LLM 深度分析，請務必替換！)
GEMINI_API_KEY = "AIzaSyBZoPr5y8AM3c9VcM5ahIAqfw0ODtRAtQk"

# ==============================================================================
# II. 內容擷取與預處理模組 (Extraction & Preprocessing) (略，與上一版相同)
# ==============================================================================

def preprocess_document_text(text: str) -> str:
    """清理常見的網頁噪音、廣告和冗餘空間。"""
    text = re.sub(r'\(C\) 版權所有|All rights reserved|分享給好友|點擊下載|繼續閱讀|相關新聞.*', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\n{2,}', '\n', text) 
    text = re.sub(r'\s{2,}', ' ', text).strip()
    return text

def fetch_and_clean_url(url: str) -> Tuple[str, str, str]:
    """從 URL 抓取標題、網域和淨化後的主文本。"""
    print(f"-> 正在擷取網址內容: {url}")
    domain = urllib.parse.urlparse(url).netloc
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }

    max_attempts = 3
    for attempt in range(1, max_attempts + 1):
        try:
            time.sleep(1.0 * attempt)  # backoff
            response = requests.get(url, headers=headers, timeout=10, allow_redirects=True)
            response.raise_for_status()
            response.encoding = response.apparent_encoding

            soup = BeautifulSoup(response.text, 'html.parser')
            title = soup.title.string.strip() if soup.title and soup.title.string else "未偵測到標題"

            main_text = ""
            # 使用 CSS selector 嘗試擷取文章主體（比直接 find 更可靠）
            content_selectors = ['article', 'div[itemprop="articleBody"]', 'div.article-content', 'div.entry-content', 'div#main-content']

            for selector in content_selectors:
                article_body = soup.select_one(selector)
                if article_body and len(article_body.get_text(strip=True)) > 200:
                    main_text = article_body.get_text(separator='\n', strip=True)
                    break

            if not main_text and soup.body:
                main_text = soup.body.get_text(separator='\n', strip=True)

            main_text = preprocess_document_text(main_text)
            return title, domain, main_text

        except requests.exceptions.RequestException as e:
            logging.debug(f"fetch attempt {attempt} failed for {url}: {e}")
            if attempt == max_attempts:
                error_msg = f"網路連線或請求錯誤 (ERR: {e.__class__.__name__})"
                return "提取失敗", domain, error_msg
            continue
        except Exception as e:
            logging.debug(f"processing error for {url}: {e}")
            error_msg = f"資料處理發生未知錯誤 (ERR: {e.__class__.__name__})"
            return "提取失敗", domain, error_msg

# ==============================================================================
# III. 搜尋與備援模組 (Search & Fallback) (略，與上一版相同)
# ==============================================================================

def perform_ddgs_search(query: str, max_results: int = 20) -> List[Dict[str, str]]:
    """使用 DuckDuckGo (DDGS) 進行關鍵字搜尋。"""
    print(f"-> 正在執行 DuckDuckGo 關鍵字搜尋: {query} (最多 {max_results} 筆)")
    results = []
    
    try:
        with DDGS() as ddgs:
            # 🐞 DDGS 錯誤修復：使用關鍵字參數 q=query
            ddgs_results = ddgs.text(q=query, region='tw-zh', max_results=max_results)
            
            for r in ddgs_results:
                results.append({'title': r['title'], 'link': r['href'], 'snippet': r.get('body', '無摘要')})
            time.sleep(3) 
    except Exception as e:
        print(f"  > DDGS 搜尋失敗，請檢查網路或搜尋頻率: {e}")
            
    return results

def perform_serpapi_fallback(query: str, max_results: int = 10) -> List[Dict[str, str]]:
    """使用 SerpApi (Google) 進行備援搜尋。"""
    print(f"-> 正在執行 SerpApi 備用搜尋 (Google): {query} (最多 {max_results} 筆)")
    
    if not SERPAPI_API_KEY or SERPAPI_API_KEY == "YOUR_API_KEY_HERE":
        print("  > ❌ SerpApi 金鑰未設置！備援搜尋中止。")
        return []

    params = {
        "engine": "google", "q": query, "api_key": SERPAPI_API_KEY,
        "gl": "tw", "hl": "zh-tw", "num": max_results
    }
    
    results = []
    try:
        search = GoogleSearch(params)
        data = search.get_dict()

        if "organic_results" in data:
            for item in data["organic_results"]:
                results.append({
                    'title': item.get('title', '無標題'), 
                    'link': item.get('link', ''),
                    'snippet': item.get('snippet', '無摘要')
                })
        
        return results

    except Exception as e:
        print(f"  > ❌ SerpApi 搜尋失敗。請檢查金鑰或額度。錯誤: {e}") 
        return []

# ==============================================================================
# IV. 特徵工程模組 (Feature Engineering) (略，與上一版相同)
# ==============================================================================

def get_domain_credibility(domain: str) -> float:
    """根據預設對應表獲取網域可信度分數。"""
    normalized_domain = domain.replace('www.', '')
    return DOMAIN_CREDIBILITY_MAP.get(normalized_domain, 3.0)

def calculate_article_features(url: str, title: str, content: str, domain: str) -> Dict[str, float]:
    """計算文章內容的結構化特徵，供 LLM 判別參考。"""
    features = {}
    
    if "提取失敗" in title or not content:
        return {'score_source': 1.0, 'emotion_ratio': 0.0, 'text_length': 0.0, 'final_crawler_score': 1.0, 'punctuation_density': 0.0}

    features['score_source'] = get_domain_credibility(domain) 
    text_len = len(content)
    features['text_length'] = float(text_len)

    emotion_count = sum(content.count(kw) for kw in EMOTIONAL_INDICATORS)
    features['emotion_ratio'] = (emotion_count / (text_len / 100)) if text_len > 100 else float(emotion_count) 
        
    exclamation_count = content.count('!') + content.count('！')
    question_count = content.count('?') + content.count('？')
    features['punctuation_density'] = (exclamation_count + question_count) / (text_len / 100) if text_len > 100 else float(exclamation_count + question_count) 

    crawler_score = features['score_source']
    crawler_score -= (features['emotion_ratio'] * 0.5) 
    crawler_score -= (features['punctuation_density'] * 0.2) 
    
    features['final_crawler_score'] = max(1.0, min(5.0, crawler_score))
    
    return features

# ==============================================================================
# V. AI 判別服務客戶端 (LLM Client Interface) (略，與上一版相同)
# ==============================================================================

class AnalysisOutput:
    """LLM 服務的結構化輸出物件。"""
    def __init__(self, confidence_score: float, credibility_level: str, summary: str):
        self.confidence_score = confidence_score
        self.credibility_level = credibility_level
        self.summary = summary

class CredibilityAnalyzerClient:
    """用於與 Gemini 服務互動，實現深度可信度判別的客戶端介面。"""
    def __init__(self, api_key: str):
        if api_key == "YOUR_GEMINI_API_KEY_HERE":
            self.client = None
            print("❌ LLM 客戶端：Gemini API 金鑰未設置。將進入【模擬模式】。")
        else:
            try:
                # 使用新版 Gemini API 初始化方式
                if genai is not None:
                    genai.configure(api_key=api_key)
                    self.client = genai
                    print("[OK] LLM 客戶端：Gemini API 初始化成功。")
                else:
                    self.client = None
                    print("❌ LLM 客戶端：google-generativeai 模組未安裝。將進入【模擬模式】。")
            except Exception as e:
                 self.client = None
                 print(f"❌ LLM 客戶端：Gemini API 初始化失敗 ({e})。將進入【模擬模式】。")

    def perform_llm_analysis(self, title: str, content: str, features: Dict[str, float]) -> AnalysisOutput:
        """調用 LLM 模型根據文章內容和特徵進行專業分析。"""
        
        if self.client is None:
            time.sleep(1)
            sim_score = min(1.0, features['final_crawler_score'] / 5.0 + 0.1) 
            sim_level = "中度可信/可疑 (模擬)" if 0.5 < sim_score <= 0.8 else "低度可信 (模擬)"
            sim_summary = (
                f"【模擬結果】: 該文章經由基礎爬蟲特徵分析，分數為 {sim_score:.3f}。"
                f"（請提供有效的 Gemini 金鑰以啟用專業 LLM 評論）"
            )
            return AnalysisOutput(sim_score, sim_level, sim_summary)

        try:
            prompt = f"""
            你是一位專業的資訊可信度分析師。請根據提供的文章內容和爬蟲計算出的特徵指標，判斷這篇文章的可信度等級 (Credibility Level) 並給出分數 (Score)。
            文章標題: {title}
            文章內容摘要: {content[:1500]}...
            爬蟲計算的基礎總分 (5.0滿分): {features['final_crawler_score']:.2f}
            來源網域可信度: {features['score_source']:.2f}
            文章情緒化詞彙比例 (每百字): {features['emotion_ratio']:.2f}

            請嚴格以 JSON 格式輸出，不要包含任何額外文字。JSON 格式必須包含三個鍵：
            1. credibility_level: 最終可信度等級（例如：「高度可信」、「中度可疑」、「極度可疑」）。
            2. confidence_score: 最終可信度分數（0.0到1.0之間，越高越可信）。
            3. summary: 基於內容和特徵的專業分析總結（約100字）。
            """
            
            # 使用新版 Gemini API
            model = self.client.GenerativeModel(
                'gemini-2.0-flash',
                generation_config={
                    "response_mime_type": "application/json",
                    "response_schema": {
                        "type": "object",
                        "properties": {
                            "credibility_level": {"type": "string"},
                            "confidence_score": {"type": "number"},
                            "summary": {"type": "string"},
                        },
                        "required": ["credibility_level", "confidence_score", "summary"],
                    },
                }
            )
            
            response = model.generate_content(prompt)
            
            data = json.loads(response.text)
            
            return AnalysisOutput(
                confidence_score=data.get('confidence_score', 0.5),
                credibility_level=data.get('credibility_level', '分析失敗'),
                summary=f"【LLM 專業分析】: {data.get('summary', '無詳細評論')}"
            )

        except Exception as e:
            print(f"❌ LLM 呼叫或解析失敗。錯誤類型: {e.__class__.__name__}")
            sim_score = min(1.0, features['final_crawler_score'] / 5.0 + 0.1) 
            sim_level = "錯誤回退：中度可信/可疑"
            sim_summary = "【LLM 錯誤回退】: LLM 服務呼叫失敗，分數為爬蟲基礎分數的線性映射。"
            return AnalysisOutput(sim_score, sim_level, sim_summary)

    def annotate_features(self, title: str, content: str, url: str = "") -> Tuple[Dict[str, float], str]:
        """使用 Gemini（或模擬）輸出該文章的特徵標註與 30 字以內判斷。
        回傳 (features_dict, short_judgement)。features_dict 的 keys 與您提供的 schema 相符，值在 0.0-1.0。
        """
        # If no real client, produce a heuristic simulation
        if self.client is None:
            # Heuristics based on domain and content
            domain = urllib.parse.urlparse(url).netloc if url else ""
            dscore = get_domain_credibility(domain) / 5.0

            # title-body overlap as simple ratio
            title_tokens = set(re.findall(r"\w+", title.lower()))
            body_tokens = set(re.findall(r"\w+", content.lower()))
            if title_tokens and body_tokens:
                overlap = len(title_tokens & body_tokens) / max(1, len(title_tokens))
            else:
                overlap = 0.0

            # emotion density from previous feature calculation
            emotion_count = sum(content.count(kw) for kw in EMOTIONAL_INDICATORS)
            text_len = max(1, len(content))
            emotive_density = min(1.0, (emotion_count / (text_len / 100)))

            # evidence quality approx: presence of numbers/doi/https links
            evidence = 0.0
            if re.search(r"\b\d{4}\b", content):
                evidence += 0.3
            if re.search(r"doi:\/\/|doi\.org|pubmed|arxiv", content, flags=re.I):
                evidence += 0.5
            if re.search(r"https?:\/\/(?:[\w.-]+)\/(?:\S*\d)", content):
                evidence += 0.2
            evidence = min(1.0, evidence)

            # ad intensity: presence of buy/subscribe/discount keywords
            ad = 0.0
            if re.search(r"buy now|subscribe|discount|promo|購買|聯盟|廣告|贊助", content, flags=re.I):
                ad = 0.7

            features = {
                "source_entity_score": dscore,  # rough
                "domain_score": dscore,
                "title_body_consistency": min(1.0, overlap * 1.2),
                "evidence_quality": evidence,
                "ad_promo_intensity": ad,
                "hyperbole_score": min(1.0, emotive_density * 0.8),
                "emotive_clickbait_density": emotive_density,
                "title_body_embedding_cosine": min(1.0, overlap),
            }

            # short judgement (<=30 chars)
            short = None
            if features["domain_score"] >= 0.8 and features["evidence_quality"] >= 0.6:
                short = "高度可信"
            elif features["emotive_clickbait_density"] > 0.6 or features["ad_promo_intensity"]>0.7:
                short = "可疑 / 廣告導向"
            elif features["title_body_consistency"] < 0.4:
                short = "標題與內文不符"
            else:
                short = "中度可信"

            return features, short

        # Real Gemini call: ask for JSON with numeric fields + short judgement
        try:
            # build prompt safely (avoid f-string to prevent parsing issues)
            prompt = (
                "請以 JSON 格式回傳下列欄位 (數值 0.0 到 1.0)：\n\n"
                + "title: " + (title or "") + "\n\n"
                + "content: " + (content or "")[:2000].replace('\n', ' ') + "...\n\n"
                + "欄位: source_entity_score, domain_score, title_body_consistency, evidence_quality, ad_promo_intensity, hyperbole_score, emotive_clickbait_density, title_body_embedding_cosine\n"
                + "同時回傳一個 short_judgement (不超過 30 個字的中文判斷)。\n"
                + "JSON 必須只有一個物件，範例如：{\"source_entity_score\":0.8, \"domain_score\":0.9, \"title_body_consistency\":0.8, \"evidence_quality\":0.7, \"ad_promo_intensity\":0.1, \"hyperbole_score\":0.2, \"emotive_clickbait_density\":0.1, \"title_body_embedding_cosine\":0.85, \"short_judgement\":\"高度可信\"}\n"
            )

            # 使用新版 Gemini API
            model = self.client.GenerativeModel(
                'gemini-2.0-flash',
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
                        "required": ["source_entity_score","domain_score","title_body_consistency","evidence_quality","ad_promo_intensity","hyperbole_score","emotive_clickbait_density","title_body_embedding_cosine","short_judgement"]
                    }
                }
            )

            response = model.generate_content(prompt)
            data = json.loads(response.text)
            # normalize numbers into 0.0-1.0 range
            features = {k: float(data.get(k, 0.0)) for k in [
                "source_entity_score","domain_score","title_body_consistency","evidence_quality","ad_promo_intensity","hyperbole_score","emotive_clickbait_density","title_body_embedding_cosine"
            ]}
            short = data.get("short_judgement", "")[:30]
            return features, short
        except Exception as e:
            logging.debug(f"Gemini annotate failed: {e}")
            # fallback to heuristic simulation
            features = {
                "source_entity_score": 0.5,
                "domain_score": 0.5,
                "title_body_consistency": 0.6,
                "evidence_quality": 0.5,
                "ad_promo_intensity": 0.3,
                "hyperbole_score": 0.4,
                "emotive_clickbait_density": 0.3,
                "title_body_embedding_cosine": 0.7
            }
            short = "模擬判斷"
            return features, short

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
    
    report = ["\n" + "="*80]
    report.append("                           【資訊可信度分析報告】")
    report.append(f"生成時間: {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())}")
    report.append("="*80)

    if mode == "URL":
        # --- 單一網址報告 ---
        report.append(f"【分析類型】: 單一網址深度分析")
        report.append(f"【目標網址】: {user_input}")
        report.append(f"【網頁標題】: {content[:100].splitlines()[0]}...")
        report.append("-" * 30)
        
        if llm_report and features:
            report.append("--- 🤖 LLM 深度判別結果 ---")
            report.append(f"最終可信度等級: {llm_report.credibility_level}")
            report.append(f"LLM 評估分數 (0.0-1.0): {llm_report.confidence_score:.3f}")
            report.append(f"分析總結:\n{llm_report.summary}")
            report.append("-" * 30)
            
            report.append("--- 📊 爬蟲特徵指標 ---")
            report.append(f"  - 網域基礎分數 (5.0): {features['score_source']:.2f}")
            report.append(f"  - 文章總字數: {features['text_length']:.0f}")
            report.append(f"  - 情緒化指標 (每百字): {features['emotion_ratio']:.2f}")
            report.append(f"  - 爬蟲基礎總分 (5.0): {features['final_crawler_score']:.2f}")
        
        report.append("="*80)
        report.append(f"【文章內容片段】:\n{content[:1500]}...")

    elif mode == "KEYWORD" and all_analyses:
        # --- 關鍵字批量分析報告 ---
        report.append(f"【分析類型】: 關鍵字批量分析")
        report.append(f"【搜尋關鍵字】: {user_input}")
        report.append(f"【有效分析文章數】: {len(all_analyses)}")
        report.append("-" * 80)
        
        report.append("  索引 | LLM 等級及分數 | 網域 | 文章標題")
        report.append("-" * 80)
        
        for analysis in all_analyses:
            # 格式化輸出，讓分數對齊
            score_str = f"{analysis['ai_score']:.3f}"
            title_summary = analysis['title'][:40].ljust(40)
            line = (
                f" {analysis['index']:<4} | {analysis['ai_level'].ljust(10)} ({score_str}) | "
                f"{analysis['domain'].ljust(15)} | {title_summary}..."
            )
            report.append(line)
        
        report.append("-" * 80)
        report.append("\n【建議】: 應特別關注評分低於 0.5 的連結，並查看其原始內容。")
        
    else:
        # 搜尋無結果報告
        report.append(f"【分析類型】: 關鍵字搜尋")
        report.append(f"【搜尋關鍵字】: {user_input}")
        report.append("                           未找到任何相關且可分析的連結。")
        report.append("-" * 80)

    report.append("\n\n")
    return "\n".join(report)

# ==============================================================================
# VII. 主應用程式邏輯 (Main Application Logic)
# ==============================================================================

def is_valid_url(text: str) -> bool:
    """檢查輸入是否為有效的 URL 格式。"""
    return text.startswith(('http://', 'https://'))

def run_analysis_system():
    # 嘗試在專案中自動找到模型檔，將其設為 --model 的預設值
    discovered_model = None
    try:
        candidates = list(Path('.').rglob('*auth_level*.txt'))
        if candidates:
            # 使用相對路徑（從專案根）作為預設
            discovered_model = str(candidates[0].as_posix())
    except Exception:
        discovered_model = None

    parser = argparse.ArgumentParser(description='資訊可信度輔助系統')
    parser.add_argument('--max-results', type=int, default=20, help='關鍵字搜尋的最大結果數量')
    parser.add_argument('--min-length', type=int, default=100, help='最少文章長度 (字元) 才進行分析')
    parser.add_argument('--save', action='store_true', help='同時將完整報告存成檔案')
    parser.add_argument('--verbose', action='store_true', help='啟用詳細日誌')
    parser.add_argument('--model', default=(discovered_model or 'model_auth_level/auth_level_lgbm.txt'), help='LightGBM 模型檔案路徑 (可選)')
    parser.add_argument('--query', default=None, help='非互動式指定搜尋關鍵字（避免使用管道）')
    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    print("--- 資訊可信度輔助系統：內容擷取與 LLM 深度分析---")

    analyzer = CredibilityAnalyzerClient(api_key=GEMINI_API_KEY)
    # load LightGBM model if provided
    booster = None
    model_path = Path(args.model)
    # If the configured model path doesn't exist, attempt to auto-discover a model in the repo
    if not model_path.exists():
        print(f"⚠️ 指定模型不存在: {model_path}，嘗試在專案中自動搜尋相似模型檔...")
        candidates = list(Path('.').rglob('*auth_level*.txt'))
        if candidates:
            # prefer the first reasonable candidate
            model_path = candidates[0]
            print(f"🔎 自動找到模型檔: {model_path}，將使用此模型進行預測。")
        else:
            print(f"❌ 未在專案中找到任何 '*auth_level*.txt' 模型檔，將略過模型預測。")

    if model_path.exists():
        try:
            booster = lgb.Booster(model_file=str(model_path))
            print(f"[OK] 已載入模型: {model_path}")
        except Exception as e:
            print(f"[ERROR] 載入模型失敗: {e}")
            booster = None

    if args.query:
        user_input = args.query.strip()
        print(f"使用 --query 提供搜尋字串: {user_input}")
    else:
        user_input = input("請輸入【目標網址 (e.g., https://...)】或【關鍵字】：").strip()

    output_content = ""
    results: List[Dict[str, str]] = []
    all_analyses: List[Dict] = []
    skipped: List[Tuple[str, str]] = []  # list of (url, reason)
    llm_report: Optional[AnalysisOutput] = None

    if is_valid_url(user_input):
        # --- 模式 A: 單一網址擷取 ---
        title, domain, content = fetch_and_clean_url(user_input)

        if "提取失敗" in title or not content or len(content) < args.min_length:
            print("\n❌ 網址內容擷取失敗或內容不足。")
            output_items = []
        else:
            output_items = [{
                'title': title,
                'url': user_input,
                'domain': domain,
                'content': content,
            }]

        # annotate and model-predict for single URL
        enriched = []
        for it in output_items:
            feats_ann, short = analyzer.annotate_features(it['title'], it['content'], it['url'])
            it['ann_features'] = feats_ann
            it['short_judgement'] = short
            if booster is not None:
                # convert to numpy vector in same order as model expects
                feat_order = [
                    "source_entity_score","domain_score","title_body_consistency","evidence_quality","ad_promo_intensity","hyperbole_score","emotive_clickbait_density","title_body_embedding_cosine"
                ]
                x = np.array([feats_ann.get(k, 0.0) for k in feat_order], dtype=float).reshape(1, -1)
                try:
                    proba = booster.predict(x, num_iteration=booster.best_iteration or None)
                    pred = int(np.argmax(proba, axis=1)[0])
                    it['model_score'] = int(pred)
                    it['model_proba'] = proba[0].tolist()
                except Exception as e:
                    it['model_score'] = None
                    it['model_proba'] = []
            enriched.append(it)

        output_content = json.dumps({'mode': 'URL', 'items': enriched}, ensure_ascii=False, indent=2)

        output_content = json.dumps({'mode': 'URL', 'items': output_items}, ensure_ascii=False, indent=2)
        print("\n[OK] 單一網址擷取完成，輸出 JSON：\n")
        print(output_content)
        # 存檔改為執行結束時統一寫入（見程式尾端）

    else:
        # --- 模式 B: 關鍵字批量分析 ---
        results = perform_ddgs_search(user_input, max_results=args.max_results)

        if not results:
            results = perform_serpapi_fallback(user_input, max_results=min(10, args.max_results))

        if results:
            print("\n-> 開始批量擷取搜尋結果的標題/網址/內容...")
            items = []
            for i, item in enumerate(results, 1):
                url = item.get('link')
                if not url:
                    skipped.append((str(item), 'no link'))
                    continue

                title, domain, content = fetch_and_clean_url(url)

                if "提取失敗" in title:
                    skipped.append((url, 'fetch failed'))
                    continue

                if not content or len(content) < args.min_length:
                    skipped.append((url, f'content too short ({len(content) if content else 0})'))
                    continue

                # 加入爬取時間戳記
                from datetime import datetime
                crawled_at = datetime.now().isoformat()

                entry = {
                    'index': i,
                    'title': title,
                    'url': url,
                    'domain': domain,
                    'content': content,
                    'crawled_at': crawled_at,  # 新增：記錄爬取時間
                }

                # annotate with Gemini or heuristic and predict with model
                feats_ann, short = analyzer.annotate_features(title, content, url)
                entry['ann_features'] = feats_ann
                entry['short_judgement'] = short
                if booster is not None:
                    feat_order = [
                        "source_entity_score","domain_score","title_body_consistency","evidence_quality","ad_promo_intensity","hyperbole_score","emotive_clickbait_density","title_body_embedding_cosine"
                    ]
                    x = np.array([feats_ann.get(k, 0.0) for k in feat_order], dtype=float).reshape(1, -1)
                    try:
                        proba = booster.predict(x, num_iteration=booster.best_iteration or None)
                        pred = int(np.argmax(proba, axis=1)[0])
                        entry['model_score'] = int(pred)
                        entry['model_proba'] = proba[0].tolist()
                    except Exception as e:
                        entry['model_score'] = None
                        entry['model_proba'] = []

                items.append(entry)

                print(f"  > [OK] [{i}] {domain} 擷取完成。")

            output_content = json.dumps({'mode': 'KEYWORD', 'items': items, 'skipped_count': len(skipped)}, ensure_ascii=False, indent=2)
            print(f"\n[OK] 批量擷取完成！共擷取: {len(items)} 篇；被跳過: {len(skipped)} 篇。")
            if skipped:
                print("\n-- 被跳過的連結 (範例最多 10 筆) --")
                for u, reason in skipped[:10]:
                    print(f" - {u} -> {reason}")

            print("\n輸出 JSON：\n")
            print(output_content)

            if args.save:
                timestamp = time.strftime('%Y%m%d_%H%M%S')
                fname = f"reports/raw_{timestamp}.json"
                try:
                    os.makedirs('reports', exist_ok=True)
                    with open(fname, 'w', encoding='utf-8') as f:
                        f.write(output_content)
                    print(f"📁 已將原始擷取結果存為: {fname}")
                except Exception as e:
                    print(f"❌ 儲存結果失敗: {e}")
        else:
            output_content = json.dumps({'mode': 'KEYWORD', 'items': [], 'skipped_count': 0}, ensure_ascii=False)
            print("\n⚠️ 未找到任何相關連結。")

    # ------------------
    # 輸出到終端機並複製到剪貼簿
    # ------------------
    print("\n" + "="*50)
    print("【系統運行報告摘要】")

    # 打印報告摘要
    if is_valid_url(user_input):
        if llm_report:
            print(f"分析目標: {user_input[:50]}...")
            print(f"最終等級: {llm_report.credibility_level}")
    else:
        print(f"關鍵字: {user_input}")
        print(f"批量分析文章數: {len(all_analyses)}")
        if all_analyses:
            print(f"前 3 筆最可疑連結:")
            # 按分數排序，選擇最低分的三個 (最可疑)
            top_suspicious = sorted(all_analyses, key=lambda x: x['ai_score'])[:3]
            for analysis in top_suspicious:
                print(f"  - {analysis['domain']} ({analysis['ai_level']}) - {analysis['ai_score']:.3f}")

    print("="*50)

    # --- 統一寫出 JSON 記錄檔（依使用者要求：每次都寫） ---
    try:
        os.makedirs('reports', exist_ok=True)
        timestamp = time.strftime('%Y%m%d_%H%M%S')
        fname = f"reports/raw_{timestamp}.json"
        with open(fname, 'w', encoding='utf-8') as f:
            f.write(output_content)
        print(f"📁 已將原始擷取結果存為: {fname}")
    except Exception as e:
        print(f"❌ 自動儲存 JSON 失敗: {e}")

    try:
        pyperclip.copy(output_content)
        print("🎉 完整報告內容已自動複製到您的剪貼簿中。")
    except pyperclip.PyperclipException:
        print("❌ 無法存取剪貼簿。請手動複製上方內容。")
        
if __name__ == "__main__":
    run_analysis_system()