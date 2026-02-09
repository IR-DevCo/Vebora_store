#!/bin/bash
#!/bin/bash
set -e

echo "🌐 Setting up Nginx for Vebora Store..."

# ===== Configuration =====
DOMAIN="subdomain.yourdomain.com"   # دامنه یا ساب‌دامین خود را اینجا قرار دهید
FRONTEND_PORT=3000
MINIAPP_PORT=4000
API_PATH="/api"
PROJECT_DIR="/var/vebora"

# ===== Install Nginx =====
if ! command -v nginx &> /dev/null; then
    echo "📦 Installing Nginx..."
    sudo apt update
    sudo apt install -y nginx
fi

# ===== Nginx Configuration =====
NGINX_CONF="/etc/nginx/sites-available/vebora-store.conf"
echo "📄 Creating Nginx configuration at $NGINX_CONF ..."

sudo tee $NGINX_CONF > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    # Frontend Next.js
    location / {
        proxy_pass http://127.0.0.1:$FRONTEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    # API Backend
    location $API_PATH/ {
        proxy_pass http://127.0.0.1:8000$API_PATH/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Mini App (optional) on /miniapp
    location /miniapp/ {
        proxy_pass http://127.0.0.1:$MINIAPP_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# ===== Enable site =====
sudo ln -sf /etc/nginx/sites-available/vebora-store.conf /etc/nginx/sites-enabled/vebora-store.conf

# ===== Test Nginx configuration =====
sudo nginx -t

# ===== Restart Nginx =====
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "✅ Nginx setup complete for $DOMAIN!"
echo "🔹 Frontend: http://$DOMAIN/"
echo "🔹 API: http://$DOMAIN$API_PATH/"
echo "🔹 Mini App: http://$DOMAIN/miniapp/"
