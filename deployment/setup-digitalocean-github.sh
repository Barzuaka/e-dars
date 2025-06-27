#!/bin/bash

# DigitalOcean Droplet Setup Script for E-Dars Course Platform (GitHub-based)
# Run this as root on your fresh droplet

set -e

echo "🚀 Setting up E-Dars course platform on DigitalOcean (GitHub-based)..."

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install essential packages
echo "🔧 Installing essential packages..."
apt install -y curl wget git nginx certbot python3-certbot-nginx ufw

# Install Node.js 20.x
echo "📦 Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install PM2 globally
echo "⚡ Installing PM2 process manager..."
npm install -g pm2

# Install MongoDB
echo "🗄️ Installing MongoDB..."
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
apt update
apt install -y mongodb-org

# Start and enable MongoDB
systemctl start mongod
systemctl enable mongod

# Create application directory
echo "📁 Creating application directory..."
mkdir -p /var/www/e-dars
chown -R $SUDO_USER:$SUDO_USER /var/www/e-dars

# Configure firewall
echo "🔥 Configuring firewall..."
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 3001
ufw --force enable

# Create environment file template
echo "📝 Creating environment file template..."
cat > /var/www/e-dars/.env.template << 'EOF'
# Database Configuration
MONGO_URI=mongodb://localhost:27017/e-dars

# Session Configuration
SESSION_SECRET=your-super-secret-session-key-change-this

# Admin Configuration
ADMIN_EMAIL=admin@e-dars.uz
ADMIN_PASSWORD=your-secure-admin-password

# Server Configuration
PORT=3001
NODE_ENV=production

# Optional: Telegram Bot (if you have one)
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
TELEGRAM_CHAT_ID=your-telegram-chat-id
EOF

# Configure Nginx
echo "🌐 Configuring Nginx..."
cat > /etc/nginx/sites-available/e-dars << 'EOF'
server {
    listen 80;
    server_name e-dars.uz www.e-dars.uz;
    
    # Redirect to HTTPS (will be enabled after SSL setup)
    # return 301 https://$server_name$request_uri;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Serve static files directly
    location /public/ {
        alias /var/www/e-dars/public/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3001/health;
        access_log off;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/e-dars /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Create GitHub-based deployment script
echo "📜 Creating GitHub deployment script..."
cat > /var/www/e-dars/deploy-github.sh << 'EOF'
#!/bin/bash

set -e

GITHUB_REPO="your-username/course-platform"
BRANCH="main"

echo "🚀 Deploying E-Dars from GitHub..."

# Navigate to app directory
cd /var/www/e-dars

# Backup current version
echo "💾 Creating backup..."
if [ -d "backup" ]; then
    rm -rf backup
fi
mkdir -p backup
cp -r * backup/ 2>/dev/null || true

# Pull latest changes from GitHub
echo "📥 Pulling latest changes from GitHub..."
git fetch origin
git reset --hard origin/$BRANCH

# Install/update dependencies
echo "📦 Installing dependencies..."
npm install --production

# Restart the application
echo "🔄 Restarting application..."
pm2 restart e-dars || pm2 start ecosystem.config.js

echo "✅ Deployment completed successfully!"
echo "📊 Check status with: pm2 status"
echo "📋 Check logs with: pm2 logs e-dars"
EOF

chmod +x /var/www/e-dars/deploy-github.sh

# Create PM2 ecosystem file
echo "⚙️ Creating PM2 configuration..."
cat > /var/www/e-dars/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'e-dars',
    script: 'app.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: '/var/log/pm2/e-dars-error.log',
    out_file: '/var/log/pm2/e-dars-out.log',
    log_file: '/var/log/pm2/e-dars-combined.log',
    time: true
  }]
};
EOF

# Create log directory
mkdir -p /var/log/pm2
chown -R $SUDO_USER:$SUDO_USER /var/log/pm2

# Setup PM2 startup script
pm2 startup
echo "⚠️  Run the command above as your regular user to enable PM2 startup"

echo "✅ Setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Push your code to GitHub repository"
echo "2. Clone your repository: cd /var/www/e-dars && git clone https://github.com/your-username/course-platform.git ."
echo "3. Copy .env.template to .env and configure it"
echo "4. Run: npm install --production"
echo "5. Run: pm2 start ecosystem.config.js"
echo "6. Run: certbot --nginx -d e-dars.uz -d www.e-dars.uz"
echo "7. Test your application at https://e-dars.uz"
echo ""
echo "🔧 Useful commands:"
echo "- Deploy updates: ./deploy-github.sh"
echo "- Check app status: pm2 status"
echo "- View logs: pm2 logs e-dars"
echo "- Restart app: pm2 restart e-dars" 