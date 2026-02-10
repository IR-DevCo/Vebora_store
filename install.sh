#!/bin/bash
set -e

PROJECT_DIR=/opt/vpn-platform
LOG_FILE=/var/log/vebora-install.log
ENV_FILE=$PROJECT_DIR/.env

exec > >(tee -a $LOG_FILE) 2>&1

# ===== Root Check =====
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

# ===== Banner =====
clear
cat << "EOF"

██╗   ██╗███████╗██████╗  ██████╗ ██████╗  █████╗ 
██║   ██║██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗
██║   ██║█████╗  ██████╔╝██║   ██║██████╔╝███████║
╚██╗ ██╔╝██╔══╝  ██╔══██╗██║   ██║██╔══██╗██╔══██║
 ╚████╔╝ ███████╗██████╔╝╚██████╔╝██║  ██║██║  ██║
  ╚═══╝  ╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝

        🚀 Vebora Store - VPN Platform Installer
        🔐 Commercial Grade VPN Automation
        🤖 Bot + Mini App + 3x-ui Integration

Log: $LOG_FILE
EOF

# ===== Base Packages =====
apt update
apt install -y curl git ca-certificates gnupg lsb-release software-properties-common

# ===== Ask for config =====
read -p "Enter Telegram Bot Token: " TELEGRAM_BOT_TOKEN
read -p "Enter Admin Telegram Chat ID: " ADMIN_CHAT_ID
read -p "Enter Force Join Channel Username (without @): " FORCE_CHANNEL
read -p "Enter Backend Subdomain (e.g., api.example.com): " BACKEND_DOMAIN
read -p "Enter Mini App Subdomain (e.g., app.example.com): " MINIAPP_DOMAIN
read -p "Enter 3x-ui URL (http://IP:Port): " XUI_URL
read -p "Enter 3x-ui Username: " XUI_USER
read -p "Enter 3x-ui Password: " XUI_PASS
read -p "Enter 3x-ui Inbound ID: " XUI_INBOUND_ID

# ===== Save .env =====
mkdir -p $PROJECT_DIR
cat > $ENV_FILE << EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
ADMIN_CHAT_ID=$ADMIN_CHAT_ID
FORCE_CHANNEL=$FORCE_CHANNEL
BACKEND_DOMAIN=$BACKEND_DOMAIN
MINIAPP_DOMAIN=$MINIAPP_DOMAIN
XUI_URL=$XUI_URL
XUI_USER=$XUI_USER
XUI_PASS=$XUI_PASS
XUI_INBOUND_ID=$XUI_INBOUND_ID
DATABASE_URL=postgresql://vpnbot:STRONG_PASSWORD@localhost:5432/vpnbot
EOF

chmod 600 $ENV_FILE

# ===== Helper =====
pause() { read -p "Press Enter to continue..."; }

# ===== PostgreSQL =====
setup_postgres() {
  apt install -y postgresql
  sudo -u postgres psql <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='vpnbot') THEN
    CREATE USER vpnbot WITH PASSWORD 'STRONG_PASSWORD';
  END IF;
END
\$\$;
CREATE DATABASE vpnbot OWNER vpnbot;
EOF
  echo "✅ PostgreSQL ready"
}

# ===== Node.js LTS =====
install_node() {
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  apt install -y nodejs
}

# ===== Menu =====
menu() {
  clear
  echo "=== Vebora Store Installer Menu ==="
  echo "1) Install Backend"
  echo "2) Install Telegram Bot"
  echo "3) Install Mini App"
  echo "4) Setup Nginx + Subdomains"
  echo "5) Setup SSL (Let's Encrypt)"
  echo "6) Start All Services"
  echo "7) Setup PostgreSQL"
  echo "8) Install/Update Node.js LTS"
  echo "9) Install VPS Control Menu"
  echo "0) Exit"
  read -p "Select: " opt

  case $opt in
    1) install_backend ;;
    2) install_bot ;;
    3) install_miniapp ;;
    4) setup_nginx ;;
    5) setup_ssl ;;
    6) start_services ;;
    7) setup_postgres ;;
    8) install_node ;;
    9) install_control_menu ;;
    0) exit ;;
    *) echo "Invalid choice"; sleep 2 ;;
  esac
}

install_backend() {
  apt install -y python3-venv python3-pip
  cd $PROJECT_DIR/backend
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  cp systemd/vpn-backend.service /etc/systemd/system/
  systemctl daemon-reload
  echo "✅ Backend installed"
  pause
}

install_bot() {
  cd $PROJECT_DIR/bot
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  cp systemd/vpn-bot.service /etc/systemd/system/
  systemctl daemon-reload
  echo "✅ Bot installed"
  pause
}

install_miniapp() {
  install_node
  cd $PROJECT_DIR/miniapp
  npm install
  npm run build
  npm run start &
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
  certbot --nginx
  echo "✅ SSL configured"
  pause
}

start_services() {
  systemctl enable vpn-backend vpn-bot
  systemctl start vpn-backend vpn-bot
  echo "✅ All services started"
  pause
}

install_control_menu() {
  cp $PROJECT_DIR/vebora-menu.sh /usr/local/bin/vebora
  chmod +x /usr/local/bin/vebora
  echo "✅ VPS Control Menu installed. Run: vebora"
  pause
}

# ===== Start menu =====
while true; do
  menu
done