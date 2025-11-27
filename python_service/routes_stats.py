from flask import Blueprint, jsonify, request
from datetime import datetime, timedelta
import xml.etree.ElementTree as ET
import requests

from verification_loader import (
    get_verification_stats,
    get_daily_distribution,
)

bp = Blueprint("stats", __name__)


# ============================================================
# Helper：分類標題
# ============================================================
def _categorize_titles(titles):
    mapping = {
        '政治': ['選舉', '總統', '立法院', '政治', '政黨', '立委'],
        '健康': ['確診', '疫苗', '疫情', '醫療', '減肥', '健康'],
        '經濟': ['股', '台積電', '經濟', '投資', '通膨', '銀行'],
        '科技': ['AI', '人工智慧', '科技', '晶片', '蘋果', '微軟'],
        '社會': ['警方', '警察', '詐騙', '車禍', '火警', '社會'],
        '國際': ['中國', '美國', '日本', '韓國', '俄羅斯', '以色列'],
    }

    counts = {k: 0 for k in mapping}

    for t in titles:
        for cat, keys in mapping.items():
            if any(k in t for k in keys):
                counts[cat] += 1
                break

    total = sum(counts.values()) or 1

    return [
        {"name": k, "percentage": int(v * 100 / total)}
        for k, v in counts.items() if v > 0
    ][:5]


# ============================================================
# ROUTE A：前端 fake-news-stats
# ============================================================
@bp.get("/fake-news-stats")
def fake_news_stats():
    print("[DEBUG] /fake-news-stats 被呼叫")

    # ============================================
    # ① 取得初始資料
    # ============================================
    verified_count, unverified_count, verified_items, unverified_items = get_verification_stats()

    # ============================================
    # ② 星期分佈（修正 index 對應方式）
    # ============================================
    verified_daily = get_daily_distribution(verified_items, 7)
    unverified_daily = get_daily_distribution(unverified_items, 7)

    # 將最近 7 天的資料放到對應的星期欄位 (週一=0 ... 週日=6)，並以星期標籤輸出
    # 這樣前端畫面上固定的星期標籤（一-日）會與資料對齊，今天的數據會出現在對應的星期位置
    from datetime import datetime, timedelta

    today = datetime.now().date()

    # 先把最近 7 天 (offset 0=今天,1=昨天...) 的 verified/unverified 按 weekday 聚合
    verified_by_weekday = {i: 0 for i in range(7)}
    suspicious_by_weekday = {i: 0 for i in range(7)}
    for offset in range(0, 7):
        d = today - timedelta(days=offset)
        wd = d.weekday()  # Monday=0 ... Sunday=6
        verified_by_weekday[wd] = verified_daily.get(offset, 0)
        suspicious_by_weekday[wd] = unverified_daily.get(offset, 0)

    # 產出週陣列，順序為 週一..週日，label 使用一..日（與前端靜態標籤對齊）
    labels = ["一", "二", "三", "四", "五", "六", "日"]
    weekly = []
    for wd in range(7):
        weekly.append({
            "day": labels[wd],
            "verified": verified_by_weekday.get(wd, 0),
            "suspicious": suspicious_by_weekday.get(wd, 0),
        })

    # ============================================
    # ③ 計算卡片紅灰綠
    # ============================================
    total_verified = sum(verified_daily.values())
    total_suspicious = sum(unverified_daily.values())

    total = total_verified + total_suspicious
    ai_accuracy = round(total_verified / total * 100) if total else 0

    # ============================================
    # ④ 熱門分類
    # ============================================
    all_titles = [item.get("title", "") for item in (verified_items + unverified_items)]

    # meta.fetchedAt: 取所有 items 中最新的 crawled_at（若有），以 ISO 字串回傳
    latest_ts = None
    for item in (verified_items + unverified_items):
        ts = item.get('crawled_at')
        if not ts:
            continue
        try:
            dt = datetime.fromisoformat(ts)
        except Exception:
            continue
        if latest_ts is None or dt > latest_ts:
            latest_ts = dt
    meta = {"source": "JSON raw_*.json", "count": len(all_titles)}
    if latest_ts:
        meta['fetchedAt'] = latest_ts.isoformat()

    return jsonify({
        "ok": True,
        "stats": {
            "totalVerified": total_verified,
            "totalSuspicious": total_suspicious,
            "aiAccuracy": ai_accuracy,
            "weeklyReports": weekly,
            "topCategories": _categorize_titles(all_titles),
            "meta": meta
        }
    })
