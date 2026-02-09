import os
from telegram.ext import Updater
from handlers import admin, user, start, broadcast
from dotenv import load_dotenv

# ===============================
# Load environment variables
# ===============================
load_dotenv()
TOKEN = os.getenv("BOT_TOKEN")

if not TOKEN:
    raise Exception("❌ BOT_TOKEN not found in .env")

# ===============================
# Initialize Updater & Dispatcher
# ===============================
updater = Updater(TOKEN, use_context=True)
dp = updater.dispatcher

# ===============================
# Register Handlers
# ===============================
start.register_start_handlers(dp)
admin.register_admin_handlers(dp)
user.register_user_handlers(dp)
broadcast.register_broadcast_handlers(dp)

# ===============================
# Start Bot
# ===============================
print("🤖 Vebora Store Bot is running...")
updater.start_polling()
updater.idle()
