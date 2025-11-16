# =====================================================================
# database.py  — 最終穩定版，完全對應你的 models.py
# =====================================================================

import logging
from datetime import datetime, timedelta

# ============================================================
#  正確匯入 models 中的 SQLAlchemy db 與 ChatHistory / User
# ============================================================
try:
    from models import db, ChatHistory, User
except Exception as e:
    logging.error(f"❌ 無法從 models 匯入資料庫模型：{e}")
    db = None
    ChatHistory = None
    User = None


# ============================================================
#  初始化資料庫
# ============================================================
def init_db():
    if db:
        try:
            db.create_all()
            logging.info("✅ DB 初始化完成")
        except Exception as e:
            logging.error(f"❌ DB 初始化失敗：{e}")
    else:
        logging.warning("⚠️ DB 未正確載入，略過初始化")


# ============================================================
#  寫入聊天紀錄
# ============================================================
def insert_chat_history(query_text, ai_acc_result, gemini_result, user_id=None):
    print(f"[insert_chat_history] user_id={user_id}")

    # DB 未初始化 → 跳過
    if db is None or ChatHistory is None:
        print("❌ DB 或模型未載入，跳過 insert")
        return

    # ============================================================
    #  驗證 user_id（避免 FK 錯誤）
    # ============================================================
    user_id_to_use = None
    if user_id is not None:
        try:
            exists = db.session.get(User, user_id)
            if exists:
                user_id_to_use = user_id
            else:
                print(f"⚠️ user_id {user_id} 不存在 → 改為 NULL")
        except Exception as e:
            print(f"⚠️ 檢查 user_id 時發生錯誤：{e}")

    # ============================================================
    #  寫入資料庫
    # ============================================================
    try:
        record = ChatHistory(
            user_id=user_id_to_use,
            query_text=query_text,
            ai_acc_result=ai_acc_result,
            gemini_result=gemini_result,
            created_at=datetime.utcnow(),
        )

        db.session.add(record)
        db.session.commit()

        print(f"✅ chat_history 寫入成功 id={record.id}")

    except Exception as e:
        print(f"❌ 無法寫入 chat_history：{e}")
        import traceback
        print(traceback.format_exc())


# ============================================================
#  讀取聊天紀錄
# ============================================================
def get_chat_history(limit=50, user_id=None):
    if db is None or ChatHistory is None:
        return []

    try:
        q = ChatHistory.query.order_by(ChatHistory.created_at.desc())

        if user_id is not None:
            try:
                uid = int(user_id)
                q = q.filter_by(user_id=uid)
            except:
                pass

        records = q.limit(limit).all()

        return [
            {
                "id": r.id,
                "user_id": r.user_id,
                "query": r.query_text,
                "ai_acc_result": r.ai_acc_result,
                "gemini_result": r.gemini_result,
                "created_at": r.created_at.isoformat(),
            }
            for r in records
        ]

    except Exception as e:
        logging.error(f"❌ 讀取 chat_history 失敗：{e}")
        return []


# ============================================================
#  清除 30 天以上紀錄
# ============================================================
def cleanup_old_chat_history(days=30):
    if db is None or ChatHistory is None:
        return

    try:
        cutoff = datetime.utcnow() - timedelta(days=days)
        ChatHistory.query.filter(ChatHistory.created_at < cutoff).delete()
        db.session.commit()
        logging.info("🧹 已清除過期 chat_history")
    except Exception as e:
        logging.warning(f"⚠️ 清除舊紀錄失敗：{e}")
