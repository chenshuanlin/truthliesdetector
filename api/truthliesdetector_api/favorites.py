from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from database import get_db
import models

router = APIRouter(prefix="/favorites", tags=["favorites"])

class FavoriteRequest(BaseModel):
    user_id: int
    article_id: int

@router.post("/")
def add_favorite(fav: FavoriteRequest, db: Session = Depends(get_db)):
    exists = db.query(models.Favorite).filter(
        models.Favorite.user_id == fav.user_id,
        models.Favorite.article_id == fav.article_id
    ).first()
    if exists:
        raise HTTPException(status_code=400, detail="已收藏過")

    new_fav = models.Favorite(
        user_id=fav.user_id,
        article_id=fav.article_id,
        favorited_at=datetime.utcnow()
    )
    db.add(new_fav)
    db.commit()
    db.refresh(new_fav)
    return {"favorite_id": new_fav.favorite_id}

@router.get("/user/{user_id}")
def get_user_favorites(user_id: int, db: Session = Depends(get_db)):
    return db.query(models.Favorite).filter(
        models.Favorite.user_id == user_id
    ).all()
