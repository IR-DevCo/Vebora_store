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

# ===== CLONE OR UPDATE PROJECT =====
if [ ! -d "$PROJECT_DIR/.git" ]; then
  echo "[*] Cloning Vebora platform..."
  git clone https://github.com/IR-DevCo/Vebora_store.git $PROJECT_DIR
else
  echo "[*] Updating Vebora platform..."
  cd $PROJECT_DIR
  git pull
fi

pause() { read -p "Press Enter to continue..."; }

# ===== INSTALL FUNCTIONS =====
install_backend() {
  cd $PROJECT_DIR/backend
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  systemctl daemon-reload
  systemctl enable vebora-backend
  systemctl restart vebora-backend
  echo "✅ Backend installed"
  pause
}

install_bot() {
  cd $PROJECT_DIR/bot
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  systemctl daemon-reload
  systemctl enable vebora-bot
  systemctl restart vebora-bot
  echo "✅ Bot installed"
  # ===== Send Telegram notification =====
  BOT_MSG="✅ Vebora Bot is now active."
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=$ADMIN_CHAT_ID&text=$BOT_MSG"
  pause
}

install_miniapp() {
  cd $PROJECT_DIR/miniapp
  npm install
  npm run build
  systemctl daemon-reload
  systemctl enable vebora-miniapp
  systemctl restart vebora-miniapp
  echo "✅ Mini App installed"
  pause
}

setup_nginx() {
  apt install -y nginx
  cp $PROJECT_DIR/nginx/*.conf /etc/nginx/sites-enabled/
  nginx -t && systemctl reload nginx
  echo "✅ Nginx configured"
  pause
}

setup_ssl() {
  apt install -y certbot python3-certbot-nginx
  certbot --nginx --non-interactive --agree-tos
  echo "✅ SSL configured"
  pause
}

start_services() {
  systemctl restart vebora-backend vebora-bot vebora-miniapp
  echo "✅ All services started"
  pause
}

menu() {
  while true; do
    clear
    echo "=== Vebora Store Installer Menu ==="
    echo "1) Install Backend"
    echo "2) Install Telegram Bot"
    echo "3) Install Mini App"
    echo "4) Setup Nginx + Subdomains"
    echo "5) Setup SSL (Let's Encrypt)"
    echo "6) Start All Services"
    echo "0) Exit"
    read -p "Select: " opt

    case $opt in
      1) install_backend ;;
      2) install_bot ;;
      3) install_miniapp ;;
      4) setup_nginx ;;
      5) setup_ssl ;;
      6) start_services ;;
      0) exit 0 ;;
      *) echo "Invalid choice"; sleep 2 ;;
    esac
  done
}

# ===== CREATE SYSTEMD SERVICES =====
mkdir -p /etc/systemd/system

cat > /etc/systemd/system/vebora-backend.service << EOF
[Unit]
Description=Vebora Backend API
After=network.target

[Service]
WorkingDirectory=$PROJECT_DIR/backend
ExecStart=$PROJECT_DIR/backend/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/vebora-bot.service << EOF
[Unit]
Description=Vebora Telegram Bot
After=network.target

[Service]
WorkingDirectory=$PROJECT_DIR/bot
ExecStart=$PROJECT_DIR/bot/venv/bin/python bot.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/vebora-miniapp.service << EOF
[Unit]
Description=Vebora Mini App
After=network.target

[Service]
WorkingDirectory=$PROJECT_DIR/miniapp
ExecStart=/usr/bin/npm run start -- -p 7575
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo "✅ Systemd services created"

# ===== START MENU =====
menu
