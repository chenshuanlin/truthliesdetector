# =====================================================================
# database.py — Chat Session + JSONB + ROLLBACK 修正版（最終版）
# =====================================================================

import logging
from datetime import datetime
from sqlalchemy.orm.attributes import flag_modified

from models import db, ChatHistory, User


# ============================================================
# 初始化 DB
# ============================================================
def init_db():
    try:
        db.create_all()
        logging.info("✅ DB 初始化完成")
    except Exception as e:
        logging.error(f"❌ DB 初始化失敗：{e}")


# ============================================================
# 1️⃣ 建立新的聊天 Session
# ============================================================
def insert_chat_session(user_id, query_text, ai_acc_result, gemini_result, conversation):
    try:
        # User 是否存在
        user_obj = db.session.get(User, user_id) if user_id else None
        if not user_obj:
            logging.warning(f"⚠ user_id {user_id} 不存在 → 改為 NULL")
            user_id = None

        # conversation 必須是 list
        if isinstance(conversation, str):
            logging.error("⚠ conversation 是字串 → 自動改為 []")
            conversation = []

        session = ChatHistory(
            user_id=user_id,
            query_text=query_text,
            ai_acc_result=ai_acc_result,
            gemini_result=gemini_result,
            conversation=conversation,
            created_at=datetime.utcnow(),
        )

        db.session.add(session)
        db.session.commit()

        logging.info(f"✅ 新增 session 成功 id={session.id}")
        return session.id

    except Exception as e:
        logging.error(f"❌ insert_chat_session error: {e}", exc_info=True)
        db.session.rollback()
        return None


# ============================================================
# 2️⃣ 新增對話（append）
# ============================================================
def append_chat_conversation(session_id, message_item):
    try:
        session = db.session.get(ChatHistory, session_id)
        if not session:
            logging.warning(f"⚠ session_id {session_id} 不存在")
            return False

        # conversation 必須是 list
        if isinstance(session.conversation, str):
            logging.error("⚠ conversation 居然是字串 → 強制改為空 list")
            session.conversation = []

        if not isinstance(session.conversation, list):
            logging.error("⚠ conversation 型別錯誤 → 初始化為空 list")
            session.conversation = []

        # append
        session.conversation.append(message_item)

        # ⭐ 讓 SQLAlchemy 確認 JSONB 欄位有變化
        flag_modified(session, "conversation")

        db.session.commit()
        logging.info(f"📌 append 成功 session_id={session_id}")
        return True

    except Exception as e:
        logging.error(f"❌ append_chat_conversation error: {e}", exc_info=True)
        db.session.rollback()
        return False


# ============================================================
# 3️⃣ 取得最新 Chat Sessions（給前端歷史紀錄用）
# ============================================================
def get_recent_chat_sessions(user_id, limit=5):
    try:
        user_obj = db.session.get(User, user_id)
        if not user_obj:
            logging.warning(f"⚠ user_id {user_id} 不存在 → 回傳空陣列")
            return []

        rows = (
            ChatHistory.query
            .filter_by(user_id=user_id)
            .order_by(ChatHistory.created_at.desc())
            .limit(limit)
            .all()
        )

        result = []
        for r in rows:
            # conversation 必須是 list
            conv = r.conversation
            if isinstance(conv, str):
                logging.error(f"⚠ id={r.id} conversation 是字串 → 修正")
                conv = []

            result.append({
                "id": r.id,
                "user_id": r.user_id,
                "query_text": r.query_text,
                "created_at": r.created_at.isoformat(),
                "conversation": conv,
                "ai_acc_result": r.ai_acc_result,
                "gemini_result": r.gemini_result,
            })

        return result

    except Exception as e:
        logging.error(f"❌ get_recent_chat_sessions error: {e}", exc_info=True)
        return []


# ============================================================
# 4️⃣ 一般歷史查詢（保留）
# ============================================================
def get_chat_history(limit=50, user_id=None):
    try:
        q = ChatHistory.query.order_by(ChatHistory.created_at.desc())
        if user_id:
            q = q.filter_by(user_id=user_id)

        rows = q.limit(limit).all()

        result = []
        for r in rows:
            conv = r.conversation
            if isinstance(conv, str):
                logging.error(f"⚠ id={r.id} conversation 是字串 → 修正")
                conv = []

            result.append({
                "id": r.id,
                "user_id": r.user_id,
                "query_text": r.query_text,
                "ai_acc_result": r.ai_acc_result,
                "gemini_result": r.gemini_result,
                "created_at": r.created_at.isoformat(),
                "conversation": conv,
            })

        return result

    except Exception as e:
        logging.error(f"❌ get_chat_history error: {e}", exc_info=True)
        return []
