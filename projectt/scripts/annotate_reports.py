# Script: annotate_reports.py
# Purpose: Load a reports JSON file and add ai_level/ai_score/ai_summary to items
# Usage: run from project root with the project's venv python

import json
import time
import sys
import os
from pathlib import Path

# ensure project root in path
ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scraper import CredibilityAnalyzerClient, calculate_article_features, GEMINI_API_KEY

REPORT_PATH = ROOT / 'reports' / 'raw_20251009_021724.json'

if not REPORT_PATH.exists():
    print(f"Report not found: {REPORT_PATH}")
    sys.exit(2)

with open(REPORT_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

items = data.get('items', [])

analyzer = CredibilityAnalyzerClient(api_key=GEMINI_API_KEY)

updated = 0
for it in items:
    # Skip if already has ai_level
    if it.get('ai_level') is not None:
        continue
    title = it.get('title', '')
    content = it.get('content', '')
    url = it.get('url', '')
    domain = it.get('domain', '')

    feats = calculate_article_features(url, title, content, domain)
    try:
        out = analyzer.perform_llm_analysis(title, content, feats)
        it['ai_level'] = out.credibility_level
        try:
            it['ai_score'] = float(out.confidence_score)
        except Exception:
            it['ai_score'] = out.confidence_score
        it['ai_summary'] = out.summary
        updated += 1
    except Exception as e:
        it['ai_level'] = None
        it['ai_score'] = None
        it['ai_summary'] = ''
    # small pause to avoid rate spikes
    time.sleep(0.5)

# write back
backup = REPORT_PATH.with_suffix('.bak.json')
with open(backup, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

with open(REPORT_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Annotated {updated} items in {REPORT_PATH}")
print(f"Backup saved to {backup}")
