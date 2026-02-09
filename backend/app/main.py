from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

# Import routers
from routers import users, subscriptions, orders, admin

# Load environment variables
from dotenv import load_dotenv
load_dotenv(".env")

app = FastAPI(
    title="Vebora Store Backend",
    description="Commercial VPN Platform with 3x-ui Integration",
    version="1.0.0"
)

# ===== CORS =====
origins = [
    f"https://{os.getenv('MINIAPP_DOMAIN')}",
    f"http://{os.getenv('MINIAPP_DOMAIN')}"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== Include routers =====
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(subscriptions.router, prefix="/api/subscriptions", tags=["Subscriptions"])
app.include_router(orders.router, prefix="/api/orders", tags=["Orders"])
app.include_router(admin.router, prefix="/api/admin", tags=["Admin"])

# ===== Root endpoint =====
@app.get("/")
def root():
    return {"message": "🚀 Vebora Store Backend is running!"}

# ===== Startup event =====
@app.on_event("startup")
async def startup_event():
    print("🌐 Vebora Store Backend starting...")
    # TODO: Initialize DB, 3x-ui client, cache, etc.
