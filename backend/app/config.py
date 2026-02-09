import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv(".env")

# ===== Telegram Bot Config =====
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
ADMIN_CHAT_ID = int(os.getenv("ADMIN_CHAT_ID", "0"))
FORCE_CHANNEL = os.getenv("FORCE_CHANNEL", "")

# ===== Domains =====
BACKEND_DOMAIN = os.getenv("BACKEND_DOMAIN")
MINIAPP_DOMAIN = os.getenv("MINIAPP_DOMAIN")

# ===== 3x-ui Config =====
XUI_URL = os.getenv("XUI_URL")
XUI_USER = os.getenv("XUI_USER")
XUI_PASS = os.getenv("XUI_PASS")
XUI_INBOUND_ID = int(os.getenv("XUI_INBOUND_ID", "1"))

# ===== Database Config =====
DATABASE_URL = os.getenv("DATABASE_URL")

# ===== Optional Settings =====
MAX_CONCURRENT_USERS = int(os.getenv("MAX_CONCURRENT_USERS", "1000"))
DEBUG = os.getenv("DEBUG", "False").lower() == "true"
TIMEZONE = os.getenv("TIMEZONE", "Asia/Tehran")
