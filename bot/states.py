from enum import Enum, auto

class UserStates(Enum):
    START = auto()          # کاربر تازه وارد / منوی اصلی
    BUY_PLAN = auto()       # انتخاب پلن
    CONFIRM_PLAN = auto()   # تایید خرید پلن
    VIEW_USAGE = auto()     # مشاهده مصرف
    SUPPORT = auto()        # منوی پشتیبانی

class AdminStates(Enum):
    START = auto()              # منوی اصلی ادمین
    SEND_MESSAGE = auto()       # ارسال پیام به کاربر
    BROADCAST_USERS = auto()    # پیام همگانی به کاربران
    BROADCAST_CHANNEL = auto()  # پیام به کانال
    LIST_USERS = auto()         # مشاهده لیست کاربران
    PROVISION_USER = auto()     # پروویژن کاربر جدید
