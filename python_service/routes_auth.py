from flask import Blueprint, request, jsonify
from models import db, User

bp = Blueprint('auth', __name__)

# ============================================================
# 1. 註冊
# ============================================================
@bp.route('/register', methods=['POST'])
def register():
    data = request.get_json() or {}

    account = data.get('account')
    username = data.get('username')
    password = data.get('password')
    email = data.get('email')
    phone = data.get('phone')

    if not all([account, username, password, email]):
        return jsonify({'error': '缺少必要欄位'}), 400

    if User.query.filter_by(account=account).first():
        return jsonify({'error': '帳號已存在'}), 409

    if User.query.filter_by(email=email).first():
        return jsonify({'error': '電子郵件已被使用'}), 409

    user = User(
        account=account,
        username=username,
        email=email,
        phone=phone
    )
    user.set_password(password)

    db.session.add(user)
    db.session.commit()

    return jsonify({'ok': True, 'user_id': user.user_id}), 201


# ============================================================
# 2. 登入
# ============================================================
@bp.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    account = data.get('account')
    password = data.get('password')

    if not all([account, password]):
        return jsonify({'error': '缺少必要欄位'}), 400

    user = User.query.filter_by(account=account).first()

    if not user or not user.check_password(password):
        return jsonify({'error': '帳號或密碼錯誤'}), 401

    return jsonify({'ok': True, 'user': user.to_dict()})


# ============================================================
# 3. 取得用戶資訊
# ============================================================
@bp.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': '找不到用戶'}), 404

    return jsonify({'ok': True, 'user': user.to_dict()})


# ============================================================
# 4. 更新用戶資料（支援修改密碼）
# ============================================================
@bp.route('/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': '找不到用戶'}), 404

    data = request.get_json() or {}

    # 基本欄位
    user.username = data.get('username', user.username)
    user.email = data.get('email', user.email)
    user.phone = data.get('phone', user.phone)

    # ⭐ 支援改密碼
    if "password" in data and data["password"]:
        user.set_password(data["password"])

    db.session.commit()

    return jsonify({'ok': True, 'user': user.to_dict()})
