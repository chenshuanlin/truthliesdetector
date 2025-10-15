import requests

r = requests.get('http://127.0.0.1:5000/api/fake-news-stats')
stats = r.json()['stats']

total_verified = stats['totalVerified']
total_suspicious = stats['totalSuspicious']
ai_accuracy = stats['aiAccuracy']
total = total_verified + total_suspicious

calculated = round((total_verified / total * 100)) if total > 0 else 0

print(f"已驗證: {total_verified}")
print(f"疑似: {total_suspicious}")
print(f"總數: {total}")
print(f"API 返回的 AI 辨識率: {ai_accuracy}%")
print(f"應該計算的 AI 辨識率: {calculated}%")
print(f"計算公式: {total_verified} / {total} * 100 = {calculated}%")
