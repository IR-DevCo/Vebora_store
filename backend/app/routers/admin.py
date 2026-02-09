from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import Plan
from pydantic import BaseModel

router = APIRouter(prefix="/admin", tags=["admin"])

# ===============================
# Pydantic Schemas
# ===============================
class PlanCreate(BaseModel):
    name: str
    days: int
    price: str
    active: bool = True

class PlanUpdate(BaseModel):
    name: str | None = None
    days: int | None = None
    price: str | None = None
    active: bool | None = None

class PlanOut(BaseModel):
    id: int
    name: str
    days: int
    price: str
    active: bool

    class Config:
        orm_mode = True

# ===============================
# Admin Endpoints
# ===============================

# Create a new plan
@router.post("/plans", response_model=PlanOut)
def create_plan(plan: PlanCreate, db: Session = Depends(get_db)):
    new_plan = Plan(**plan.dict())
    db.add(new_plan)
    db.commit()
    db.refresh(new_plan)
    return new_plan

# Get all plans
@router.get("/plans", response_model=List[PlanOut])
def get_plans(db: Session = Depends(get_db)):
    plans = db.query(Plan).all()
    return plans

# Update a plan
@router.put("/plans/{plan_id}", response_model=PlanOut)
def update_plan(plan_id: int, plan: PlanUpdate, db: Session = Depends(get_db)):
    existing_plan = db.query(Plan).filter(Plan.id == plan_id).first()
    if not existing_plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    for key, value in plan.dict(exclude_unset=True).items():
        setattr(existing_plan, key, value)
    db.commit()
    db.refresh(existing_plan)
    return existing_plan

# Delete a plan
@router.delete("/plans/{plan_id}")
def delete_plan(plan_id: int, db: Session = Depends(get_db)):
    existing_plan = db.query(Plan).filter(Plan.id == plan_id).first()
    if not existing_plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    db.delete(existing_plan)
    db.commit()
    return {"detail": "Plan deleted successfully"}
