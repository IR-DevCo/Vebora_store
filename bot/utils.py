from telegram import InlineKeyboardButton, InlineKeyboardMarkup
from datetime import datetime, timedelta
import pytz

# ===== Format bytes to MB =====
def bytes_to_mb(byte_value: int) -> str:
    return f"{byte_value / 1024 / 1024:.2f} MB"

# ===== Generate Inline Keyboard =====
def generate_buttons(buttons_list):
    """
    buttons_list: List of lists [['Text', 'callback_data'], ...]
    Example:
    [
        ['🌟 پلن 30 روزه', 'plan_30'],
        ['🌟 پلن 90 روزه', 'plan_90']
    ]
    """
    keyboard = []
    for row in buttons_list:
        keyboard.append([InlineKeyboardButton(row[0], callback_data=row[1])])
    return InlineKeyboardMarkup(keyboard)

# ===== Format date =====
def format_date(dt: datetime, timezone_str="UTC") -> str:
    tz = pytz.timezone(timezone_str)
    local_dt = dt.astimezone(tz)
    return local_dt.strftime("%Y-%m-%d %H:%M:%S")

# ===== Add days to date =====
def add_days_to_now(days: int, timezone_str="UTC") -> str:
    tz = pytz.timezone(timezone_str)
    new_date = datetime.now(tz) + timedelta(days=days)
    return new_date.strftime("%Y-%m-%d %H:%M:%S")

# ===== Shorten text for messages =====
def truncate_text(text: str, length=200) -> str:
    if len(text) > length:
        return text[:length] + "..."
    return text
