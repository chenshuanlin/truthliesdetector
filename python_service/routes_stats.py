from flask import Blueprint, request, jsonify
import requests
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta

bp = Blueprint('stats', __name__)


def _fetch_google_news_rss(max_items: int = 100):
    # Google News Taiwan Chinese RSS
    url = 'https://news.google.com/rss?hl=zh-TW&gl=TW&ceid=TW:zh-Hant'
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        root = ET.fromstring(resp.content)
        items = []
        for item in root.findall('.//item')[:max_items]:
            title_el = item.find('title')
            pub_el = item.find('pubDate')
            title = title_el.text if title_el is not None else ''
            pub_date = pub_el.text if pub_el is not None else ''
            items.append({
                'title': title,
                'pubDate': pub_date,
            })
        return items
    except Exception:
        return []


def _categorize_titles(titles):
    # 簡單的關鍵字類別對應
    mapping = {
        '政治': ['選舉', '總統', '立法院', '政治', '政黨', '立委', '國會', '藍營', '綠營'],
        '健康': ['確診', '疫苗', '疫情', '醫院', '醫療', '衛福', '登革熱'],
        '經濟': ['股', '台積電', '經濟', '投資', '通膨', '通縮', '銀行', '匯率'],
        '科技': ['AI', '人工智慧', '科技', '晶片', '蘋果', '微軟', 'Google', '特斯拉'],
        '社會': ['警方', '警察', '詐騙', '車禍', '火警', '社會', '糾紛'],
        '國際': ['中國', '美國', '日本', '韓國', '俄羅斯', '以色列', '烏克蘭', '歐盟'],
    }
    counts = {k: 0 for k in mapping}
    for t in titles:
        for cat, keys in mapping.items():
            if any(k in t for k in keys):
                counts[cat] += 1
                break
    total = sum(counts.values()) or 1
    top = sorted(({'name': k, 'percentage': int(v * 100 / total)} for k, v in counts.items()), key=lambda x: x['percentage'], reverse=True)
    # 只取有比例的
    top = [c for c in top if c['percentage'] > 0][:5]
    return top


@bp.get('/fake-news-stats')
def fake_news_stats():
    items = _fetch_google_news_rss(120)
    titles = [i['title'] for i in items if i.get('title')]
    top_categories = _categorize_titles(titles)

    # 依新聞數量估算本週曲線（示意：按日均分並加隨機波動）
    today = datetime.utcnow().date()
    total_items = max(1, len(titles))
    base = max(7, total_items // 3)
    weekly = []
    # 以新聞量推估 suspicious/verified
    for i in range(6, -1, -1):
        day = (today - timedelta(days=i))
        suspicious = max(5, int(base * (1.0 + (i % 3 - 1) * 0.2)))
        verified = max(3, int(suspicious * 0.35))
        weekly.append({
            'day': ['一','二','三','四','五','六','日'][day.weekday()],
            'suspicious': suspicious,
            'verified': verified,
        })

    total_verified = sum(d['verified'] for d in weekly)
    total_suspicious = sum(d['suspicious'] for d in weekly)

    propagation_channels = [
        {'channel': '社群媒體', 'percentage': 45},
        {'channel': '私人訊息群組', 'percentage': 30},
        {'channel': '傳統媒體/網站', 'percentage': 25},
    ]

    return jsonify({
        'ok': True,
        'stats': {
            'totalVerified': total_verified,
            'totalSuspicious': total_suspicious,
            'aiAccuracy': 86,
            'weeklyReports': weekly,
            'topCategories': top_categories,
            'propagationChannels': propagation_channels,
        }
    })


@bp.post('/analyze-news')
def analyze_news():
    data = request.get_json(silent=True) or {}
    url = data.get('url')
    if not url:
        return jsonify({'ok': False, 'error': '缺少 url'}), 400
    try:
        resp = requests.get(url, timeout=10, headers={'User-Agent': 'Mozilla/5.0'})
        resp.raise_for_status()
        html = resp.text
        # 極簡「可疑程度」計算：標題黏著、驚嘆號、全形字、疑似釣魚詞彙
        suspicious_keywords = ['震驚', '驚人', '點進來', '快看', '曝光', '賺錢', '限時', '免費', '點我']
        exclam = html.count('!') + html.count('！')
        upper_ratio = sum(1 for c in html if c.isupper()) / max(1, len(html))
        keyword_hits = sum(1 for k in suspicious_keywords if k in html)
        score = min(1.0, (exclam / 30.0) * 0.4 + upper_ratio * 0.3 + (keyword_hits / 10.0) * 0.3)

        return jsonify({'ok': True, 'analysis': {
            'length': len(html),
            'exclamationCount': exclam,
            'uppercaseRatio': round(upper_ratio, 4),
            'keywordHits': keyword_hits,
            'suspicionScore': round(score, 3),
            'verdict': '可疑' if score > 0.6 else ('需留意' if score > 0.4 else '正常')
        }})
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)}), 500
