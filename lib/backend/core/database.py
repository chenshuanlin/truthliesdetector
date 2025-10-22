import os
import psycopg2
import logging
import json
from urllib.parse import urlparse
from dotenv import load_dotenv

load_dotenv()

# =========================================================
# 🔹 建立資料庫連線
# =========================================================
def get_connection():
    """建立 PostgreSQL 連線"""
    try:
        db_url = os.getenv("DATABASE_URL")
        if db_url:
            result = urlparse(db_url)
            conn = psycopg2.connect(
                dbname=result.path[1:],
                user=result.username,
                password=result.password,
                host=result.hostname,
                port=result.port,
            )
            logging.info("✅ 已連線 PostgreSQL")
            return conn
        else:
            logging.error("⚠️ 缺少 DATABASE_URL")
            return None
    except Exception as e:
        logging.error(f"⚠️ 資料庫連線失敗：{e}")
        return None


# =========================================================
# 🔹 初始化資料表
# =========================================================
def init_db():
    """自動建立所有資料表"""
    conn = get_connection()
    if not conn:
        logging.warning("⚠️ 無法連線資料庫，略過建立資料表。")
        return

    try:
        cur = conn.cursor()
        logging.info("🧱 初始化資料庫結構...")

        cur.execute("""
        CREATE TABLE IF NOT EXISTS public.users (
            user_id SERIAL PRIMARY KEY,
            account VARCHAR(50) NOT NULL,
            username VARCHAR(50) NOT NULL,
            password VARCHAR(100) NOT NULL,
            email VARCHAR(100),
            phone TEXT
        );

        CREATE TABLE IF NOT EXISTS public.articles (
            article_id SERIAL PRIMARY KEY,
            title VARCHAR(200) NOT NULL,
            content TEXT NOT NULL,
            category VARCHAR(50),
            source_link TEXT,
            media_name VARCHAR(100),
            created_time TIMESTAMP,
            published_time TIMESTAMP,
            reliability_score NUMERIC(3,2)
        );

        CREATE TABLE IF NOT EXISTS public.reports (
            report_id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES public.users(user_id),
            article_id INTEGER REFERENCES public.articles(article_id),
            reason TEXT,
            status VARCHAR(20),
            reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS public.analysis_results (
            analysis_id SERIAL PRIMARY KEY,
            article_id INTEGER REFERENCES public.articles(article_id),
            user_id INTEGER REFERENCES public.users(user_id),
            explanation TEXT,
            analyzed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            keywords TEXT,
            category VARCHAR(50),
            confidence_score NUMERIC(3,2),
            risk_level VARCHAR(20),
            report_id INTEGER REFERENCES public.reports(report_id)
        );

        CREATE TABLE IF NOT EXISTS chat_history (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES public.users(user_id),
            query_text TEXT,
            ai_acc_result JSONB,
            gemini_result JSONB,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """)

        conn.commit()
        cur.close()
        conn.close()
        logging.info("✅ 資料表初始化完成。")
    except Exception as e:
        logging.error(f"⚠️ 建立或修正資料表失敗：{e}")


# =========================================================
# 🔹 寫入分析結果
# =========================================================
def insert_analysis_result(explanation, score, level, summary, keywords=None, category=None):
    """寫入新版 analysis_results 結構"""
    conn = get_connection()
    if not conn:
        logging.warning("⚠️ 無法連線資料庫，略過寫入。")
        return

    try:
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO analysis_results (
                explanation,
                confidence_score,
                risk_level,
                keywords,
                category
            )
            VALUES (%s, %s, %s, %s, %s);
        """, (summary[:300], round(score, 2), level, keywords or '', category or ''))
        conn.commit()
        cur.close()
        conn.close()
        logging.info(f"✅ 已寫入 analysis_results：{level}（score={score:.2f}）")
    except Exception as e:
        logging.error(f"⚠️ 寫入 analysis_results 失敗：{e}")


# =========================================================
# 🔹 儲存對話歷史（支援 user_id）
# =========================================================
def insert_chat_history(query_text, ai_acc_result=None, gemini_result=None, user_id=None):
    """儲存使用者查詢與 AI 回覆，可綁定 user_id"""
    conn = get_connection()
    if not conn:
        logging.warning("⚠️ 無法連線資料庫，略過對話寫入。")
        return

    try:
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO chat_history (user_id, query_text, ai_acc_result, gemini_result)
            VALUES (%s, %s, %s::jsonb, %s::jsonb);
        """, (
            user_id,
            query_text,
            json.dumps(ai_acc_result or {}, ensure_ascii=False),
            json.dumps(gemini_result or {}, ensure_ascii=False)
        ))
        conn.commit()
        cur.close()
        conn.close()
        logging.info(f"💬 已新增 chat_history：{query_text[:30]}... (user_id={user_id})")
    except Exception as e:
        logging.error(f"⚠️ 寫入 chat_history 失敗：{e}")


# =========================================================
# 🔹 讀取對話歷史（依 user_id 過濾）
# =========================================================
def get_chat_history(limit=50, user_id=None):
    """取得最近的聊天紀錄，可指定 user_id"""
    conn = get_connection()
    if not conn:
        logging.warning("⚠️ 無法連線資料庫，略過讀取。")
        return []

    try:
        cur = conn.cursor()
        if user_id:
            cur.execute("""
                SELECT id, user_id, query_text, ai_acc_result, gemini_result, created_at
                FROM chat_history
                WHERE user_id = %s
                ORDER BY created_at DESC
                LIMIT %s;
            """, (user_id, limit))
        else:
            cur.execute("""
                SELECT id, user_id, query_text, ai_acc_result, gemini_result, created_at
                FROM chat_history
                ORDER BY created_at DESC
                LIMIT %s;
            """, (limit,))
        rows = cur.fetchall()
        cur.close()
        conn.close()

        history = []
        for row in rows:
            history.append({
                "id": row[0],
                "user_id": row[1],
                "query_text": row[2],
                "ai_acc_result": _safe_json(row[3]),
                "gemini_result": _safe_json(row[4]),
                "created_at": row[5].isoformat() if row[5] else None
            })
        return history
    except Exception as e:
        logging.error(f"⚠️ 讀取 chat_history 失敗：{e}")
        return []


# =========================================================
# 🔸 輔助函式：安全解析 JSON 欄位
# =========================================================
def _safe_json(data):
    """安全地將字串轉為 JSON"""
    try:
        if isinstance(data, dict):
            return data
        if isinstance(data, str) and data.strip().startswith("{"):
            return json.loads(data)
        return {}
    except Exception:
        return {}


# =========================================================
# 🔹 自動清理舊的聊天紀錄（30天前）
# =========================================================
def cleanup_old_chat_history(days=30):
    """刪除超過指定天數的舊聊天紀錄"""
    conn = get_connection()
    if not conn:
        logging.warning("⚠️ 無法連線資料庫，略過清理。")
        return

    try:
        cur = conn.cursor()
        cur.execute(f"""
            DELETE FROM chat_history
            WHERE created_at < NOW() - INTERVAL '{days} days';
        """)
        deleted = cur.rowcount
        conn.commit()
        cur.close()
        conn.close()

        if deleted > 0:
            logging.info(f"🧹 已清理 {deleted} 筆超過 {days} 天的聊天紀錄。")
        else:
            logging.info("🧹 無需清理，聊天紀錄皆為近期資料。")
    except Exception as e:
        logging.error(f"⚠️ 清理舊聊天紀錄失敗：{e}")
