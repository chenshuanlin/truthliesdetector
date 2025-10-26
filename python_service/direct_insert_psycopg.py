import os
import json
from urllib.parse import urlparse
import psycopg2

db_url = os.environ.get('DATABASE_URL')
print('DB_URL=', db_url)
res = urlparse(db_url)
conn = psycopg2.connect(dbname=res.path[1:], user=res.username, password=res.password, host=res.hostname, port=res.port)
cur = conn.cursor()
try:
    cur.execute("INSERT INTO chat_history (user_id, query_text, ai_acc_result, gemini_result) VALUES (%s, %s, %s::jsonb, %s::jsonb) RETURNING id;",
                (1, 'direct insert test', json.dumps({'level':'test'} , ensure_ascii=False), json.dumps({'reply':'ok'}, ensure_ascii=False)))
    rid = cur.fetchone()[0]
    conn.commit()
    print('inserted id', rid)
    cur.execute("SELECT id, user_id, query_text, created_at FROM chat_history ORDER BY created_at DESC LIMIT 5;")
    rows = cur.fetchall()
    print('rows count', len(rows))
    for r in rows:
        print(r)
except Exception as e:
    print('error', e)
    conn.rollback()
finally:
    cur.close()
    conn.close()
