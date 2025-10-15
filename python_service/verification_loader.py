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
    # 找到 projectt/reports 資料夾（相對於此檔案）
    current_dir = Path(__file__).parent
    reports_dir = current_dir.parent / 'projectt' / 'reports'
    
    if not reports_dir.exists():
        print(f"警告：找不到查證資料資料夾 {reports_dir}")
        return []
    
    all_items = []
    json_files = list(reports_dir.glob('raw_*.json'))
    
    if not json_files:
        print(f"警告：在 {reports_dir} 找不到任何 raw_*.json 檔案")
        return []
    
    print(f"找到 {len(json_files)} 個查證資料檔案")
    
    for json_file in json_files:
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                items = data.get('items', [])
                all_items.extend(items)
                print(f"  ✓ 載入 {json_file.name}: {len(items)} 則新聞")
        except Exception as e:
            print(f"  ✗ 載入 {json_file.name} 失敗: {e}")
            continue
    
    print(f"總共載入 {len(all_items)} 則新聞")
    return all_items


def classify_item(item: Dict) -> str:
    """
    將單一新聞條目分類為 'verified'（已查證）或 'unverified'（未查證）
    
    分類邏輯：
    1. 優先依 short_judgement 關鍵字判斷
    2. 輔助依 ann_features 的 evidence_quality 分數判斷
    """
    # 1. 依 short_judgement 判斷
    sj = item.get('short_judgement', '')
    
    # 已查證的關鍵字（明確標示可信、假訊息、不實等）
    verified_keywords = [
        '可信', '查證', '已查證', '經查證', '假訊息', '不實', '謠言', 
        '經證實', '經查核', '經審查', '確認', '事實查核', '闢謠'
    ]
    
    if any(k in sj for k in verified_keywords):
        return 'verified'
    
    # 2. 依 ann_features 分數輔助判斷
    ann = item.get('ann_features', {})
    evidence_quality = ann.get('evidence_quality', 0)
    source_score = ann.get('source_entity_score', 0)
    
    # 若證據品質與來源分數都很高，視為已查證
    if evidence_quality >= 0.8 and source_score >= 0.8:
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
