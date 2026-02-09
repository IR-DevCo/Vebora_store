from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import CallbackContext, CommandHandler, CallbackQueryHandler
import requests
import os

API_BASE = os.getenv("API_BASE", "http://127.0.0.1:8000")  # Backend URL

ADMIN_IDS = [123456789]  # شناسه تلگرام ادمین، هنگام نصب VPS باید تغییر کنه

# ===============================
# Command: /plans
# ===============================
def admin_plans(update: Update, context: CallbackContext):
    user_id = update.effective_user.id
    if user_id not in ADMIN_IDS:
        update.message.reply_text("❌ You are not authorized!")
        return

    # دریافت پلن‌ها از Backend
    try:
        resp = requests.get(f"{API_BASE}/admin/plans")
        resp.raise_for_status()
        plans = resp.json()
    except requests.RequestException as e:
        update.message.reply_text(f"⚠️ Failed to fetch plans: {e}")
        return

    keyboard = []
    for plan in plans:
        keyboard.append([
            InlineKeyboardButton(f"{plan['name']} - {plan['price']}", callback_data=f"edit_{plan['id']}"),
            InlineKeyboardButton("❌", callback_data=f"delete_{plan['id']}")
        ])

    keyboard.append([InlineKeyboardButton("➕ Add New Plan", callback_data="add_plan")])
    update.message.reply_text("📊 Admin Plans:", reply_markup=InlineKeyboardMarkup(keyboard))

# ===============================
# Callback: Add/Edit/Delete Plan
# ===============================
def admin_callback(update: Update, context: CallbackContext):
    query = update.callback_query
    user_id = query.from_user.id
    if user_id not in ADMIN_IDS:
        query.answer("❌ Unauthorized")
        return

    data = query.data
    if data == "add_plan":
        query.edit_message_text("💡 Send plan as: name,days,price (e.g., Pro,30,10$)")
        context.user_data["action"] = "add_plan"
        query.answer()
    elif data.startswith("edit_"):
        plan_id = data.split("_")[1]
        query.edit_message_text(f"💡 Send new values for Plan {plan_id} as: name,days,price,active (active=True/False)")
        context.user_data["action"] = f"edit_{plan_id}"
        query.answer()
    elif data.startswith("delete_"):
        plan_id = data.split("_")[1]
        try:
            resp = requests.delete(f"{API_BASE}/admin/plans/{plan_id}")
            resp.raise_for_status()
            query.edit_message_text(f"✅ Plan {plan_id} deleted")
        except requests.RequestException as e:
            query.edit_message_text(f"⚠️ Failed to delete: {e}")
        query.answer()

# ===============================
# Message handler for adding/editing
# ===============================
def handle_admin_message(update: Update, context: CallbackContext):
    user_id = update.effective_user.id
    if user_id not in ADMIN_IDS:
        update.message.reply_text("❌ You are not authorized!")
        return

    action = context.user_data.get("action")
    if not action:
        return

    text = update.message.text.strip()
    if action == "add_plan":
        try:
            name, days, price = [x.strip() for x in text.split(",")]
            payload = {"name": name, "days": int(days), "price": price}
            resp = requests.post(f"{API_BASE}/admin/plans", json=payload)
            resp.raise_for_status()
            update.message.reply_text(f"✅ Plan '{name}' added successfully!")
        except Exception as e:
            update.message.reply_text(f"⚠️ Failed to add plan: {e}")
    elif action.startswith("edit_"):
        plan_id = action.split("_")[1]
        try:
            name, days, price, active = [x.strip() for x in text.split(",")]
            payload = {"name": name, "days": int(days), "price": price, "active": active.lower() == "true"}
            resp = requests.put(f"{API_BASE}/admin/plans/{plan_id}", json=payload)
            resp.raise_for_status()
            update.message.reply_text(f"✅ Plan {plan_id} updated successfully!")
        except Exception as e:
            update.message.reply_text(f"⚠️ Failed to edit plan: {e}")

    # پاک کردن action بعد از انجام
    context.user_data["action"] = None

# ===============================
# Register handlers
# ===============================
def register_admin_handlers(dp):
    dp.add_handler(CommandHandler("plans", admin_plans))
    dp.add_handler(CallbackQueryHandler(admin_callback))
    dp.add_handler(MessageHandler(Filters.text & ~Filters.command, handle_admin_message))
