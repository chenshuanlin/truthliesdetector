from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

db = SQLAlchemy()

class User(db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.Integer, primary_key=True)
    account = db.Column(db.String(64), unique=True, nullable=False)
    username = db.Column(db.String(64), nullable=False)
    password = db.Column(db.String(255), nullable=False)  # 增加長度以容納密碼 hash
    email = db.Column(db.String(128), unique=True, nullable=False)
    phone = db.Column(db.String(32))
    # 設定欄位（布林值），與 11144235 branch 同步
    news_category_subscription = db.Column(db.Boolean, default=False)
    expert_analysis_subscription = db.Column(db.Boolean, default=False)
    weekly_report_subscription = db.Column(db.Boolean, default=False)
    fake_news_alert = db.Column(db.Boolean, default=False)
    trending_topic_alert = db.Column(db.Boolean, default=False)
    expert_response_alert = db.Column(db.Boolean, default=False)
    privacy_policy_agreed = db.Column(db.Boolean, default=False)

    def set_password(self, password):
        self.password = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password, password)

    def to_dict(self):
        return {
            'user_id': self.user_id,
            'account': self.account,
            'username': self.username,
            'email': self.email,
            'phone': self.phone
        ,
            # include settings if present on the model
            'news_category_subscription': getattr(self, 'news_category_subscription', False),
            'expert_analysis_subscription': getattr(self, 'expert_analysis_subscription', False),
            'weekly_report_subscription': getattr(self, 'weekly_report_subscription', False),
            'fake_news_alert': getattr(self, 'fake_news_alert', False),
            'trending_topic_alert': getattr(self, 'trending_topic_alert', False),
            'expert_response_alert': getattr(self, 'expert_response_alert', False),
            'privacy_policy_agreed': getattr(self, 'privacy_policy_agreed', False),
        }


class ChatHistory(db.Model):
    __tablename__ = 'chat_history'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=True)
    query_text = db.Column(db.Text)
    ai_acc_result = db.Column(db.JSON)
    gemini_result = db.Column(db.JSON)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'query_text': self.query_text,
            'ai_acc_result': self.ai_acc_result,
            'gemini_result': self.gemini_result,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
