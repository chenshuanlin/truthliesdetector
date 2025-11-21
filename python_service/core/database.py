# =====================================================================
# database.py — 最終正式版（支援 Chat Session、續問、Mutable JSONB）
# =====================================================================

import logging
from datetime import datetime
from sqlalchemy.orm.attributes import flag_modified

from models import db, ChatHistory, User


# ============================================================
# 初始化資料庫
# ============================================================
def init_db():
    try:
        db.create_all()
        logging.info("✅ DB 初始化完成")
    except Exception as e:
        logging.error(f"❌ DB 初始化失敗：{e}")


# ============================================================
# 1️⃣ 建立新的聊天 Session（第一次查證）
# ============================================================
def insert_chat_session(user_id, query_text, ai_acc_result, gemini_result, conversation):
    """
    新增一筆 chat session：
    - user_id
    - query_text
    - ai_acc_result（可信度分析）
    - gemini_result（AI 回覆）
    - conversation（完整對話 list）
    """
    try:
        # 檢查使用者是否存在
        user_obj = db.session.get(User, user_id) if user_id else None
        if not user_obj:
            logging.warning(f"⚠️ user_id {user_id} 不存在，設為 NULL")
            user_id = None

        session = ChatHistory(
            user_id=user_id,
            query_text=query_text,
            ai_acc_result=ai_acc_result,
            gemini_result=gemini_result,
            conversation=conversation,
            created_at=datetime.utcnow()
        )

        db.session.add(session)
        db.session.commit()

        logging.info(f"✅ 新增 session 完成 id={session.id}")
        return session.id

    except Exception as e:
        logging.error(f"❌ insert_chat_session 失敗：{e}")
        db.session.rollback()
        return None


# ============================================================
# 2️⃣ 追加對話（續問）
# ============================================================
def append_chat_conversation(session_id, message_item):
    """
    message_item 樣式：
    {
        "sender": "user/ai/system",
        "text": "...",
        "timestamp": "2025-01-01T12:33:00"
    }
    """

    try:
        session = db.session.get(ChatHistory, session_id)
        if not session:
            logging.warning(f"⚠️ append 失敗：session_id {session_id} 不存在")
            return False

        # 確保 conversation 為 list
        if not isinstance(session.conversation, list):
            logging.warning(f"⚠️ conversation 非 list，自動初始化")
            session.conversation = []

        # 加入訊息
        session.conversation.append(message_item)

        # ⭐⭐⭐ 確保 SQLAlchemy 強制更新 JSONB 欄位
        flag_modified(session, "conversation")

        db.session.commit()
        logging.info(f"📌 conversation append 成功 session_id={session_id}")
        return True

    except Exception as e:
        logging.error(f"❌ append_chat_conversation 失敗：{e}")
        db.session.rollback()
        return False


# ============================================================
# 3️⃣ 查詢最新 N 筆 Session（AIacc 使用）
# ============================================================
def get_recent_chat_sessions(user_id, limit=5):
    """
    回傳格式：
    [
        {
            "id": ...,
            "query_text": "...",
            "created_at": "...",
            "conversation": [...],
            "ai_acc_result": {...},
            "gemini_result": {...}
        }
    ]
    """
    try:
        user_obj = db.session.get(User, user_id) if user_id else None
        if not user_obj:
            logging.warning(f"⚠️ user_id {user_id} 不存在 → 回傳空陣列")
            return []

        rows = (
            ChatHistory.query
            .filter_by(user_id=user_id)
            .order_by(ChatHistory.created_at.desc())
            .limit(limit)
            .all()
        )

        return [
            {
                "id": r.id,
                "user_id": r.user_id,
                "query_text": r.query_text,
                "created_at": r.created_at.isoformat(),
                "conversation": r.conversation or [],
                "ai_acc_result": r.ai_acc_result,
                "gemini_result": r.gemini_result,
            }
            for r in rows
        ]

    except Exception as e:
        logging.error(f"❌ get_recent_chat_sessions 失敗：{e}")
        return []


# ============================================================
# 4️⃣（保留）一般歷史查詢
# ============================================================
def get_chat_history(limit=50, user_id=None):
    try:
        q = ChatHistory.query.order_by(ChatHistory.created_at.desc())

        if user_id:
            q = q.filter_by(user_id=user_id)

        rows = q.limit(limit).all()

        return [
            {
                "id": r.id,
                "user_id": r.user_id,
                "query_text": r.query_text,
                "ai_acc_result": r.ai_acc_result,
                "gemini_result": r.gemini_result,
                "created_at": r.created_at.isoformat(),
                "conversation": r.conversation or [],
            }
            for r in rows
        ]

    except Exception as e:
        logging.error(f"❌ get_chat_history 失敗：{e}")
        return []
