from flask import Blueprint, request, jsonify
from models import db, User

bp = Blueprint('settings', __name__)


# 取得使用者設定
@bp.route('/settings/<int:user_id>', methods=['GET'])
def get_settings(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    return jsonify({
        'news_category_subscription': bool(user.news_category_subscription),
        'expert_analysis_subscription': bool(user.expert_analysis_subscription),
        'weekly_report_subscription': bool(user.weekly_report_subscription),
        'fake_news_alert': bool(user.fake_news_alert),
        'trending_topic_alert': bool(user.trending_topic_alert),
        'expert_response_alert': bool(user.expert_response_alert),
        'privacy_policy_agreed': bool(user.privacy_policy_agreed),
    })


# 更新使用者設定
@bp.route('/settings/<int:user_id>', methods=['PUT'])
def update_settings(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json() or {}
    for key, value in data.items():
        if hasattr(user, key):
            try:
                setattr(user, key, bool(value))
            except Exception:
                # ignore invalid conversions
                pass

    db.session.commit()
    return jsonify({'success': True})
