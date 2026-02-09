from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import Order, User
from typing import List
from pydantic import BaseModel
from config import ADMIN_CHAT_ID

router = APIRouter()

# ===== Admin Authentication Dependency =====
def verify_admin(chat_id: int = ADMIN_CHAT_ID):
    if chat_id != ADMIN_CHAT_ID:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    return True

# ===== Pydantic Schemas =====
class OrderCreate(BaseModel):
    user_telegram_id: str
    plan_name: str
    amount: int

class OrderUpdate(BaseModel):
    status: str  # pending, completed, canceled

# ===== Create Order =====
@router.post("/", tags=["Orders"])
def create_order(order: OrderCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.telegram_id == order.user_telegram_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    new_order = Order(
        user_id=user.id,
        plan_name=order.plan_name,
        amount=order.amount,
        status="pending"
    )
    db.add(new_order)
    db.commit()
    db.refresh(new_order)
    return {"status": "success", "order": {
        "id": new_order.id,
        "user_id": new_order.user_id,
        "plan_name": new_order.plan_name,
        "amount": new_order.amount,
        "status": new_order.status
    }}

# ===== Get All Orders =====
@router.get("/", tags=["Orders"])
def get_all_orders(db: Session = Depends(get_db), auth: bool = Depends(verify_admin)):
    orders = db.query(Order).all()
    return [
        {
            "id": o.id,
            "user_id": o.user_id,
            "plan_name": o.plan_name,
            "amount": o.amount,
            "status": o.status,
            "created_at": o.created_at
        }
        for o in orders
    ]

# ===== Update Order Status =====
@router.put("/{order_id}", tags=["Orders"])
def update_order(order_id: int, update: OrderUpdate, db: Session = Depends(get_db), auth: bool = Depends(verify_admin)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    order.status = update.status
    db.commit()
    db.refresh(order)
    return {"status": "success", "order": {
        "id": order.id,
        "user_id": order.user_id,
        "plan_name": order.plan_name,
        "amount": order.amount,
        "status": order.status
    }}
