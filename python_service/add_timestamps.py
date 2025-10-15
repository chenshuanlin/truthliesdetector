#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""為所有 JSON 檔案根據檔名加入時間戳記"""

import json
import re
from pathlib import Path
from datetime import datetime

reports_dir = Path('C:/Users/rin/Desktop/truthliesdetector/projectt/reports')

for json_file in reports_dir.glob('raw_*.json'):
    # 從檔名提取日期時間: raw_20251015_195225.json
    match = re.match(r'raw_(\d{8})_(\d{6})\.json', json_file.name)
    if not match:
        print(f"⚠️ 跳過 {json_file.name} (無法解析檔名)")
        continue
    
    date_str, time_str = match.groups()
    # 格式化為 ISO 時間: 2025-10-15T19:52:25
    timestamp = f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:8]}T{time_str[:2]}:{time_str[2:4]}:{time_str[4:6]}"
    
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # 為每個 item 加入 crawled_at
        items_updated = 0
        for item in data.get('items', []):
            if 'crawled_at' not in item:
                item['crawled_at'] = timestamp
                items_updated += 1
        
        # 寫回檔案
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ {json_file.name}: 更新了 {items_updated} 筆資料的時間戳記 ({timestamp})")
        
    except Exception as e:
        print(f"❌ {json_file.name}: 處理失敗 - {e}")

print("\n完成！")
