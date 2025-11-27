"""
查證資料載入與分類模組
從 projectt/reports/raw_*.json 讀取查證資料，並自動分類為「已查證」和「未查證」
"""
import json
import os
from pathlib import Path
from typing import List, Dict, Tuple
from datetime import datetime


def load_verification_data() -> List[Dict]:
    """
    載入所有 projectt/reports/raw_*.json 檔案
    回傳合併後的新聞條目列表
    """
    # 找到可能的 reports 資料夾（相對於此檔案）
    current_dir = Path(__file__).parent

    # 優先使用 projectt/reports（舊路徑），若不存在則 fallback 到 repo 根目錄下的 reports
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
        print(f"警告：找不到查證資料資料夾，嘗試的路徑: {candidate_paths}")
        return []
    else:
        print(f"使用查證資料資料夾: {reports_dir}")
    
    all_items = []

    # 支援同時從多個候選 reports 資料夾載入（例如 projectt/reports 與 repo_root/reports）
    json_files = []
    for p in candidate_paths:
        if p.exists():
            found = list((p).glob('raw_*.json'))
            if found:
                print(f"在 {p} 找到 {len(found)} 個 raw_*.json 檔案")
                json_files.extend(found)

    if not json_files:
        print(f"警告：在候選資料夾中找不到任何 raw_*.json 檔案，嘗試的路徑: {candidate_paths}")
        return []

    print(f"總共找到 {len(json_files)} 個 raw_*.json 檔案，開始載入...")

    for json_file in sorted(json_files):
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                items = data.get('items', [])
                all_items.extend(items)
                print(f"  ✓ 載入 {json_file}: {len(items)} 則新聞")
        except Exception as e:
            print(f"  ✗ 載入 {json_file} 失敗: {e}")
            continue
    
    print(f"總共載入 {len(all_items)} 則新聞")
    return all_items


def classify_item(item):
    sj = item.get("short_judgement") or item.get("shortJudgement") or ""

    verified_keywords = [
        '可信', '查證', '已查證', '經查證', '假訊息', '不實', '謠言',
        '經證實', '經查核', '經審查', '確認', '事實查核', '闢謠'
    ]

    # 1) 文字關鍵字判斷（若短判斷明確包含已查證相關文字，直接視為已查證）
    if any(k in sj for k in verified_keywords):
        return "verified"

    # 2) 若沒有文字提示，使用 ann_features 的分數作為輔助判斷
    ann = item.get('ann_features') or {}
    try:
        evidence_quality = float(ann.get('evidence_quality') or 0)
    except Exception:
        evidence_quality = 0.0
    try:
        source_score = float(ann.get('source_entity_score') or 0)
    except Exception:
        source_score = 0.0

    # 調整閾值：若證據品質與來源分數都 >= 0.6，視為已查證（提高可信度識別）
    if evidence_quality >= 0.6 and source_score >= 0.6:
        return 'verified'

    # 其餘視為未查證
    return 'unverified'


def get_verification_stats() -> Tuple[int, int, List[Dict], List[Dict]]:
    """
    取得查證統計資料
    
    回傳：
    - verified_count: 已查證數量
    - unverified_count: 未查證數量
    - verified_items: 已查證條目列表
    - unverified_items: 未查證條目列表
    """
    all_items = load_verification_data()
    
    verified_items = []
    unverified_items = []
    
    for item in all_items:
        if classify_item(item) == 'verified':
            verified_items.append(item)
        else:
            unverified_items.append(item)
    
    return len(verified_items), len(unverified_items), verified_items, unverified_items


def get_daily_distribution(items: List[Dict], days: int = 7) -> Dict[int, int]:
    """
    將條目列表依實際爬取日期分組到近 N 天
    回傳 {day_offset: count} 字典，day_offset 0 = 今天，1 = 昨天，依此類推
    
    如果條目有 crawled_at 欄位，則根據實際日期分組
    否則退回到均分邏輯（向下兼容）
    """
    from datetime import datetime, timedelta
    
    total = len(items)
    if total == 0:
        return {i: 0 for i in range(days)}
    
    # 檢查是否有 crawled_at 欄位
    has_timestamp = any('crawled_at' in item for item in items)
    
    if has_timestamp:
        # 使用真實日期分組
        now = datetime.now()
        today_date = now.date()
        
        distribution = {i: 0 for i in range(days)}
        
        for item in items:
            if 'crawled_at' not in item:
                continue
                
            try:
                # 解析 ISO 格式時間戳記
                crawled_time = datetime.fromisoformat(item['crawled_at'])
                crawled_date = crawled_time.date()
                
                # 計算距離今天的天數
                delta = (today_date - crawled_date).days
                
                # 只統計近 N 天內的數據
                if 0 <= delta < days:
                    distribution[delta] += 1
                    
            except (ValueError, TypeError):
                # 如果解析失敗，跳過這筆資料
                continue
        
        return distribution
    else:
        # 向下兼容：沒有時間戳記時使用均分邏輯
        base_count = total // days
        remainder = total % days
        
        distribution = {}
        for i in range(days):
            # 餘數優先分配給最近的幾天（day_offset 0, 1, 2...）
            distribution[i] = base_count + (1 if i < remainder else 0)
        
        return distribution


if __name__ == '__main__':
    # 測試用：執行此檔案可看到統計結果
    verified, unverified, v_items, u_items = get_verification_stats()
    print(f"\n=== 查證資料統計 ===")
    print(f"已查證: {verified} 則")
    print(f"未查證: {unverified} 則")
    print(f"總計: {verified + unverified} 則")
    
    if v_items:
        print(f"\n已查證範例（前 3 則）:")
        for item in v_items[:3]:
            print(f"  - {item.get('title', '無標題')[:50]}...")
            print(f"    判斷: {item.get('short_judgement', '無')[:80]}")
