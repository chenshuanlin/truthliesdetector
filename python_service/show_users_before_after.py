from app import create_app
from models import db
from sqlalchemy import text

app = create_app()
with app.app_context():
    res = db.session.execute(text('SELECT user_id, account, username FROM users ORDER BY user_id')).fetchall()
    print('users:')
    for r in res:
        print(r)
