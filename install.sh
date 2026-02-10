#!/bin/bash
set -e

PROJECT_DIR=/opt/vpn-platform
LOG_FILE=/var/log/vebora-install.log
ENV_FILE=$PROJECT_DIR/.env

exec > >(tee -a $LOG_FILE) 2>&1

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

clear
cat << "EOF"

██╗   ██╗███████╗██████╗  ██████╗ ██████╗  █████╗ 
██║   ██║██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗
██║   ██║█████╗  ██████╔╝██║   ██║██████╔╝███████║
╚██╗ ██╔╝██╔══╝  ██╔══██╗██║   ██║██╔══██╗██╔══██║
 ╚████╔╝ ███████╗██████╔╝╚██████╔╝██║  ██║██║  ██║
  ╚═══╝  ╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝

   🚀 Vebora Store - VPN Platform Installer
==================================================
       VEBORA STORE - FULL AUTO INSTALLER
          Zero Prompt | Auto X-UI Detect
           MiniApp:7575 | Backend Local
==================================================
EOF

apt update
apt install -y curl git ca-certificates gnupg lsb-release software-properties-common jq sqlite3 net-tools python3-venv python3-pip nodejs npm

# ===== ONLY REQUIRED INPUT =====
read -p "Enter Telegram Bot Token: " TELEGRAM_BOT_TOKEN
read -p "Enter Admin Telegram Chat ID: " ADMIN_CHAT_ID

mkdir -p $PROJECT_DIR

# ===== AUTO DETECT X-UI =====
echo "[*] Detecting 3x-ui..."

XUI_PORT=$(ss -lntp | grep x-ui | awk '{print $4}' | cut -d: -f2 | head -n1 || true)

if [ -z "$XUI_PORT" ]; then
  echo "❌ 3x-ui not detected. Make sure x-ui is running."
  exit 1
fi

XUI_URL="http://127.0.0.1:$XUI_PORT"
echo "✅ X-UI detected at $XUI_URL"

# ===== AUTO DETECT INBOUND =====
XUI_DB=$(find /opt /etc -name "x-ui.db" 2>/dev/null | head -n1)

if [ -z "$XUI_DB" ]; then
  echo "❌ x-ui.db not found"
  exit 1
fi

INBOUND_ID=$(sqlite3 "$XUI_DB" "select id from inbounds limit 1;")

if [ -z "$INBOUND_ID" ]; then
  echo "❌ No inbound found in x-ui"
  exit 1
fi

echo "✅ Using Inbound ID: $INBOUND_ID"

# ===== SAVE ENV =====
cat > $ENV_FILE << EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
ADMIN_CHAT_ID=$ADMIN_CHAT_ID

XUI_URL=$XUI_URL
XUI_INBOUND_ID=$INBOUND_ID

BACKEND_BIND=127.0.0.1:8000
MINIAPP_PORT=7575
EOF

chmod 600 $ENV_FILE

echo "✅ Environment configured"

# ===== CLONE PROJECT IF NOT EXISTS =====
if [ ! -d "$PROJECT_DIR/backend" ]; then
  echo "[*] Cloning Vebora platform..."
  git clone https://github.com/IR-DevCo/Vebora_store.git $PROJECT_DIR
fi

# ===== SYSTEMD BACKEND =====
cat > /etc/systemd/system/vebora-backend.service << EOF
[Unit]
Description=Vebora Backend API
After=network.target

[Service]
WorkingDirectory=$PROJECT_DIR/backend
ExecStart=$PROJECT_DIR/backend/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ===== SYSTEMD BOT =====
cat > /etc/systemd/system/vebora-bot.service << EOF
[Unit]
Description=Vebora Telegram Bot
After=network.target

[Service]
WorkingDirectory=$PROJECT_DIR/bot
ExecStart=$PROJECT_DIR/bot/venv/bin/python bot.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ===== SYSTEMD MINIAPP =====
cat > /etc/systemd/system/vebora-miniapp.service << EOF
[Unit]
Description=Vebora Mini App
After=network.target

[Service]
WorkingDirectory=$PROJECT_DIR/miniapp
ExecStart=/usr/bin/npm run start -- -p 7575
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "===================================="
echo " INSTALL PHASE COMPLETE"
echo " Now run: bash install.sh again"
echo " Then choose menu options"
echo "===================================="
