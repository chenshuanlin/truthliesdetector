from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()

class User(db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.Integer, primary_key=True)
    account = db.Column(db.String(64), unique=True, nullable=False)
    username = db.Column(db.String(64), nullable=False)
    password = db.Column(db.String(255), nullable=False)  # 增加長度以容納密碼 hash
    email = db.Column(db.String(128), unique=True, nullable=False)
    phone = db.Column(db.String(32))

    # ✅ 新增的設定欄位（布林值）
    news_category_subscription = db.Column(db.Boolean, default=False)
    expert_analysis_subscription = db.Column(db.Boolean, default=False)
    weekly_report_subscription = db.Column(db.Boolean, default=False)
    fake_news_alert = db.Column(db.Boolean, default=False)
    trending_topic_alert = db.Column(db.Boolean, default=False)
    expert_response_alert = db.Column(db.Boolean, default=False)
    privacy_policy_agreed = db.Column(db.Boolean, default=False)

    # -------------------------------------------------------------
    # 密碼處理
    # -------------------------------------------------------------
    def set_password(self, password):
        self.password = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password, password)

    # -------------------------------------------------------------
    # 將物件轉成字典 (回傳前端用)
    # -------------------------------------------------------------
    def to_dict(self):
        return {
            'user_id': self.user_id,
            'account': self.account,
            'username': self.username,
            'email': self.email,
            'phone': self.phone,
            'news_category_subscription': self.news_category_subscription,
            'expert_analysis_subscription': self.expert_analysis_subscription,
            'weekly_report_subscription': self.weekly_report_subscription,
            'fake_news_alert': self.fake_news_alert,
            'trending_topic_alert': self.trending_topic_alert,
            'expert_response_alert': self.expert_response_alert,
            'privacy_policy_agreed': self.privacy_policy_agreed,
        }
