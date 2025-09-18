from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import datetime
from database import get_db
from pydantic import BaseModel
import models

router = APIRouter(prefix="/search_logs", tags=["search_logs"])

# 請求格式
class LogRequest(BaseModel):
    user_id: int
    query: str
    search_result: str   # 可以放文章 ID 或標題

# 回傳格式
class LogResponse(BaseModel):
    search_id: int
    user_id: int
    query: str
    search_result: str
    searched_at: datetime

    class Config:
        from_attributes = True  # Pydantic v2 對應 SQLAlchemy ORM

@router.post("/", response_model=LogResponse)
def add_log(log: LogRequest, db: Session = Depends(get_db)):
    """新增一筆搜尋紀錄"""
    new_log = models.SearchLog(
        user_id=log.user_id,
        query=log.query,
        search_result=log.search_result,
        searched_at=datetime.utcnow()
    )
    db.add(new_log)
    db.commit()
    db.refresh(new_log)
    return new_log

@router.get("/{user_id}", response_model=list[LogResponse])
def get_user_logs(user_id: int, db: Session = Depends(get_db)):
    """取得指定使用者的搜尋紀錄（依時間倒序）"""
    return db.query(models.SearchLog)\
             .filter(models.SearchLog.user_id == user_id)\
             .order_by(models.SearchLog.searched_at.desc())\
             .all()
