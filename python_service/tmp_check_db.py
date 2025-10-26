import os, sys
from urllib.parse import urlparse
try:
    import psycopg2
except Exception as e:
    print('psycopg2 not available:', e)
    sys.exit(0)

db_url = os.environ.get('DATABASE_URL')
print('DATABASE_URL=', db_url)
if not db_url:
    sys.exit(0)

res = urlparse(db_url)
try:
    conn = psycopg2.connect(dbname=res.path[1:], user=res.username, password=res.password, host=res.hostname, port=res.port)
    cur = conn.cursor()
    cur.execute("SELECT id, user_id, query_text, created_at FROM chat_history ORDER BY created_at DESC LIMIT 10;")
    rows = cur.fetchall()
    print('found rows:', len(rows))
    for r in rows:
        print(r)
    cur.close()
    conn.close()
except Exception as e:
    print('DB query error:', e)
    sys.exit(1)
