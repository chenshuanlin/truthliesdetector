# models.py
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime


class User(Base):
    __tablename__ = "users"
    user_id = Column(Integer, primary_key=True, index=True)
    account = Column(String(50), nullable=False)
    username = Column(String(50), nullable=False)
    password = Column(String(100), nullable=False)
    email = Column(String(100))
    phone = Column(String(20))

    comments = relationship("Comment", back_populates="user")
    favorites = relationship("Favorite", back_populates="user")
    analysis_results = relationship("AnalysisResult", back_populates="user")
    reports = relationship("Report", back_populates="user")
    search_logs = relationship("SearchLog", back_populates="user")


class Article(Base):
    __tablename__ = "articles"
    article_id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200))
    content = Column(String)
    category = Column(String(50))
    source_link = Column(String(200))
    media_name = Column(String(100))
    created_time = Column(DateTime)
    published_time = Column(DateTime)
    reliability_score = Column(Float)

    comments = relationship("Comment", back_populates="article")
    favorites = relationship("Favorite", back_populates="article")
    analysis_results = relationship("AnalysisResult", back_populates="article")
    reports = relationship("Report", back_populates="article")
    related_news_sources = relationship("RelatedNews", foreign_keys="[RelatedNews.source_article_id]")
    related_news_targets = relationship("RelatedNews", foreign_keys="[RelatedNews.related_article_id]")


class Comment(Base):
    __tablename__ = "comments"
    comment_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    article_id = Column(Integer, ForeignKey("articles.article_id"))
    content = Column(String)
    commented_at = Column(DateTime)
    user_identity = Column(String(50))

    user = relationship("User", back_populates="comments")
    article = relationship("Article", back_populates="comments")


class Favorite(Base):
    __tablename__ = "favorites"
    favorite_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    article_id = Column(Integer, ForeignKey("articles.article_id"))
    favorited_at = Column(DateTime)

    user = relationship("User", back_populates="favorites")
    article = relationship("Article", back_populates="favorites")


class AnalysisResult(Base):
    __tablename__ = "analysis_results"
    analysis_id = Column(Integer, primary_key=True, index=True)
    article_id = Column(Integer, ForeignKey("articles.article_id"))
    user_id = Column(Integer, ForeignKey("users.user_id"))
    explanation = Column(String)
    analyzed_at = Column(DateTime)
    keywords = Column(String)
    category = Column(String)
    confidence_score = Column(Float)
    risk_level = Column(String)
    report_id = Column(Integer, ForeignKey("reports.report_id"), nullable=True)

    user = relationship("User", back_populates="analysis_results")
    article = relationship("Article", back_populates="analysis_results")


class Report(Base):
    __tablename__ = "reports"
    report_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    article_id = Column(Integer, ForeignKey("articles.article_id"))
    reason = Column(String)
    status = Column(String)
    reported_at = Column(DateTime)

    user = relationship("User", back_populates="reports")
    article = relationship("Article", back_populates="reports")


class RelatedNews(Base):
    __tablename__ = "related_news"
    related_id = Column(Integer, primary_key=True, index=True)
    source_article_id = Column(Integer, ForeignKey("articles.article_id"))
    related_article_id = Column(Integer, ForeignKey("articles.article_id"))
    similarity_score = Column(Float)
    related_title = Column(String)
    related_link = Column(String)


# ✅ 只保留這個 SearchLog 定義
class SearchLog(Base):
    __tablename__ = "search_logs"
    search_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    query = Column(Text)
    search_result = Column(Text)
    searched_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="search_logs")
