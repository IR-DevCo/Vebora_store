from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import Subscription, User
from typing import List
from pydantic import BaseModel
from datetime import datetime
from config import ADMIN_CHAT_ID

router = APIRouter()

# ===== Admin Authentication Dependency =====
def verify_admin(chat_id: int = ADMIN_CHAT_ID):
    if chat_id != ADMIN_CHAT_ID:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    return True

# ===== Pydantic Schemas =====
class SubscriptionCreate(BaseModel):
    user_telegram_id: str
    plan_name: str
    end_date: datetime

class SubscriptionUpdate(BaseModel):
    active: bool
    end_date: datetime

# ===== Create Subscription =====
@router.post("/", tags=["Subscriptions"])
def create_subscription(sub: SubscriptionCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.telegram_id == sub.user_telegram_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    new_sub = Subscription(
        user_id=user.id,
        plan_name=sub.plan_name,
        start_date=datetime.utcnow(),
        end_date=sub.end_date,
        active=True
    )
    db.add(new_sub)
    db.commit()
    db.refresh(new_sub)
    return {"status": "success", "subscription": {
        "id": new_sub.id,
        "user_id": new_sub.user_id,
        "plan_name": new_sub.plan_name,
        "start_date": new_sub.start_date,
        "end_date": new_sub.end_date,
        "active": new_sub.active
    }}

# ===== Get All Subscriptions (Admin only) =====
@router.get("/", tags=["Subscriptions"])
def get_all_subscriptions(db: Session = Depends(get_db), auth: bool = Depends(verify_admin)):
    subs = db.query(Subscription).all()
    return [
        {
            "id": s.id,
            "user_id": s.user_id,
            "plan_name": s.plan_name,
            "start_date": s.start_date,
            "end_date": s.end_date,
            "active": s.active
        }
        for s in subs
    ]

# ===== Update Subscription =====
@router.put("/{subscription_id}", tags=["Subscriptions"])
def update_subscription(subscription_id: int, update: SubscriptionUpdate, db: Session = Depends(get_db), auth: bool = Depends(verify_admin)):
    sub = db.query(Subscription).filter(Subscription.id == subscription_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")
    sub.active = update.active
    sub.end_date = update.end_date
    db.commit()
    db.refresh(sub)
    return {"status": "success", "subscription": {
        "id": sub.id,
        "user_id": sub.user_id,
        "plan_name": sub.plan_name,
        "start_date": sub.start_date,
        "end_date": sub.end_date,
        "active": sub.active
    }}

# ===== Get Subscriptions for a User =====
@router.get("/user/{telegram_id}", tags=["Subscriptions"])
def get_user_subscriptions(telegram_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.telegram_id == telegram_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    subs = db.query(Subscription).filter(Subscription.user_id == user.id).all()
    return [
        {
            "id": s.id,
            "plan_name": s.plan_name,
            "start_date": s.start_date,
            "end_date": s.end_date,
            "active": s.active
        }
        for s in subs
    ]
