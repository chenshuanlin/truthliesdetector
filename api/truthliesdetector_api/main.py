from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime

from database import SessionLocal, engine, Base, get_db
import models, schemas
from favorites import router as favorites_router      # 收藏路由
from search_logs import router as search_logs_router  # 瀏覽紀錄路由

# --------------------------------------------------------
# 建立資料表
# --------------------------------------------------------
Base.metadata.create_all(bind=engine)

app = FastAPI(title="TruthliesDetector API")

# --------------------------------------------------------
# 允許跨來源 (CORS)
# --------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 上線可改為 ["http://你的前端網址"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --------------------------------------------------------
# 掛載路由
# --------------------------------------------------------
app.include_router(favorites_router)      # 收藏相關 API
app.include_router(search_logs_router)    # 瀏覽紀錄 API

# --------------------------------------------------------
# Users
# --------------------------------------------------------
@app.post("/register", response_model=schemas.UserSchema)
def register_user(user: schemas.UserSchema, db: Session = Depends(get_db)):
    """使用者註冊"""
    db_user = models.User(
        account=user.account,
        username=user.username,
        password=user.password,
        email=user.email,
        phone=user.phone
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


@app.get("/users", response_model=list[schemas.UserSchema])
def get_users(db: Session = Depends(get_db)):
    """取得所有使用者"""
    return db.query(models.User).all()


@app.post("/login")
def login_user(user: schemas.UserLogin, db: Session = Depends(get_db)):
    """使用者登入驗證"""
    db_user = db.query(models.User).filter(
        models.User.account == user.account,
        models.User.password == user.password
    ).first()
    if not db_user:
        raise HTTPException(status_code=401, detail="帳號或密碼錯誤")
    return {
        "message": "登入成功",
        "user_id": db_user.user_id,
        "username": db_user.username
    }

# --------------------------------------------------------
# Articles
# --------------------------------------------------------
@app.get("/articles", response_model=list[schemas.ArticleSchema])
def get_articles(db: Session = Depends(get_db)):
    """取得所有文章，並附帶評論、收藏、分析、回報、相關新聞"""
    articles = db.query(models.Article).all()
    for article in articles:
        article.comments = db.query(models.Comment).filter(
            models.Comment.article_id == article.article_id).all()
        article.favorites = db.query(models.Favorite).filter(
            models.Favorite.article_id == article.article_id).all()
        article.analysis_results = db.query(models.AnalysisResult).filter(
            models.AnalysisResult.article_id == article.article_id).all()
        article.reports = db.query(models.Report).filter(
            models.Report.article_id == article.article_id).all()
        article.related_news_sources = db.query(models.RelatedNews).filter(
            models.RelatedNews.source_article_id == article.article_id).all()
        article.related_news_targets = db.query(models.RelatedNews).filter(
            models.RelatedNews.related_article_id == article.article_id).all()
    return articles


@app.get("/articles/{article_id}", response_model=schemas.ArticleSchema)
def get_article(article_id: int, db: Session = Depends(get_db)):
    """取得單一文章詳情"""
    article = db.query(models.Article).filter(
        models.Article.article_id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")

    article.comments = db.query(models.Comment).filter(
        models.Comment.article_id == article.article_id).all()
    article.favorites = db.query(models.Favorite).filter(
        models.Favorite.article_id == article.article_id).all()
    article.analysis_results = db.query(models.AnalysisResult).filter(
        models.AnalysisResult.article_id == article.article_id).all()
    article.reports = db.query(models.Report).filter(
        models.Report.article_id == article.article_id).all()
    article.related_news_sources = db.query(models.RelatedNews).filter(
        models.RelatedNews.source_article_id == article.article_id).all()
    article.related_news_targets = db.query(models.RelatedNews).filter(
        models.RelatedNews.related_article_id == article.article_id).all()
    return article
