# schemas.py
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

class CommentSchema(BaseModel):
    comment_id: int
    user_id: int
    content: str
    commented_at: datetime
    user_identity: str

    class Config:
        orm_mode = True

class FavoriteSchema(BaseModel):
    favorite_id: int
    user_id: int
    article_id: int
    favorited_at: datetime

    class Config:
        from_attributes = True

class AnalysisResultSchema(BaseModel):
    analysis_id: int
    article_id: int
    user_id: int
    explanation: str
    analyzed_at: datetime
    keywords: str
    category: str
    confidence_score: float
    risk_level: str
    report_id: Optional[int]

    class Config:
        orm_mode = True

class ReportSchema(BaseModel):
    report_id: int
    user_id: int
    article_id: int
    reason: str
    status: str
    reported_at: datetime

    class Config:
        orm_mode = True

class RelatedNewsSchema(BaseModel):
    related_id: int
    source_article_id: int
    related_article_id: int
    similarity_score: float
    related_title: str
    related_link: str

    class Config:
        orm_mode = True

class ArticleSchema(BaseModel):
    article_id: int
    title: str
    content: str
    category: str
    source_link: str
    media_name: str
    created_time: datetime
    published_time: datetime
    reliability_score: float
    comments: List[CommentSchema] = []
    favorites: List[FavoriteSchema] = []
    analysis_results: List[AnalysisResultSchema] = []
    reports: List[ReportSchema] = []
    related_news_sources: List[RelatedNewsSchema] = []
    related_news_targets: List[RelatedNewsSchema] = []

    class Config:
        orm_mode = True

class UserSchema(BaseModel):
    account: str
    username: str
    password: str
    email: str
    phone: str
    user_id: Optional[int] = None

    class Config:
        orm_mode = True

class UserLogin(BaseModel):
    account: str
    password: str
