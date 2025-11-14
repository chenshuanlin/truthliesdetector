#!/usr/bin/env python3
"""
簡化版新聞分析腳本，專為 Node.js API 設計
接收單一網址，輸出 JSON 格式分析結果
"""
import sys
import json
import requests
from bs4 import BeautifulSoup
import urllib.parse
import time
import re

def preprocess_document_text(text: str) -> str:
    """清理常見的網頁噪音、廣告和冗餘空間。"""
    text = re.sub(r'\(C\) 版權所有|All rights reserved|分享給好友|點擊下載|繼續閱讀|相關新聞.*', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\n{2,}', '\n', text) 
    text = re.sub(r'\s{2,}', ' ', text).strip()
    return text

def fetch_and_clean_url(url: str):
    """從 URL 抓取標題、網域和淨化後的主文本。"""
    domain = urllib.parse.urlparse(url).netloc
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }

    try:
        response = requests.get(url, headers=headers, timeout=10, allow_redirects=True)
        response.raise_for_status()
        response.encoding = response.apparent_encoding

        soup = BeautifulSoup(response.text, 'html.parser')
        title = soup.title.string.strip() if soup.title and soup.title.string else "未偵測到標題"

        # 嘗試擷取文章主體
        main_text = ""
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

    except Exception as e:
        error_msg = f"網路連線或請求錯誤: {str(e)}"
        return "提取失敗", domain, error_msg

def analyze_content(title: str, content: str, domain: str):
    """簡單的內容分析，計算可信度分數"""
    
    # 網域可信度評分
    domain_credibility = {
        'cna.com.tw': 5.0, 'udn.com': 4.5, 'setn.com': 3.0, 
        'facebook.com': 2.5, 'ptt.cc': 2.0
    }
    
    domain_score = domain_credibility.get(domain, 3.0)
    
    # 情緒化詞彙檢測
    emotional_indicators = [
        '驚人', '絕對', '震驚', '離譜', '不可思議', '大爆發', '小心', '慘了', 
        '怒吼', '崩潰', '獨家', '急轉直下', '馬上看', '瘋傳', '秘密'
    ]
    
    emotion_count = sum(1 for word in emotional_indicators if word in content)
    emotion_ratio = emotion_count / (len(content) / 100) if content else 0
    
    # 計算總分 (簡化版)
    base_score = domain_score
    emotion_penalty = min(emotion_ratio * 0.5, 2.0)
    final_score = max(1.0, base_score - emotion_penalty)
    
    # 正規化到 0-1
    confidence_score = min(1.0, final_score / 5.0)
    
    # 判斷可信度等級
    if confidence_score >= 0.8:
        credibility_level = "高度可信"
    elif confidence_score >= 0.6:
        credibility_level = "中度可信"
    elif confidence_score >= 0.4:
        credibility_level = "中度可疑"
    else:
        credibility_level = "高度可疑"
    
    return {
        'confidence_score': round(confidence_score, 3),
        'credibility_level': credibility_level,
        'domain_score': domain_score,
        'emotion_ratio': round(emotion_ratio, 2),
        'final_score': round(final_score, 2)
    }

def main():
    if len(sys.argv) < 2:
        result = {
            'error': '缺少網址參數',
            'usage': 'python analyze_news.py <url>'
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
        sys.exit(1)
    
    url = sys.argv[1]
    
    try:
        # 擷取內容
        title, domain, content = fetch_and_clean_url(url)
        
        if "提取失敗" in title or not content:
            result = {
                'error': '無法擷取網頁內容',
                'url': url,
                'domain': domain
            }
        else:
            # 分析內容
            analysis = analyze_content(title, content, domain)
            
            result = {
                'success': True,
                'url': url,
                'title': title,
                'domain': domain,
                'content_length': len(content),
                'analysis': analysis,
                'summary': f"該文章來自 {domain}，標題為「{title}」，經分析後可信度等級為「{analysis['credibility_level']}」，可信度分數為 {analysis['confidence_score']}。"
            }
        
        # 輸出 JSON 結果
        print(json.dumps(result, ensure_ascii=False, indent=2))
        
    except Exception as e:
        result = {
            'error': f'分析過程發生錯誤: {str(e)}',
            'url': url
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
        sys.exit(1)

if __name__ == "__main__":
    main()