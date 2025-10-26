# lightweight DB wrapper used by routes (delegates to existing models if available)
import logging
from datetime import datetime, timedelta

try:
    # try to import existing SQLAlchemy models from project's models.py
    from models import db, ChatHistory, AnalysisResult
except Exception:
    # fallback minimal implementations (in case original models are different)
    db = None


def init_db():
    if db:
        db.create_all()
    logging.info("DB init complete (if SQLAlchemy configured)")


def insert_chat_history(query_text, ai_acc_result, gemini_result, user_id=None):
    try:
        # debug: print so we can always see this in server output
        print(f"insert_chat_history called (module db is {'set' if db else 'None'}, user_id={user_id})")
        # if db wasn't available at module import time, try to import models now
        local_db = db
        local_ChatHistory = None
        if local_db is None:
            try:
                from models import db as local_db, ChatHistory as local_ChatHistory
                print('Dynamically imported models inside insert_chat_history')
            except Exception as e:
                print('Could not import models inside insert_chat_history:', e)
                print('DB not configured - skipping insert_chat_history')
                return
        else:
            # resolve ChatHistory if not bound at module level
            try:
                local_ChatHistory = ChatHistory
            except Exception:
                try:
                    from models import ChatHistory as local_ChatHistory
                except Exception as e:
                    print('Could not resolve ChatHistory model:', e)
                    return

        # If a user_id was provided, check that the user exists. If not, insert with NULL user_id
        user_id_to_use = None
        if user_id is not None:
            try:
                # try to import User model
                try:
                    from models import User as local_User
                except Exception:
                    local_User = None

                if local_User is not None:
                    # prefer session.get when available (SQLAlchemy 1.4+/2.0)
                    exists = None
                    try:
                        exists = local_db.session.get(local_User, user_id)
                    except Exception:
                        try:
                            exists = local_db.session.query(local_User).filter_by(user_id=user_id).first()
                        except Exception:
                            exists = None

                    if exists:
                        user_id_to_use = user_id
                    else:
                        print(f'user_id {user_id} not found in users table; inserting with null user_id')
                        user_id_to_use = None
                else:
                    # if we cannot resolve User model, play safe and insert NULL to avoid FK errors
                    print('User model not available; inserting with null user_id')
                    user_id_to_use = None
            except Exception as e:
                print('Error while checking user existence:', e)
                user_id_to_use = None
        else:
            user_id_to_use = None

        # create record using SQLAlchemy model instances (store JSON as native types)
        record = local_ChatHistory(
            user_id=user_id_to_use,
            query_text=query_text,
            ai_acc_result=ai_acc_result,
            gemini_result=gemini_result,
            created_at=datetime.utcnow()
        )
        # debug: print engine URL and bound session info
        try:
            print('SQLALCHEMY_ENGINE_URL =', getattr(local_db, 'engine', None) and str(local_db.engine.url))
            try:
                bind = local_db.session.get_bind()
                print('session bind =', bind)
            except Exception as e:
                print('could not get session bind:', e)
        except Exception:
            pass

        local_db.session.add(record)
        local_db.session.commit()
        print('insert_chat_history: committed record id=', getattr(record, 'id', None))
    except Exception as e:
        print(f"Could not insert chat history: {e}")
        import traceback
        print(traceback.format_exc())


def get_chat_history(limit=50, user_id=None):
    try:
        # dynamically resolve db and ChatHistory to avoid import-order issues
        local_db = db
        local_ChatHistory = None
        if local_db is None:
            try:
                from models import db as local_db, ChatHistory as local_ChatHistory
            except Exception:
                return []
        else:
            try:
                local_ChatHistory = ChatHistory
            except Exception:
                try:
                    from models import ChatHistory as local_ChatHistory
                except Exception:
                    return []

        q = local_ChatHistory.query
        # accept user_id as int or string; convert if possible
        if user_id is not None:
            try:
                uid = int(user_id)
                q = q.filter_by(user_id=uid)
            except Exception:
                pass
        records = q.order_by(local_ChatHistory.created_at.desc()).limit(limit).all()
        rows = []
        for r in records:
            rows.append({
                "user_id": r.user_id,
                "query": r.query_text,
                "gemini_result": r.gemini_result,
                "created_at": r.created_at.isoformat() if r.created_at else None
            })
        return rows
    except Exception as e:
        logging.warning(f"get_chat_history failed: {e}")
        return []


def cleanup_old_chat_history(days=30):
    try:
        if db is None:
            return
        cutoff = datetime.utcnow() - timedelta(days=days)
        ChatHistory.query.filter(ChatHistory.created_at < cutoff).delete()
        db.session.commit()
    except Exception as e:
        logging.warning(f"cleanup_old_chat_history failed: {e}")
