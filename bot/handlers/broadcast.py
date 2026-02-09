from telegram import Update
from telegram.ext import CallbackContext
from database import get_db
from models import User
from sqlalchemy.orm import Session
from config import ADMIN_CHAT_ID, FORCE_CHANNEL
import time

# ===== Check if user is admin =====
def is_admin(user_id: int) -> bool:
    return user_id == ADMIN_CHAT_ID

# ===== Broadcast message to all users =====
def broadcast_to_users(update: Update, context: CallbackContext):
    if not is_admin(update.effective_user.id):
        update.message.reply_text("❌ شما دسترسی ادمین ندارید!")
        return

    db: Session = next(get_db())
    users = db.query(User).filter(User.is_verified == True).all()
    if not users:
        update.message.reply_text("❌ هیچ کاربر فعالی یافت نشد!")
        return

    text = " ".join(context.args)
    success_count = 0
    fail_count = 0

    for user in users:
        try:
            context.bot.send_message(chat_id=int(user.telegram_id), text=f"📢 پیام همگانی:\n\n{text}")
            success_count += 1
            time.sleep(0.1)  # جلوگیری از Flood
        except:
            fail_count += 1
            continue

    update.message.reply_text(f"✅ ارسال پیام تمام شد!\n✅ موفق: {success_count}\n❌ ناموفق: {fail_count}")

# ===== Broadcast message to channel =====
def broadcast_to_channel(update: Update, context: CallbackContext):
    if not is_admin(update.effective_user.id):
        update.message.reply_text("❌ شما دسترسی ادمین ندارید!")
        return

    text = " ".join(context.args)
    try:
        context.bot.send_message(chat_id=f"@{FORCE_CHANNEL}", text=f"📢 پیام کانال:\n\n{text}")
        update.message.reply_text("✅ پیام به کانال ارسال شد!")
    except Exception as e:
        update.message.reply_text(f"❌ خطا در ارسال پیام به کانال: {e}")
