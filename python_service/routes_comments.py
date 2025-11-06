from flask import Blueprint, request, jsonify
from models import db, Comment
from datetime import datetime

# Blueprint 名稱：comments
# 注意這裡的 prefix 改為 /articles
bp = Blueprint("comments", __name__)

# ======================
# 💬 取得留言
# ======================
@bp.route("/articles/<int:article_id>/comments", methods=["GET"])
def get_comments(article_id):
    try:
        comments = (
            Comment.query.filter_by(article_id=article_id)
            .order_by(Comment.commented_at.desc())
            .all()
        )

        return jsonify([
            {
                "author": c.user_identity or "匿名用戶",
                "content": c.content,
                "time": c.commented_at.strftime("%Y-%m-%d %H:%M") if c.commented_at else None,
            }
            for c in comments
        ]), 200

    except Exception as e:
        print("❌ 讀取留言失敗:", e)
        return jsonify({"error": str(e)}), 500


# ======================
# ✏️ 新增留言
# ======================
@bp.route("/articles/<int:article_id>/comments", methods=["POST"])
def add_comment(article_id):
    try:
        data = request.get_json()
        author = data.get("author", "匿名用戶")
        content = data.get("content", "").strip()
        user_id = data.get("user_id")

        if not content:
            return jsonify({"error": "留言內容不得為空"}), 400

        new_comment = Comment(
            article_id=article_id,
            content=content,
            user_identity=author,
            user_id=user_id,
            commented_at=datetime.now(),
        )

        db.session.add(new_comment)
        db.session.commit()

        return jsonify({"message": "留言新增成功"}), 201

    except Exception as e:
        db.session.rollback()
        print("❌ 新增留言失敗:", e)
        return jsonify({"error": str(e)}), 500
