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
        }
