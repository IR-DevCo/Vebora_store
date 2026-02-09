from fastapi import HTTPException, status, Depends
from sqlalchemy.orm import Session
from database import get_db
from models import User
from config import ADMIN_CHAT_ID
import requests
from config import FORCE_CHANNEL, TELEGRAM_BOT_TOKEN

# ===== Admin Verification Dependency =====
def verify_admin(chat_id: int):
    if chat_id != ADMIN_CHAT_ID:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return True

# ===== User Verification: Channel Membership =====
def verify_membership(user_telegram_id: str, db: Session = Depends(get_db)):
    """
    Check if user is member of FORCE_CHANNEL
    """
    user = db.query(User).filter(User.telegram_id == user_telegram_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Telegram API check
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/getChatMember"
    params = {
        "chat_id": f"@{FORCE_CHANNEL}",
        "user_id": user_telegram_id
    }
    response = requests.get(url, params=params).json()

    if response.get("ok"):
        status_ = response["result"]["status"]
        if status_ in ["member", "creator", "administrator"]:
            # Update database
            if not user.is_verified:
                user.is_verified = True
                db.commit()
            return True
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User is not a member of the required channel"
            )
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to verify membership via Telegram API"
        )
