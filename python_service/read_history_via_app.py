from app import create_app
from models import db, ChatHistory

app = create_app()
with app.app_context():
    rows = ChatHistory.query.order_by(ChatHistory.created_at.desc()).limit(20).all()
    print('rows via app:', len(rows))
    for r in rows:
        print(r.to_dict())
