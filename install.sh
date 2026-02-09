#!/bin/bash
set -e

PROJECT_DIR=/opt/vpn-platform

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

EOF

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
read -p "Enter Database User (e.g., vpnbot): " DB_USER
read -p "Enter Database Password: " DB_PASS

# ===== Create project dir & save .env =====
mkdir -p $PROJECT_DIR
cat > $PROJECT_DIR/.env << EOF
# Bot Configuration
BOT_TOKEN=$TELEGRAM_BOT_TOKEN
ADMIN_CHAT_ID=$ADMIN_CHAT_ID
FORCE_CHANNEL=$FORCE_CHANNEL

# Backend Configuration
API_BASE=https://$BACKEND_DOMAIN
HOST=0.0.0.0
PORT=8000

# Database
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=vpnbot
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASS

# X-UI
XUI_HOST=$XUI_URL
XUI_USER=$XUI_USER
XUI_PASS=$XUI_PASS
XUI_INBOUND_ID=$XUI_INBOUND_ID

# Misc
LOG_LEVEL=info
EOF

echo "✅ .env file created at $PROJECT_DIR/.env"

# ===== Menu =====
menu() {
  clear
  echo "=== Vebora Store Installer Menu ==="
  echo "1) Install Backend"
  echo "2) Install Telegram Bot"
  echo "3) Install Mini App"
  echo "4) Setup PostgreSQL Database"
  echo "5) Setup Nginx + Subdomains"
  echo "6) Setup SSL (Let's Encrypt)"
  echo "7) Start All Services"
  echo "0) Exit"
  read -p "Select: " opt

  case $opt in
    1) install_backend ;;
    2) install_bot ;;
    3) install_miniapp ;;
    4) setup_database ;;
    5) setup_nginx ;;
    6) setup_ssl ;;
    7) start_services ;;
    0) exit ;;
    *) echo "Invalid choice"; read -p "Enter..." ; menu ;;
  esac
}

install_backend() {
  echo "📦 Installing Backend dependencies..."
  apt update
  apt install -y python3-venv python3-pip
  cd $PROJECT_DIR/backend
  python3 -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r requirements.txt
  cp systemd/vpn-backend.service /etc/systemd/system/
  systemctl daemon-reload
  echo "✅ Backend installed"
  read -p "Press Enter to continue..."
  menu
}

install_bot() {
  echo "🤖 Installing Telegram Bot..."
  cd $PROJECT_DIR/bot
  python3 -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r requirements.txt
  cp systemd/vpn-bot.service /etc/systemd/system/
  systemctl daemon-reload
  echo "✅ Bot installed"
  read -p "Press Enter to continue..."
  menu
}

install_miniapp() {
  echo "🌐 Installing Mini App..."
  apt install -y nodejs npm
  cd $PROJECT_DIR/miniapp
  npm install
  npm run build
  echo "✅ Mini App built"
  read -p "Press Enter to continue..."
  menu
}

setup_database() {
  echo "🗄 Setting up PostgreSQL Database..."
  apt install -y postgresql postgresql-contrib
  sudo -u postgres psql -c "CREATE DATABASE vpnbot;"
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE vpnbot TO $DB_USER;"
  echo "✅ Database configured"
  read -p "Press Enter to continue..."
  menu
}

setup_nginx() {
  echo "🖥 Configuring Nginx..."
  apt install -y nginx
  cp $PROJECT_DIR/nginx/backend.conf /etc/nginx/sites-available/backend.conf
  cp $PROJECT_DIR/nginx/miniapp.conf /etc/nginx/sites-available/miniapp.conf
  ln -sf /etc/nginx/sites-available/backend.conf /etc/nginx/sites-enabled/backend.conf
  ln -sf /etc/nginx/sites-available/miniapp.conf /etc/nginx/sites-enabled/miniapp.conf
  nginx -t && systemctl restart nginx
  echo "✅ Nginx configured"
  read -p "Press Enter to continue..."
  menu
}

setup_ssl() {
  echo "🔐 Setting up SSL with Let's Encrypt..."
  apt install -y certbot python3-certbot-nginx
  certbot --nginx --agree-tos --redirect -m admin@$BACKEND_DOMAIN -d $BACKEND_DOMAIN -d $MINIAPP_DOMAIN --non-interactive
  echo "✅ SSL configured"
  read -p "Press Enter to continue..."
  menu
}

start_services() {
  echo "🚀 Starting all services..."
  systemctl enable vpn-backend vpn-bot
  systemctl start vpn-backend vpn-bot
  echo "✅ All services started"
  read -p "Press Enter to continue..."
  menu
}

# ===== Start menu =====
while true; do
  menu
done
