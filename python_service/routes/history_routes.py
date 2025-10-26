from flask import Blueprint, request, jsonify
from core.database import get_chat_history

bp = Blueprint('history', __name__)

@bp.route('/history', methods=['GET'])
def history():
    limit = int(request.args.get('limit', 50))
    records = get_chat_history(limit=limit)
    return jsonify({'ok': True, 'count': len(records), 'records': records})
