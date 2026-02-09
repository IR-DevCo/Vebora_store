from ..models import Plan, User, Subscription
from ..database import get_db
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import requests
import os

# ===============================
# X-UI API Configuration
# ===============================
XUI_HOST = os.getenv("XUI_HOST", "http://127.0.0.1:54321")
XUI_KEY = os.getenv("XUI_KEY", "YOUR_XUI_KEY_HERE")  # باید در .env تعریف بشه

def create_vpn_user(user_id: int, plan_id: int, db: Session):
    """
    Create a VPN account for a user based on selected plan
    """
    # دریافت اطلاعات کاربر و پلن
    user = db.query(User).filter(User.id == user_id).first()
    plan = db.query(Plan).filter(Plan.id == plan_id, Plan.active == True).first()

    if not user:
        raise Exception("User not found")
    if not plan:
        raise Exception("Plan not found or inactive")

    # تاریخ پایان اشتراک
    end_date = datetime.utcnow() + timedelta(days=plan.days)

    # ساخت اشتراک در دیتابیس
    subscription = Subscription(
        user_id=user.id,
        plan_id=plan.id,
        start_date=datetime.utcnow(),
        end_date=end_date,
        active=True
    )
    db.add(subscription)
    db.commit()
    db.refresh(subscription)

    # ===== ایجاد حساب در X-UI =====
    # نمونه payload برای x-ui
    payload = {
        "add": [
            {
                "email": f"{user.username}@vebora.store",
                "remark": f"{user.username}-{plan.name}",
                "enable": True,
                "expire": int(end_date.timestamp())
            }
        ]
    }

    headers = {"Authorization": f"Bearer {XUI_KEY}"}
    try:
        response = requests.post(f"{XUI_HOST}/api/v1/user/add", json=payload, headers=headers)
        response.raise_for_status()
        return {"subscription_id": subscription.id, "vpn_response": response.json()}
    except requests.RequestException as e:
        # اگر ایجاد VPN شکست خورد، اشتراک را deactivate کن
        subscription.active = False
        db.commit()
        raise Exception(f"Failed to create VPN user: {e}")

# ===============================
# Delete VPN user
# ===============================
def delete_vpn_user(user_id: int, db: Session):
    """
    Delete VPN account for a user
    """
    subscription = db.query(Subscription).filter(Subscription.user_id == user_id, Subscription.active == True).first()
    if not subscription:
        return {"detail": "No active subscription found"}

    # نمونه payload برای حذف از x-ui
    payload = {"id": subscription.id}  # توجه: باید با API x-ui هماهنگ بشه
    headers = {"Authorization": f"Bearer {XUI_KEY}"}
    try:
        response = requests.post(f"{XUI_HOST}/api/v1/user/delete", json=payload, headers=headers)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"⚠️ Failed to delete VPN user: {e}")

    # deactivate subscription
    subscription.active = False
    db.commit()
    return {"detail": "VPN user deleted"}
