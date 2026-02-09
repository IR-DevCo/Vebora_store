from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import Plan, User, Subscription
from pydantic import BaseModel
from datetime import datetime, timedelta

router = APIRouter(prefix="/users", tags=["users"])

# ===============================
# Pydantic Schemas
# ===============================
class PlanOut(BaseModel):
    id: int
    name: str
    days: int
    price: str
    active: bool

    class Config:
        orm_mode = True

class SubscriptionOut(BaseModel):
    plan_name: str
    start_date: datetime
    end_date: datetime
    active: bool

# ===============================
# Endpoints
# ===============================

# Get all active plans for users
@router.get("/plans", response_model=List[PlanOut])
def get_active_plans(db: Session = Depends(get_db)):
    plans = db.query(Plan).filter(Plan.active == True).all()
    return plans

# Subscribe user to a plan
class SubscribeRequest(BaseModel):
    user_id: int
    plan_id: int

@router.post("/subscribe", response_model=SubscriptionOut)
def subscribe_user(req: SubscribeRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == req.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    plan = db.query(Plan).filter(Plan.id == req.plan_id, Plan.active == True).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found or inactive")

    # محاسبه تاریخ پایان اشتراک
    start_date = datetime.utcnow()
    end_date = start_date + timedelta(days=plan.days)

    subscription = Subscription(
        user_id=user.id,
        plan_id=plan.id,
        start_date=start_date,
        end_date=end_date,
        active=True
    )

    db.add(subscription)
    db.commit()
    db.refresh(subscription)

    return SubscriptionOut(
        plan_name=plan.name,
        start_date=subscription.start_date,
        end_date=subscription.end_date,
        active=subscription.active
    )

# Get user subscriptions
@router.get("/subscriptions/{user_id}", response_model=List[SubscriptionOut])
def get_user_subscriptions(user_id: int, db: Session = Depends(get_db)):
    subscriptions = (
        db.query(Subscription)
        .join(Plan)
        .filter(Subscription.user_id == user_id)
        .all()
    )
    result = []
    for sub in subscriptions:
        result.append(
            SubscriptionOut(
                plan_name=sub.plan.name,
                start_date=sub.start_date,
                end_date=sub.end_date,
                active=sub.active
            )
        )
    return result
