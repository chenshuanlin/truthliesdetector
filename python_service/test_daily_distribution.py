#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""測試每日分佈功能"""

import sys
sys.path.insert(0, 'C:/Users/rin/Desktop/truthliesdetector/python_service')

from verification_loader import get_verification_stats, get_daily_distribution

# 取得數據
v_count, u_count, v_items, u_items = get_verification_stats()

print(f"\n總數據: 已查證 {v_count} 則，疑似 {u_count} 則")

# 檢查是否有時間戳記
has_timestamp = any('crawled_at' in item for item in v_items + u_items)
print(f"數據是否包含時間戳記: {'是' if has_timestamp else '否'}")

# 取得每日分佈
v_daily = get_daily_distribution(v_items, 7)
u_daily = get_daily_distribution(u_items, 7)

print("\n=== 已查證每日分佈 ===")
for i in range(7):
    print(f"距今 {i} 天: {v_daily[i]} 則")

print("\n=== 疑似每日分佈 ===")
for i in range(7):
    print(f"距今 {i} 天: {u_daily[i]} 則")

print("\n=== 範例數據（前3筆）===")
for item in (v_items + u_items)[:3]:
    print(f"- {item.get('title', 'N/A')[:50]}")
    print(f"  爬取時間: {item.get('crawled_at', '無時間戳記')}")
