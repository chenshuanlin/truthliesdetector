from flask import Blueprint, request, jsonify
from models import db, Reports, User, Article
from datetime import datetime

bp = Blueprint("reports", __name__)

# ------------------------------
# POST /api/reports - 舉報文章
# ------------------------------
@bp.route("", methods=["POST"])
def create_report():
    try:
        data = request.get_json() or {}
        user_id = data.get("user_id")
        article_id = data.get("article_id")
        reason = data.get("reason")

        if not all([user_id, article_id, reason]):
            return jsonify({"ok": False, "error": "缺少必要欄位"}), 400

        # 檢查使用者和文章是否存在
        user = User.query.filter_by(user_id=user_id).first()
        article = Article.query.filter_by(article_id=article_id).first()

        if not user or not article:
            return jsonify({"ok": False, "error": "使用者或文章不存在"}), 404

        # 建立舉報資料
        report = Reports(
            user_id=user_id,
            article_id=article_id,
            reason=reason,
            status="待審核",
            reported_at=datetime.utcnow(),
        )
        db.session.add(report)
        db.session.commit()

        return jsonify({"ok": True, "message": "舉報成功"}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"ok": False, "error": str(e)}), 500