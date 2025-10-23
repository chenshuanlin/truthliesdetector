# daily_crawler.py
"""
每天自動執行爬蟲腳本，無需手動觸發。
可用於 Flask 啟動時由後台 Thread 啟動，或由主程式調用。
"""
import threading
import time
import subprocess
import sys
from pathlib import Path
from datetime import datetime, timedelta

# 爬蟲腳本與 Python 執行檔路徑
SCRAPER_PATH = Path(__file__).parent.parent / 'projectt' / 'scraper.py'

# 使用當前 Python 執行檔（更可靠）
PYTHON_EXE = sys.executable

# 多領域關鍵字
DEFAULT_KEYWORDS = [
    '疫苗', '健康', '減肥', '投資', '詐騙',
    '選舉', '政治', '經濟', '科技', '社會',
    '國際', '環保', '教育', '醫療'
]

MAX_RESULTS = 30

_last_run = None


def run_daily_crawler():
    """每天執行一次爬蟲"""
    global _last_run
    
    print(f"[定時爬蟲] 已啟動，Python 路徑: {PYTHON_EXE}")
    print(f"[定時爬蟲] 爬蟲腳本: {SCRAPER_PATH}")
    
    # 檢查路徑是否存在
    if not SCRAPER_PATH.exists():
        print(f"[定時爬蟲] ❌ 錯誤：爬蟲腳本不存在 {SCRAPER_PATH}")
        return
    
    while True:
        now = datetime.now()
        # 若今天尚未執行過
        if not _last_run or _last_run.date() != now.date():
            print(f"\n[定時爬蟲] {now:%Y-%m-%d %H:%M:%S} 開始執行每日爬蟲...")
            success_count = 0
            fail_count = 0
            
            for keyword in DEFAULT_KEYWORDS[:10]:
                try:
                    print(f"[定時爬蟲] 正在爬取關鍵字: {keyword}")
                    
                    # 增加超時時間到 120 秒，因為爬蟲需要呼叫外部 API
                    process = subprocess.Popen(
                        [PYTHON_EXE, str(SCRAPER_PATH), '--query', keyword, '--max-results', str(MAX_RESULTS)],
                        cwd=str(SCRAPER_PATH.parent),
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        text=True
                    )
                    
                    try:
                        stdout, stderr = process.communicate(timeout=120)
                        if process.returncode == 0:
                            print(f"[定時爬蟲] ✅ 完成: {keyword}")
                            success_count += 1
                        else:
                            print(f"[定時爬蟲] ⚠️ 失敗: {keyword}")
                            if stderr:
                                print(f"[定時爬蟲]    錯誤訊息: {stderr[:200]}")
                            fail_count += 1
                    except subprocess.TimeoutExpired:
                        process.kill()
                        print(f"[定時爬蟲] ⏱️ 超時 (120秒): {keyword}")
                        fail_count += 1
                        
                except Exception as e:
                    print(f"[定時爬蟲] ❌ 例外錯誤: {keyword}: {e}")
                    fail_count += 1
                
                # 每個關鍵字之間暫停 2 秒，避免 API 請求過於頻繁
                time.sleep(2)
            
            _last_run = now
            print(f"\n[定時爬蟲] 本日爬蟲執行完畢！成功: {success_count}, 失敗: {fail_count}")
            print(f"[定時爬蟲] 下次執行時間: {(now + timedelta(days=1)).strftime('%Y-%m-%d')}")
        
        # 每小時檢查一次是否需要執行
        time.sleep(3600)

def start_daily_crawler_thread():
    t = threading.Thread(target=run_daily_crawler, daemon=True)
    t.start()
