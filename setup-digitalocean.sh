#!/bin/bash

# DigitalOcean Initial Setup Script
# Run this script on a fresh Ubuntu droplet

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Update system
log "Updating system packages..."
apt update && apt upgrade -y

# Install essential packages
log "Installing essential packages..."
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add current user to docker group
usermod -aG docker $USER

# Install Docker Compose
log "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Nginx
log "Installing Nginx..."
apt install -y nginx

# Install Certbot for SSL
log "Installing Certbot..."
apt install -y certbot python3-certbot-nginx

# Install Node.js (for potential direct deployment)
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install PM2 for process management (alternative to Docker)
log "Installing PM2..."
npm install -g pm2

# Create application directory
log "Creating application directory..."
mkdir -p /opt/course-platform
mkdir -p /backups
mkdir -p /var/log/course-platform

# Set up firewall
log "Configuring firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# Configure Nginx
log "Configuring Nginx..."
cat > /etc/nginx/sites-available/course-platform << 'EOF'
# Placeholder configuration - will be replaced with actual config
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/course-platform /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx
systemctl enable nginx

# Create systemd service for the application (alternative to Docker)
log "Creating systemd service..."
cat > /etc/systemd/system/course-platform.service << 'EOF'
[Unit]
Description=Course Platform
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/course-platform
ExecStart=/usr/bin/node app.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3001

[Install]
WantedBy=multi-user.target
EOF

# Create log rotation configuration
log "Setting up log rotation..."
cat > /etc/logrotate.d/course-platform << 'EOF'
/var/log/course-platform/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload course-platform
    endscript
}
EOF

# Create monitoring script
log "Creating monitoring script..."
cat > /opt/monitor.sh << 'EOF'
#!/bin/bash

# Simple monitoring script
LOG_FILE="/var/log/course-platform/monitor.log"
APP_URL="http://localhost:3001/health"

# Check if application is responding
if curl -f $APP_URL > /dev/null 2>&1; then
    echo "$(date): Application is healthy" >> $LOG_FILE
else
    echo "$(date): Application is down - restarting..." >> $LOG_FILE
    systemctl restart course-platform
fi

# Check disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "$(date): Disk usage is high: ${DISK_USAGE}%" >> $LOG_FILE
fi

# Check memory usage
MEM_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
if [ $MEM_USAGE -gt 80 ]; then
    echo "$(date): Memory usage is high: ${MEM_USAGE}%" >> $LOG_FILE
fi
EOF

chmod +x /opt/monitor.sh

# Add monitoring to crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/monitor.sh") | crontab -

# Create backup script
log "Creating backup script..."
cat > /opt/backup.sh << 'EOF'
#!/bin/bash

# Backup script
BACKUP_DIR="/backups"
APP_DIR="/opt/course-platform"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="course_platform_backup_${TIMESTAMP}"

# Create backup
cd $APP_DIR
tar -czf $BACKUP_DIR/$BACKUP_NAME.tar.gz --exclude=node_modules --exclude=.git .

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t course_platform_backup_*.tar.gz | tail -n +8 | xargs -r rm

echo "Backup created: $BACKUP_NAME"
EOF

chmod +x /opt/backup.sh

# Add backup to crontab (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/backup.sh") | crontab -

# Set up environment file template
log "Creating environment file template..."
cat > /opt/course-platform/.env.template << 'EOF'
# Database Configuration
MONGO_URI=mongodb://your-mongodb-uri

# Session Configuration
SESSION_SECRET=your-session-secret-here

# Admin Configuration
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=your-secure-password

# Telegram Configuration (optional)
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
TELEGRAM_CHAT_ID=your-telegram-chat-id

# Bunny Storage Configuration (optional)
BUNNY_STORAGE_ZONE=your-bunny-storage-zone
BUNNY_API_KEY=your-bunny-api-key

# Environment
NODE_ENV=production
PORT=3001
EOF

# Create deployment script
log "Creating deployment script..."
cat > /opt/deploy.sh << 'EOF'
#!/bin/bash

# Simple deployment script
APP_DIR="/opt/course-platform"
BACKUP_DIR="/backups"

# Create backup
/opt/backup.sh

# Pull latest code (if using git)
# cd $APP_DIR && git pull origin main

# Install dependencies
cd $APP_DIR && npm install --production

# Restart application
systemctl restart course-platform

# Wait for health check
sleep 10

# Check if application is healthy
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    echo "Deployment successful!"
else
    echo "Deployment failed! Rolling back..."
    # Rollback logic here
    exit 1
fi
EOF

chmod +x /opt/deploy.sh

# Set proper permissions
chown -R root:root /opt/course-platform
chmod -R 755 /opt/course-platform

log "Setup completed successfully!"
log ""
log "Next steps:"
log "1. Update /opt/course-platform/.env.template with your actual values"
log "2. Copy your application files to /opt/course-platform/"
log "3. Update the domain in Nginx configuration"
log "4. Set up SSL certificate with: certbot --nginx -d your-domain.com"
log "5. Start the application: systemctl start course-platform"
log "6. Enable auto-start: systemctl enable course-platform"
log ""
log "For Docker deployment:"
log "1. Copy docker-compose.yml to /opt/course-platform/"
log "2. Run: docker-compose up -d"
log ""
log "Monitoring logs:"
log "- Application logs: journalctl -u course-platform -f"
log "- Nginx logs: tail -f /var/log/nginx/access.log"
log "- Monitor logs: tail -f /var/log/course-platform/monitor.log" 