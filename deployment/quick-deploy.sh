#!/bin/bash

# Quick Deploy Script for Digital Ocean
# This script will set up everything from scratch
# Run this on your fresh Digital Ocean droplet

set -e

echo "🚀 Quick Deploy Script for Course Platform"
echo "=========================================="

# Update system
echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "📦 Installing packages..."
sudo apt install -y curl wget git nginx

# Install Node.js 20.x
echo "📦 Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install MongoDB
echo "📦 Installing MongoDB..."
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org

# Start and enable MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Create application directory
echo "📁 Setting up application directory..."
sudo mkdir -p /var/www/course-platform
sudo chown $USER:$USER /var/www/course-platform

# Clone repository (REPLACE WITH YOUR ACTUAL GITHUB REPO URL)
echo "📥 Cloning repository..."
cd /var/www
git clone git clone https://github.com/Barzuaka/e-dars.git course-platform
cd course-platform

# Install dependencies
echo "📦 Installing dependencies..."
npm install --production

# Create .env file
echo "🔧 Creating .env file..."
cat > .env << EOF
MONGO_URI=mongodb://localhost:27017/course-platform
SESSION_SECRET=$(openssl rand -hex 32)
ADMIN_EMAIL=admin@e-dars.uz
ADMIN_PASSWORD=admin123456
PORT=3001
NODE_ENV=production
EOF

# Create systemd service
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/course-platform.service > /dev/null << EOF
[Unit]
Description=Course Platform Node.js App
After=network.target mongod.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/course-platform
ExecStart=/usr/bin/node app.js
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3001

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
echo "🔧 Configuring Nginx..."
sudo tee /etc/nginx/sites-available/course-platform > /dev/null << EOF
server {
    listen 80;
    server_name e-dars.uz www.e-dars.uz;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    location /public/ {
        alias /var/www/course-platform/public/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /uploads/ {
        alias /var/www/course-platform/public/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable site and remove default
sudo ln -sf /etc/nginx/sites-available/course-platform /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx config
sudo nginx -t

# Start services
echo "🚀 Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable course-platform
sudo systemctl start course-platform
sudo systemctl restart nginx

# Configure firewall
echo "🔒 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# Make scripts executable
chmod +x deployment/*.sh

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Important Information:"
echo "🌐 Your app is available at: http://e-dars.uz"
echo "🔑 Admin login: admin@e-dars.uz / admin123456"
echo "📁 Application directory: /var/www/course-platform"
echo ""
echo "📋 Useful Commands:"
echo "• Check status: sudo systemctl status course-platform"
echo "• View logs: sudo journalctl -u course-platform -f"
echo "• Deploy updates: ./deployment/deploy.sh"
echo "• Monitor health: ./deployment/monitor.sh"
echo "• Create backup: ./deployment/backup.sh"
echo ""
echo "⚠️  IMPORTANT: Change the admin password after first login!"
echo "⚠️  IMPORTANT: Update the SESSION_SECRET in .env file!" 