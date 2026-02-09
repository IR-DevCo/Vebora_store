#!/bin/bash
#!/bin/bash
set -e

# ===== Configuration =====
DOMAIN="subdomain.yourdomain.com"   # دامنه یا ساب‌دامین خود را اینجا قرار دهید
EMAIL="admin@yourdomain.com"        # ایمیل شما برای SSL و اطلاع‌رسانی
NGINX_CONF="/etc/nginx/sites-available/vebora-store.conf"

echo "🔒 Starting SSL setup for $DOMAIN ..."

# ===== Check if Nginx config exists =====
if [ ! -f "$NGINX_CONF" ]; then
    echo "❌ Nginx config not found at $NGINX_CONF"
    exit 1
fi

# ===== Install Certbot if not installed =====
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing Certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# ===== Test Nginx configuration =====
echo "🔧 Testing Nginx configuration..."
sudo nginx -t

# ===== Obtain SSL certificate =====
echo "📄 Obtaining SSL certificate for $DOMAIN ..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL

# ===== Reload Nginx =====
echo "🔄 Reloading Nginx..."
sudo systemctl reload nginx

# ===== Auto-renewal =====
echo "⏰ Setting up auto-renewal..."
sudo systemctl enable certbot.timer

echo "✅ SSL setup complete! Your site https://$DOMAIN is now secured."
