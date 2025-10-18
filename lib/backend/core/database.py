import psycopg2
import logging

DB_CONFIG = {
    "dbname": "truthliesdetector",
    "user": "postgres",
    "password": "1234",
    "host": "localhost",
    "port": "5432"
}

def get_connection():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logging.error(f"❌ 無法連線資料庫: {e}")
        return None

def insert_chat_history(user_message, ai_response):
    conn = get_connection()
    if not conn:
        return
    try:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS chat_history (
                    id SERIAL PRIMARY KEY,
                    user_message TEXT,
                    ai_response TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            cur.execute(
                "INSERT INTO chat_history (user_message, ai_response) VALUES (%s, %s);",
                (user_message, ai_response)
            )
            conn.commit()
    except Exception as e:
        logging.warning(f"⚠️ 寫入資料庫失敗：{e}")
    finally:
        conn.close()
