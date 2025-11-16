import sys
import traceback

if __name__ == "__main__":
    try:
        print("[INFO] 開始執行定時爬蟲...")
        with open("scraper.py", encoding="utf-8") as f:
            code = f.read()
        exec(code, {"__name__": "__main__"})
        print("[INFO] 爬蟲執行完成！")
    except Exception as e:
        print(f"[ERROR] 爬蟲執行失敗: {e}")
        traceback.print_exc()
        sys.exit(1)
