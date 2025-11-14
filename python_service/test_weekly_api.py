#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""測試 API 返回的每周數據"""

import requests

url = 'http://localhost:5000/api/fake-news-stats'
response = requests.get(url)
data = response.json()

weekly = data['stats']['weeklyReports']

print("\n=== API 返回的每周數據（現在使用真實日期分佈）===\n")
print("星期 | 已查證 | 疑似")
print("-" * 30)
for w in weekly:
    print(f"{w['day']:^4} | {w['verified']:^6} | {w['suspicious']:^4}")

print(f"\n總計: 已查證={data['stats']['totalVerified']}, 疑似={data['stats']['totalSuspicious']}")
print(f"AI 辨識率: {data['stats']['aiAccuracy']}%")
