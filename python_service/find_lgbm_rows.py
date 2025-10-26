import os
import sys
from urllib.parse import urlparse
try:
    import psycopg2
except Exception as e:
    print('psycopg2 not available:', e)
    sys.exit(0)

db_url = os.environ.get('DATABASE_URL')
if not db_url:
    # try default used by app
    db_url = 'postgresql://postgres:1234@localhost:5432/truthliesdetector'

res = urlparse(db_url)
conn = None
try:
    conn = psycopg2.connect(dbname=res.path[1:], user=res.username, password=res.password, host=res.hostname, port=res.port)
    cur = conn.cursor()
    q = """
    SELECT id, user_id, created_at, ai_acc_result::text, gemini_result::text
    FROM chat_history
    WHERE (ai_acc_result::text ILIKE '%lgbm%' OR ai_acc_result::text ILIKE '%lightgbm%'
       OR gemini_result::text ILIKE '%lgbm%' OR gemini_result::text ILIKE '%lightgbm%')
    ORDER BY created_at DESC
    LIMIT 200;
    """
    cur.execute(q)
    rows = cur.fetchall()
    print('Found', len(rows), 'rows matching LGBM/LightGBM in ai_acc_result or gemini_result')
    for r in rows:
        id_, uid, created, aires, gemres = r
        print('---')
        print('id=', id_, 'user_id=', uid, 'created_at=', created)
        print('ai_acc_result:', aires)
        print('gemini_result:', gemres)

    cur.close()
except Exception as e:
    print('DB query error:', e)
    sys.exit(1)
finally:
    if conn:
        conn.close()
