from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import CallbackContext, CommandHandler, CallbackQueryHandler
import requests
import os

API_BASE = os.getenv("API_BASE", "http://127.0.0.1:8000")  # Backend URL

# ===============================
# Command: /plans
# ===============================
def user_plans(update: Update, context: CallbackContext):
    user_id = update.effective_user.id

    # دریافت پلن‌ها از Backend
    try:
        resp = requests.get(f"{API_BASE}/users/plans")
        resp.raise_for_status()
        plans = resp.json()
    except requests.RequestException as e:
        update.message.reply_text(f"⚠️ Failed to fetch plans: {e}")
        return

    if not plans:
        update.message.reply_text("❌ No active plans available!")
        return

    keyboard = []
    for plan in plans:
        keyboard.append([InlineKeyboardButton(f"{plan['name']} - {plan['price']}", callback_data=f"buy_{plan['id']}")])

    update.message.reply_text(
        "📦 Available Plans:\nSelect a plan to subscribe:",
        reply_markup=InlineKeyboardMarkup(keyboard)
    )

# ===============================
# Callback: Buy plan
# ===============================
def user_callback(update: Update, context: CallbackContext):
    query = update.callback_query
    user_id = query.from_user.id
    data = query.data

    if data.startswith("buy_"):
        plan_id = data.split("_")[1]

        # ارسال درخواست اشتراک به Backend
        payload = {"user_id": user_id, "plan_id": int(plan_id)}
        try:
            resp = requests.post(f"{API_BASE}/users/subscribe", json=payload)
            resp.raise_for_status()
            subscription = resp.json()
        except requests.RequestException as e:
            query.answer()
            query.edit_message_text(f"⚠️ Failed to subscribe: {e}")
            return

        # موفقیت آمیز
        query.answer()
        query.edit_message_text(
            f"✅ Subscription successful!\nPlan: {subscription['plan_name']}\n"
            f"Start: {subscription['start_date']}\nEnd: {subscription['end_date']}"
        )

# ===============================
# Register handlers
# ===============================
def register_user_handlers(dp):
    dp.add_handler(CommandHandler("plans", user_plans))
    dp.add_handler(CallbackQueryHandler(user_callback))
