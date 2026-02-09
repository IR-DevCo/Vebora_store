from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import SQLAlchemyError
from .models import Base
import os

# ===============================
# Load environment variables
# ===============================
DB_USER = os.getenv("DB_USER", "vebora")
DB_PASSWORD = os.getenv("DB_PASSWORD", "vebora123")
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = os.getenv("DB_PORT", "5432")  # 3306 برای MySQL
DB_NAME = os.getenv("DB_NAME", "vebora_db")
DB_TYPE = os.getenv("DB_TYPE", "postgresql")  # postgresql یا mysql

DATABASE_URL = f"{DB_TYPE}://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# ===============================
# Create Engine & Session
# ===============================
try:
    engine = create_engine(DATABASE_URL, echo=False, future=True)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
except SQLAlchemyError as e:
    print("❌ Database connection failed:", e)
    raise e

# ===============================
# Initialize Database
# ===============================
def init_db():
    """
    Create all tables in the database.
    Call this function once during initial setup.
    """
    try:
        print("📦 Creating database tables...")
        Base.metadata.create_all(bind=engine)
        print("✅ Tables created successfully!")
    except SQLAlchemyError as e:
        print("❌ Failed to create tables:", e)
        raise e

# ===============================
# Dependency for FastAPI
# ===============================
def get_db():
    """
    Yield a database session for FastAPI routes.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
