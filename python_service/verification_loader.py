"""
查證資料載入與分類模組
從 projectt/reports/raw_*.json 讀取查證資料，並依據 model_score (0~5) 分類：
0-2 → suspicious（紅色）
3-5 → verified（綠色）
"""

import json
import os
from pathlib import Path
from typing import List, Dict, Tuple
from datetime import datetime


# ============================================================
# 載入所有 raw_*.json
# ============================================================
def load_verification_data() -> List[Dict]:
    current_dir = Path(__file__).parent

    candidate_paths = [
        current_dir.parent / 'projectt' / 'reports',
        current_dir.parent / 'reports'
    ]

    reports_dir = None
    for p in candidate_paths:
        if p.exists():
            reports_dir = p
            break

    if reports_dir is None:
        print(f"⚠️ 找不到 reports 資料夾，嘗試：{candidate_paths}")
        return []

    print(f"📁 使用查證資料資料夾: {reports_dir}")

    # 找所有 raw_*.json
    json_files = []
    for p in candidate_paths:
        if p.exists():
            found = list(p.glob('raw_*.json'))
            json_files.extend(found)
            if found:
                print(f"  ✓ {p} 找到 {len(found)} 個檔案")

    if not json_files:
        print("⚠️ 找不到任何 raw_*.json 檔案")
        return []

    all_items = []
    for jf in sorted(json_files):
        try:
            with open(jf, "r", encoding="utf-8") as f:
                data = json.load(f)
                items = data.get("items", [])
                all_items.extend(items)
                print(f"  ✓ 載入 {jf}: {len(items)} 則")
        except Exception as e:
            print(f"  ✗ 載入 {jf} 失敗: {e}")

    print(f"📌 總計載入 {len(all_items)} 則新聞")
    return all_items


# ============================================================
# 使用 model_score(0~5) 直接判斷
# ============================================================
def classify_item(item):
    """
    model_score 規則：
    0 = 不可信（紅）
    1 = 極低（紅）
    2 = 低（紅）
    3 = 中（綠）
    4 = 高（綠）
    5 = 極高（綠）
    """
    score = item.get("model_score") or item.get("credibility_score") or item.get("cred_score")

    try:
        score = int(score)
    except Exception:
        score = -1  # 無法解析視為可疑（紅色）

    if score >= 3:
        return "verified"      # 綠色柱狀
    else:
        return "unverified"    # 紅色柱狀


# ============================================================
# 依近 N 天 (0=今天) 分配數量
# ============================================================
def get_daily_distribution(items: List[Dict], days: int = 7) -> Dict[int, int]:
    from datetime import datetime, timedelta

    total = len(items)
    if total == 0:
        return {i: 0 for i in range(days)}

    has_timestamp = any('crawled_at' in item for item in items)

    # 若有 crawled_at → 使用真實日期分布
    if has_timestamp:
        now = datetime.now().date()
        distribution = {i: 0 for i in range(days)}

        for item in items:
            ts = item.get('crawled_at')
            if not ts:
                continue
            try:
                dt = datetime.fromisoformat(ts).date()
            except Exception:
                continue

            delta = (now - dt).days
            if 0 <= delta < days:
                distribution[delta] += 1

        return distribution

    # 若無日期 → 平均分配
    base = total // days
    remain = total % days
    dist = {}
    for i in range(days):
        dist[i] = base + (1 if i < remain else 0)
    return dist


# ============================================================
# 回傳 verified / unverified
# ============================================================
def get_verification_stats() -> Tuple[int, int, List[Dict], List[Dict]]:
    all_items = load_verification_data()

    verified_items = []
    unverified_items = []

    for item in all_items:
        if classify_item(item) == "verified":
            verified_items.append(item)
        else:
            unverified_items.append(item)

    return (
        len(verified_items),
        len(unverified_items),
        verified_items,
        unverified_items,
    )


# ============================================================
# 測試模式
# ============================================================
if __name__ == "__main__":
    v_count, u_count, v_items, u_items = get_verification_stats()
    print("=== 查證資料統計 ===")
    print("verified :", v_count)
    print("unverified :", u_count)
    print("total :", v_count + u_count)
