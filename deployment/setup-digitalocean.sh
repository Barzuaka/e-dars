#!/bin/bash

# Digital Ocean Server Setup Script for course-platform
# Run this script on your fresh Digital Ocean droplet
# Usage: bash setup-digitalocean.sh

set -e  # Exit on any error

echo "🔧 Setting up Digital Ocean droplet for course-platform..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

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
echo "🚀 Starting MongoDB..."
sudo systemctl start mongod
sudo systemctl enable mongod

# Install Nginx
echo "📦 Installing Nginx..."
sudo apt install -y nginx

# Install PM2 for process management
echo "📦 Installing PM2..."
sudo npm install -g pm2

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /var/www/course-platform
sudo chown $USER:$USER /var/www/course-platform

# Clone your repository (replace with your actual GitHub repo URL)
echo "📥 Cloning repository..."
cd /var/www
git clone https://github.com/your-username/course-platform.git course-platform
cd course-platform

# Install dependencies
echo "📦 Installing project dependencies..."
npm install --production

# Create systemd service file
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/course-platform.service > /dev/null <<EOF
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
sudo tee /etc/nginx/sites-available/course-platform > /dev/null <<EOF
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

    # Serve static files directly
    location /public/ {
        alias /var/www/course-platform/public/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Uploads directory
    location /uploads/ {
        alias /var/www/course-platform/public/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/course-platform /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Start and enable services
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

# Make deploy script executable
chmod +x deployment/deploy.sh

echo "✅ Server setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Create .env file in /var/www/course-platform with your configuration:"
echo "   MONGO_URI=mongodb://localhost:27017/course-platform"
echo "   SESSION_SECRET=your-secret-key"
echo "   ADMIN_EMAIL=admin@e-dars.uz"
echo "   ADMIN_PASSWORD=your-secure-password"
echo ""
echo "2. Configure your domain DNS to point to this server (167.172.186.30)"
echo ""
echo "3. For future deployments, just run: ./deployment/deploy.sh"
echo ""
echo "4. Check application status: sudo systemctl status course-platform"
echo "5. View logs: sudo journalctl -u course-platform -f"
echo ""
echo "🌐 Your app should be available at: http://e-dars.uz" 