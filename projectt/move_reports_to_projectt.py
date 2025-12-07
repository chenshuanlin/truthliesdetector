"""
將 repo 根目錄下的 reports/raw_*.json 檔案移動到 projectt/reports
- 若目的地不存在則建立
- 若檔名衝突，會在檔名末端加上 _moved_{timestamp}.json
- 列印處理結果與摘要

用法：
    python move_reports_to_projectt.py
"""
from pathlib import Path
import shutil
from datetime import datetime

ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / 'reports'
DST_DIR = ROOT / 'projectt' / 'reports'

if not SRC_DIR.exists():
    print(f"來源資料夾不存在：{SRC_DIR}")
    raise SystemExit(1)

DST_DIR.mkdir(parents=True, exist_ok=True)

files = sorted(SRC_DIR.glob('raw_*.json'))
if not files:
    print("來源資料夾沒有 raw_*.json 檔案，無需處理。")
    raise SystemExit(0)

moved = []
skipped = []

for f in files:
    dest = DST_DIR / f.name
    if dest.exists():
        # 若目的地已存在，改成加上 timestamp 的新檔名
        ts = datetime.now().strftime('%Y%m%d_%H%M%S')
        new_name = f.stem + f'_moved_{ts}.json'
        dest = DST_DIR / new_name
        print(f"目的地已存在同名檔案，將來源檔案改名為: {dest.name}")
    try:
        shutil.move(str(f), str(dest))
        moved.append(dest.name)
        print(f"搬移: {f.name} -> projectt/reports/{dest.name}")
    except Exception as e:
        print(f"搬移失敗: {f.name} ({e})")
        skipped.append(f.name)

print("\n=== 摘要 ===")
print(f"總共找到 {len(files)} 個檔案")
print(f"成功搬移 {len(moved)} 個檔案")
if skipped:
    print(f"失敗 {len(skipped)} 個: {skipped}")
else:
    print("全部成功搬移。")
