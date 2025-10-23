import requests
import json
import time

# 等待 Flask 完全啟動
time.sleep(2)

try:
    response = requests.get('http://localhost:5000/api/fake-news-stats')
    print(f'Status: {response.status_code}')
    
    if response.status_code == 200:
        data = response.json()
        
        print(f'\n總筆數: {data["total"]}')
        print(f'已查證: {data["totalVerified"]}')
        print(f'疑似: {data["totalSuspicious"]}')
        print(f'AI辨識率: {data["aiAccuracy"]}%')
        
        print(f'\n週報數據點: {len(data["weeklyReports"])}')
        print('\n已查證每日分佈 (過去7天):')
        for i, report in enumerate(data['weeklyReports']):
            print(f'距今 {i} 天: {report["verifiedCount"]} 則')
            
        print('\n疑似每日分佈 (過去7天):')
        for i, report in enumerate(data['weeklyReports']):
            print(f'距今 {i} 天: {report["suspiciousCount"]} 則')
    else:
        print(f'Error: {response.text}')
except Exception as e:
    print(f'請求失敗: {e}')
