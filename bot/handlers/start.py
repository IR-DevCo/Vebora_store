from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import CallbackContext
from auth import is_admin, check_membership
from broadcast import broadcast_to_users, broadcast_to_channel
from admin import provision_user_command, list_users
from database import get_db
from sqlalchemy.orm import Session

# ===== Start Command =====
def start(update: Update, context: CallbackContext):
    user_id = update.effective_user.id
    db: Session = next(get_db())

    # Check membership
    if not check_membership(update, context, user_id):
        return

    # Admin menu
    if is_admin(user_id):
        keyboard = InlineKeyboardMarkup([
            [InlineKeyboardButton("📩 ارسال پیام به کاربر", callback_data="admin_send_user")],
            [InlineKeyboardButton("📢 ارسال پیام به کانال", callback_data="admin_broadcast")],
            [InlineKeyboardButton("👥 لیست کاربران", callback_data="admin_list_users")],
            [InlineKeyboardButton("➕ پروویژن کاربر جدید", callback_data="admin_provision")]
        ])
        update.message.reply_text("👑 منوی ادمین Vebora Store:", reply_markup=keyboard)
        return

    # User menu
    keyboard = InlineKeyboardMarkup([
        [InlineKeyboardButton("📦 خرید اشتراک", callback_data="user_buy_plan")],
        [InlineKeyboardButton("📊 مشاهده مصرف", callback_data="user_usage")],
        [InlineKeyboardButton("📝 پشتیبانی", callback_data="user_support")]
    ])
    update.message.reply_text("🌟 منوی کاربر Vebora Store:", reply_markup=keyboard)
