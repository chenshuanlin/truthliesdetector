import sqlite3
import os
p = os.path.join(os.path.dirname(__file__), 'local.db')
print('db path:', p, 'exists=', os.path.exists(p))
try:
    conn = sqlite3.connect(p)
    cur = conn.cursor()
    cur.execute("SELECT id,user_id,query_text,created_at FROM chat_history ORDER BY created_at DESC LIMIT 20")
    rows = cur.fetchall()
    print('rows:', len(rows))
    for r in rows:
        print(r)
    cur.close(); conn.close()
except Exception as e:
    print('err', e)
