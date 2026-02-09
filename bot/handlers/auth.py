from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import CallbackContext
from database import get_db
from models import User
from config import ADMIN_CHAT_ID, FORCE_CHANNEL, TELEGRAM_BOT_TOKEN
import requests
from sqlalchemy.orm import Session

# ===== Check Admin =====
def is_admin(user_id: int) -> bool:
    return user_id == ADMIN_CHAT_ID

# ===== Check Channel Membership =====
def check_membership(update: Update, context: CallbackContext, telegram_id: int) -> bool:
    """
    Verify if the user is member of FORCE_CHANNEL
    """
    db: Session = next(get_db())
    user = db.query(User).filter(User.telegram_id == telegram_id).first()
    if not user:
        update.message.reply_text("❌ کاربر یافت نشد!")
        return False

    # Call Telegram API to check membership
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/getChatMember"
    params = {
        "chat_id": f"@{FORCE_CHANNEL}",
        "user_id": telegram_id
    }
    try:
        resp = requests.get(url, params=params).json()
        if resp.get("ok"):
            status_ = resp["result"]["status"]
            if status_ in ["member", "administrator", "creator"]:
                # Update DB if not verified
                if not user.is_verified:
                    user.is_verified = True
                    db.commit()
                return True
            else:
                # Send Join Channel button
                keyboard = InlineKeyboardMarkup(
                    [[InlineKeyboardButton("✅ عضو کانال شو", url=f"https://t.me/{FORCE_CHANNEL}")]]
                )
                update.message.reply_text(
                    "❌ شما عضو کانال ما نیستید! لطفاً عضو شوید و سپس روی دکمه زیر بزنید.",
                    reply_markup=keyboard
                )
                return False
        else:
            update.message.reply_text("❌ خطا در بررسی عضویت کانال. لطفاً دوباره تلاش کنید.")
            return False
    except Exception as e:
        update.message.reply_text(f"❌ خطا: {e}")
        return False
