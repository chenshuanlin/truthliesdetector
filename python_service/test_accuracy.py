import requests

r = requests.get('http://127.0.0.1:5000/api/fake-news-stats')
stats = r.json()['stats']
print(f"已驗證: {stats['totalVerified']}")
print(f"疑似: {stats['totalSuspicious']}")
print(f"AI辨識率: {stats['aiAccuracy']}%")
print(f"\n計算方式: {stats['totalVerified']} / ({stats['totalVerified']} + {stats['totalSuspicious']}) × 100 = {stats['aiAccuracy']}%")
