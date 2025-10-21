"""
每日自動爬蟲腳本
每天自動執行，抓取最新的新聞資料
"""
import subprocess
import sys
from datetime import datetime
import os

def run_daily_crawler():
    """執行每日爬蟲任務"""
    print(f"[{datetime.now()}] 開始執行每日爬蟲任務...")
    
    # 切換到 projectt 目錄
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    # 定義多個關鍵字，輪流使用
    keywords = ["健康", "政治", "經濟", "科技", "社會"]
    today = datetime.now()
    # 根據日期選擇關鍵字（每天不同）
    keyword = keywords[today.day % len(keywords)]
    
    print(f"今日關鍵字: {keyword}")
    print(f"抓取數量: 5 則")
    
    try:
        # 執行爬蟲
        result = subprocess.run(
            [sys.executable, "scraper.py", 
             "--query", keyword, 
             "--max-results", "5", 
             "--save"],
            capture_output=True,
            text=True,
            encoding='utf-8',
            errors='replace'
        )
        
        print("=" * 60)
        print("爬蟲執行結果:")
        print("=" * 60)
        print(result.stdout)
        
        if result.returncode == 0:
            print(f"[{datetime.now()}] ✓ 爬蟲執行成功！")
            return True
        else:
            print(f"[{datetime.now()}] ✗ 爬蟲執行失敗")
            print("錯誤訊息:")
            print(result.stderr)
            return False
            
    except Exception as e:
        print(f"[{datetime.now()}] ✗ 發生錯誤: {e}")
        return False

if __name__ == "__main__":
    success = run_daily_crawler()
    sys.exit(0 if success else 1)
