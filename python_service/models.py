from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

db = SQLAlchemy()

# ============================================================
# 👤 使用者模型（users）
# ============================================================
class User(db.Model):
    __tablename__ = 'users'

    user_id = db.Column(db.Integer, primary_key=True)
    account = db.Column(db.String(64), unique=True, nullable=False)
    username = db.Column(db.String(64), nullable=False)
    password = db.Column(db.String(255), nullable=False)
    email = db.Column(db.String(128), unique=True, nullable=False)
    phone = db.Column(db.String(32))

    # 使用者通知設定
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
    # 回傳給前端用
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


# ============================================================
# 📰 文章模型（articles）
# ============================================================
class Article(db.Model):
    __tablename__ = 'articles'

    article_id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    content = db.Column(db.Text)
    category = db.Column(db.String(100))
    media_name = db.Column(db.String(255))
    published_time = db.Column(db.DateTime, default=datetime.utcnow)
    reliability_score = db.Column(db.Float, default=0.0)
    source_link = db.Column(db.String(500))

    # 關聯留言
    comments = db.relationship('Comment', backref='article', lazy=True)

    @property
    def credibility_label(self):
        labels = {
            0: "不可信",
            1: "極低可信度",
            2: "低可信度",
            3: "中可信度",
            4: "高可信度",
            5: "極高可信度"
        }
        score = round(self.reliability_score or 0)
        return labels.get(score, "未知")

    def to_dict(self):
        return {
            "id": self.article_id,
            "title": self.title,
            "content": self.content,
            "category": self.category,
            "media_name": self.media_name,
            "published_time": self.published_time.strftime("%Y-%m-%d %H:%M")
            if self.published_time else None,
            "reliability_score": self.reliability_score,
            "credibility_label": self.credibility_label,
            "source_link": self.source_link,
        }


# ============================================================
# 💬 留言模型（comments）
# ============================================================
class Comment(db.Model):
    __tablename__ = 'comments'

    comment_id = db.Column(db.Integer, primary_key=True)
    article_id = db.Column(db.Integer, db.ForeignKey('articles.article_id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id'), nullable=True)

    content = db.Column(db.Text, nullable=False)
    user_identity = db.Column(db.String(100), default="匿名用戶")
    commented_at = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship('User', backref=db.backref('comments', lazy=True))

    def to_dict(self):
        return {
            "comment_id": self.comment_id,
            "article_id": self.article_id,
            "user_id": self.user_id,
            "author": self.user_identity,
            "content": self.content,
            "time": self.commented_at.strftime("%Y-%m-%d %H:%M")
            if self.commented_at else None,
        }


# ============================================================
# 🚨 舉報模型（reports）
# ============================================================
class Reports(db.Model):
    __tablename__ = "reports"

    report_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.user_id"), nullable=False)
    article_id = db.Column(db.Integer, db.ForeignKey("articles.article_id"), nullable=False)
    reason = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(20), default="待審核")
    reported_at = db.Column(db.DateTime, default=datetime.utcnow)


# ============================================================
# 🧠 聊天紀錄（chat_history）
# ============================================================
class ChatHistory(db.Model):
    __tablename__ = "chat_history"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.user_id"), nullable=True)

    query_text = db.Column(db.Text, nullable=False)
    ai_acc_result = db.Column(db.JSON, nullable=True)
    gemini_result = db.Column(db.JSON, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "query": self.query_text,
            "ai_acc_result": self.ai_acc_result,
            "gemini_result": self.gemini_result,
            "created_at": self.created_at.isoformat()
        }
