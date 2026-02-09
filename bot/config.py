import os
from dotenv import load_dotenv

# Load .env file
load_dotenv()

# ===== Bot Token =====
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")

# ===== Admin =====
ADMIN_CHAT_ID = int(os.getenv("ADMIN_CHAT_ID", "0"))  # جایگزین با ID ادمین

# ===== Force Channel for subscription =====
FORCE_CHANNEL = os.getenv("FORCE_CHANNEL", "YourChannelUsername")

# ===== Backend / 3x-ui =====
BACKEND_URL = os.getenv("BACKEND_URL", "http://127.0.0.1:8000")  # FastAPI backend URL
XUI_API_URL = os.getenv("XUI_API_URL", "http://127.0.0.1:54321")  # در صورت نیاز
XUI_API_KEY = os.getenv("XUI_API_KEY", "")

# ===== Security / JWT =====
SECRET_KEY = os.getenv("SECRET_KEY", "YOUR_RANDOM_SECRET_KEY")

# ===== Other =====
TIMEZONE = os.getenv("TIMEZONE", "UTC")
