#!/bin/bash
#!/bin/bash
set -e

echo "⚙️ Setting up systemd services for Vebora Store..."

# ===== Configuration =====
PROJECT_DIR="/var/vebora"
USERNAME="vebora"

# ===== Backend Service =====
cat <<EOL | sudo tee /etc/systemd/system/vebora-backend.service
[Unit]
Description=Vebora Store Backend
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$PROJECT_DIR/backend
ExecStart=/usr/bin/python3 main.py
Restart=on-failure
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOL

# ===== Bot Service =====
cat <<EOL | sudo tee /etc/systemd/system/vebora-bot.service
[Unit]
Description=Vebora Store Telegram Bot
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$PROJECT_DIR/bot
ExecStart=/usr/bin/python3 bot.py
Restart=on-failure
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOL

# ===== Mini App Service (Optional) =====
cat <<EOL | sudo tee /etc/systemd/system/vebora-miniapp.service
[Unit]
Description=Vebora Store Mini App
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$PROJECT_DIR/miniapp
ExecStart=/usr/bin/npm run start
Restart=on-failure
Environment=NODE_ENV=production
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOL

# ===== Reload systemd =====
sudo systemctl daemon-reload

# ===== Enable Services =====
sudo systemctl enable vebora-backend
sudo systemctl enable vebora-bot
sudo systemctl enable vebora-miniapp

# ===== Start Services =====
sudo systemctl start vebora-backend
sudo systemctl start vebora-bot
sudo systemctl start vebora-miniapp

echo "✅ Systemd services setup complete!"
echo "🔹 Services running:"
sudo systemctl status vebora-backend --no-pager
sudo systemctl status vebora-bot --no-pager
sudo systemctl status vebora-miniapp --no-pager
