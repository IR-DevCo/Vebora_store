#!/bin/bash
set -e

PROJECT_DIR=/opt/vpn-platform
LOG_FILE=/var/log/vebora-install.log
ENV_FILE=$PROJECT_DIR/.env
GIT_REPO="https://github.com/IR-DevCo/Vebora_store.git"

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
EOF

# ===== Base Packages =====
apt update
apt install -y curl git ca-certificates gnupg lsb-release software-properties-common

# ===== Ask for config (once) =====
mkdir -p $PROJECT_DIR

if [ ! -f "$ENV_FILE" ]; then
  read -p "Enter Telegram Bot Token: " TELEGRAM_BOT_TOKEN
  read -p "Enter Admin Telegram Chat ID: " ADMIN_CHAT_ID
  read -p "Enter Force Join Channel Username (without @): " FORCE_CHANNEL
  read -p "Enter Backend Subdomain: " BACKEND_DOMAIN
  read -p "Enter Mini App Subdomain: " MINIAPP_DOMAIN
  read -p "Enter 3x-ui URL: " XUI_URL
  read -p "Enter 3x-ui Username: " XUI_USER
  read -p "Enter 3x-ui Password: " XUI_PASS
  read -p "Enter 3x-ui Inbound ID: " XUI_INBOUND_ID

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
fi

pause() { read -p "Press Enter to return to menu..."; }

# ===== Prepare Project =====
prepare_project() {
  if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "📦 Cloning Vebora repository..."
    rm -rf $PROJECT_DIR
    git clone $GIT_REPO $PROJECT_DIR
  else
    echo "🔄 Updating Vebora repository..."
    cd $PROJECT_DIR
    git pull
  fi
}

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
  pause
}

# ===== Node.js =====
install_node() {
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  apt install -y nodejs
}

# ===== Backend =====
install_backend() {
  prepare_project

  if [ ! -d "$PROJECT_DIR/backend" ]; then
    echo "❌ backend/ directory not found in repo"
    pause
    return
  fi

  apt install -y python3-venv python3-pip

  cd $PROJECT_DIR/backend
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt

  cp systemd/vpn-backend.service /etc/systemd/system/ || true
  systemctl daemon-reload

  echo "✅ Backend installed"
  pause
}

# ===== Bot =====
install_bot() {
  prepare_project

  if [ ! -d "$PROJECT_DIR/bot" ]; then
    echo "❌ bot/ directory not found"
    pause
    return
  fi

  cd $PROJECT_DIR/bot
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt

  cp systemd/vpn-bot.service /etc/systemd/system/ || true
  systemctl daemon-reload

  echo "✅ Telegram Bot installed"
  pause
}

# ===== Mini App =====
install_miniapp() {
  prepare_project
  install_node

  if [ ! -d "$PROJECT_DIR/miniapp" ]; then
    echo "❌ miniapp/ directory not found"
    pause
    return
  fi

  cd $PROJECT_DIR/miniapp
  npm install
  npm run build

  echo "✅ Mini App built"
  pause
}

# ===== Nginx =====
setup_nginx() {
  apt install -y nginx
  cp $PROJECT_DIR/nginx/*.conf /etc/nginx/sites-enabled/ || true
  nginx -t && systemctl reload nginx
  echo "✅ Nginx configured"
  pause
}

# ===== SSL =====
setup_ssl() {
  apt install -y certbot python3-certbot-nginx
  certbot --nginx
  echo "✅ SSL configured"
  pause
}

# ===== Start Services =====
start_services() {
  systemctl enable vpn-backend vpn-bot || true
  systemctl restart vpn-backend vpn-bot || true
  echo "✅ Services started"
  pause
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
    8) install_node; pause ;;
    0) exit ;;
    *) echo "Invalid choice"; sleep 2 ;;
  esac
}

# ===== Main Loop =====
while true; do
  menu
done
