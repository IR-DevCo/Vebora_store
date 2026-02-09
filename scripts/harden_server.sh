#!/bin/bash
set -e

echo "🔒 Starting full server hardening for Vebora Store..."

# ===== Update & Upgrade =====
echo "📦 Updating packages..."
sudo apt update && sudo apt upgrade -y

# ===== Install essential tools =====
echo "🛠 Installing essential tools..."
sudo apt install -y curl git ufw fail2ban unzip software-properties-common build-essential apt-transport-https ca-certificates gnupg lsb-release

# ===== Create a new user =====
USERNAME="vebora"
echo "👤 Creating new user: $USERNAME"
sudo adduser --disabled-password --gecos "" $USERNAME
sudo usermod -aG sudo $USERNAME

# ===== SSH Hardening =====
SSH_PORT=2222
echo "🔐 Configuring SSH on port $SSH_PORT"
sudo sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sudo systemctl restart sshd

# ===== UFW Firewall =====
echo "🛡 Setting up UFW firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow $SSH_PORT/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# ===== Fail2Ban =====
echo "🚫 Configuring Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# ===== Docker & Docker Compose =====
echo "🐳 Installing Docker & Docker Compose..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USERNAME
sudo systemctl enable docker
sudo systemctl start docker

# ===== Nginx & Certbot =====
echo "🌐 Installing Nginx & Certbot..."
sudo apt install -y nginx certbot python3-certbot-nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# ===== Timezone & Locale =====
echo "⏰ Setting timezone & locale..."
sudo timedatectl set-timezone Asia/Tehran
sudo locale-gen fa_IR.UTF-8
sudo update-locale LANG=fa_IR.UTF-8

# ===== Swap setup =====
if ! swapon --show | grep -q "swap"; then
    echo "💾 Setting up 2G swap..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# ===== Prepare project folders =====
echo "📁 Creating project directories..."
sudo mkdir -p /var/vebora/frontend
sudo mkdir -p /var/vebora/backend
sudo mkdir -p /var/vebora/bot
sudo chown -R $USERNAME:$USERNAME /var/vebora

# ===== Systemd Services Placeholder =====
echo "⚙️ Creating systemd service templates..."
cat <<EOL | sudo tee /etc/systemd/system/vebora-backend.service
[Unit]
Description=Vebora Store Backend
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=/var/vebora/backend
ExecStart=/usr/bin/python3 main.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

cat <<EOL | sudo tee /etc/systemd/system/vebora-bot.service
[Unit]
Description=Vebora Store Telegram Bot
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=/var/vebora/bot
ExecStart=/usr/bin/python3 bot.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable vebora-backend
sudo systemctl enable vebora-bot

echo "✅ Full server hardening complete! Your VPS is ready for Vebora Store."
echo "🔹 SSH port: $SSH_PORT"
echo "🔹 Project folder: /var/vebora"
echo "🔹 Docker installed and running"
