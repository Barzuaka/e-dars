#!/bin/bash

# Digital Ocean Server Setup Script for Course Platform
# This script sets up a fresh Ubuntu droplet with all necessary components
# Updated to use latest stable versions of all technologies

set -e  # Exit on any error

echo "🚀 Starting Digital Ocean server setup for Course Platform with latest technologies..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "📦 Installing essential packages..."
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release build-essential

# Install Node.js 20.x (Latest LTS)
echo "📦 Installing Node.js 20.x (Latest LTS)..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
echo "✅ Node.js version: $(node --version)"
echo "✅ npm version: $(npm --version)"

# Install MongoDB 8.0 (Latest stable)
echo "📦 Installing MongoDB 8.0 (Latest stable)..."
wget -qO - https://www.mongodb.org/static/pgp/server-8.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update
sudo apt install -y mongodb-org

# Start and enable MongoDB
echo "🔧 Starting MongoDB service..."
sudo systemctl start mongod
sudo systemctl enable mongod

# Verify MongoDB installation
echo "✅ MongoDB version: $(mongod --version | head -n 1)"

# Install PM2 globally (Latest version)
echo "📦 Installing PM2 process manager (Latest version)..."
sudo npm install -g pm2@latest

# Verify PM2 installation
echo "✅ PM2 version: $(pm2 --version)"

# Install Nginx (Latest from Ubuntu repositories)
echo "📦 Installing Nginx..."
sudo apt install -y nginx

# Verify Nginx installation
echo "✅ Nginx version: $(nginx -v 2>&1)"

# Install Certbot for SSL (Latest version)
echo "📦 Installing Certbot for SSL certificates..."
sudo apt install -y certbot python3-certbot-nginx

# Verify Certbot installation
echo "✅ Certbot version: $(certbot --version)"

# Install additional useful tools
echo "📦 Installing additional tools..."
sudo apt install -y htop iotop nethogs tree jq

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /var/www/course-platform
sudo chown $USER:$USER /var/www/course-platform

# Create logs directory
echo "📁 Creating logs directory..."
sudo mkdir -p /var/log/course-platform
sudo chown $USER:$USER /var/log/course-platform

# Create uploads directory with proper permissions
echo "📁 Creating uploads directory..."
sudo mkdir -p /var/www/course-platform/public/uploads
sudo chown -R $USER:$USER /var/www/course-platform/public/uploads
sudo chmod -R 755 /var/www/course-platform/public/uploads

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 3001
sudo ufw --force enable

# Create PM2 ecosystem file with latest configurations
echo "⚙️ Creating PM2 ecosystem configuration..."
cat > /var/www/course-platform/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'course-platform',
    script: 'app.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'development',
      PORT: 3001
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: '/var/log/course-platform/err.log',
    out_file: '/var/log/course-platform/out.log',
    log_file: '/var/log/course-platform/combined.log',
    time: true,
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=1024',
    
    // Latest PM2 features
    autorestart: true,
    watch: false,
    max_restarts: 10,
    min_uptime: '10s',
    
    // Enhanced logging
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    
    // Environment variables
    env_file: '.env',
    
    // Health check with latest PM2
    health_check_grace_period: 3000,
    
    // Kill timeout
    kill_timeout: 5000,
    
    // Listen timeout
    listen_timeout: 8000,
    
    // PM2 specific
    pmx: true,
    source_map_support: true,
    
    // Cluster mode settings
    increment_var: 'PORT',
    instance_var: 'INSTANCE_ID',
    
    // Latest PM2 monitoring
    pm2_metrics: true
  }]
};
EOF

# Create enhanced Nginx configuration with latest features
echo "⚙️ Creating Nginx configuration with latest features..."
sudo tee /etc/nginx/sites-available/course-platform << 'EOF'
# Course Platform Nginx Configuration with Latest Features
# This file should be placed in /etc/nginx/sites-available/course-platform

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name e-dars.uz www.e-dars.uz;
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://$server_name$request_uri;
}

# Main HTTPS server block
server {
    listen 443 ssl http2;
    server_name e-dars.uz www.e-dars.uz;
    
    # SSL Configuration (will be managed by Certbot)
    # ssl_certificate /etc/letsencrypt/live/e-dars.uz/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/e-dars.uz/privkey.pem;
    
    # Latest SSL Security Settings
    ssl_protocols TLSv1.3 TLSv1.2;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # Latest Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval'; img-src 'self' data: blob: https:; media-src 'self' data: blob: https:;" always;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
    
    # Enhanced Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types 
        text/plain 
        text/css 
        text/xml 
        text/javascript 
        application/x-javascript 
        application/xml+rss 
        application/javascript 
        application/json
        application/xml
        image/svg+xml
        font/woff
        font/woff2
        application/font-woff
        application/font-woff2;
    
    # File Upload Limits
    client_max_body_size 100M;
    client_body_timeout 60s;
    client_header_timeout 60s;
    
    # Enhanced Rate Limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
    limit_req_zone $binary_remote_addr zone=upload:10m rate=2r/s;
    
    # Root directory
    root /var/www/course-platform/public;
    
    # Health check endpoint (no rate limiting)
    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        access_log off;
    }
    
    # Enhanced static files with latest caching
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp|avif)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
        add_header X-Content-Type-Options nosniff;
        try_files $uri =404;
    }
    
    # Uploads directory with enhanced security
    location /uploads/ {
        alias /var/www/course-platform/public/uploads/;
        expires 1y;
        add_header Cache-Control "public";
        add_header Vary Accept-Encoding;
        
        # Enhanced security for uploads
        location ~* \.(php|php3|php4|php5|phtml|pl|py|jsp|asp|sh|cgi|exe|bat|cmd|com|pif|scr|vbs|vbe|js|jar)$ {
            deny all;
        }
    }
    
    # API routes with enhanced rate limiting
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        proxy_connect_timeout 60s;
    }
    
    # Login endpoint with stricter rate limiting
    location /api/auth/login {
        limit_req zone=login burst=3 nodelay;
        
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Upload endpoints with specific rate limiting
    location /api/upload {
        limit_req zone=upload burst=5 nodelay;
        
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }
    
    # Main application proxy with latest optimizations
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
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        proxy_connect_timeout 60s;
        
        # Handle WebSocket connections
        proxy_set_header Connection "upgrade";
        proxy_set_header Upgrade $http_upgrade;
    }
    
    # Enhanced error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /usr/share/nginx/html;
    }
    
    # Enhanced security - deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to backup files
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to sensitive files
    location ~* \.(env|log|sql|bak|backup|old|orig|save|swp|tmp)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Enable the site
echo "🔗 Enabling Nginx site..."
sudo ln -sf /etc/nginx/sites-available/course-platform /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# Create enhanced deployment script
echo "📝 Creating enhanced deployment script..."
cat > /var/www/course-platform/deploy.sh << 'EOF'
#!/bin/bash

# Course Platform Deployment Script with Latest Features
# This script handles deployment updates with enhanced features

set -e

echo "🚀 Starting Course Platform deployment with latest technologies..."

# Configuration
APP_DIR="/var/www/course-platform"
BACKUP_BEFORE_DEPLOY=true
RESTART_SERVICES=true
UPDATE_DEPENDENCIES=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please don't run this script as root"
    exit 1
fi

# Navigate to application directory
cd $APP_DIR

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    print_warning "Please copy env.example to .env and configure your environment variables"
    exit 1
fi

# Create backup before deployment
if [ "$BACKUP_BEFORE_DEPLOY" = true ]; then
    print_status "Creating backup before deployment..."
    ./backup.sh
fi

# Pull latest changes
print_status "Pulling latest changes from repository..."
git fetch origin
git reset --hard origin/main

# Update dependencies if needed
if [ "$UPDATE_DEPENDENCIES" = true ]; then
    print_status "Updating dependencies to latest versions..."
    npm ci --only=production
    
    # Update global packages
    print_info "Updating global packages..."
    sudo npm update -g pm2
fi

# Check if PM2 is running
if pm2 list | grep -q "course-platform"; then
    print_status "Restarting application with PM2..."
    pm2 restart course-platform
else
    print_status "Starting application with PM2..."
    pm2 start ecosystem.config.js --env production
fi

# Save PM2 configuration
pm2 save

# Check application health
print_status "Checking application health..."
sleep 5

# Test health endpoint
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    print_status "Application health check passed"
else
    print_error "Application health check failed!"
    print_status "Checking application logs..."
    pm2 logs course-platform --lines 20
    exit 1
fi

# Restart Nginx if needed
if [ "$RESTART_SERVICES" = true ]; then
    print_status "Reloading Nginx configuration..."
    sudo nginx -t && sudo systemctl reload nginx
fi

# Show deployment status
print_status "Deployment completed successfully!"
echo ""
print_status "Application Status:"
pm2 status course-platform
echo ""
print_status "Recent logs:"
pm2 logs course-platform --lines 10
echo ""
print_info "Technology versions:"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "PM2: $(pm2 --version)"
echo "MongoDB: $(mongod --version | head -n 1)"
echo "Nginx: $(nginx -v 2>&1)"
echo ""
print_status "Your application is available at: https://e-dars.uz"
EOF

chmod +x /var/www/course-platform/deploy.sh

# Create enhanced backup script
echo "📝 Creating enhanced backup script..."
cat > /var/www/course-platform/backup.sh << 'EOF'
#!/bin/bash

set -e

BACKUP_DIR="/var/backups/course-platform"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_$DATE"

echo "💾 Starting enhanced backup..."

# Create backup directory
sudo mkdir -p $BACKUP_DIR

# Backup MongoDB with latest features
echo "📊 Backing up MongoDB..."
mongodump --out $BACKUP_DIR/$BACKUP_NAME/mongodb --gzip

# Backup application files
echo "📁 Backing up application files..."
sudo tar -czf $BACKUP_DIR/$BACKUP_NAME/app.tar.gz -C /var/www course-platform

# Backup logs
echo "📋 Backing up logs..."
sudo tar -czf $BACKUP_DIR/$BACKUP_NAME/logs.tar.gz -C /var/log course-platform

# Backup configuration files
echo "⚙️ Backing up configuration files..."
sudo tar -czf $BACKUP_DIR/$BACKUP_NAME/config.tar.gz -C /etc nginx/sites-available/course-platform mongod.conf

# Create backup archive
echo "📦 Creating backup archive..."
cd $BACKUP_DIR
sudo tar -czf $BACKUP_NAME.tar.gz $BACKUP_NAME
sudo rm -rf $BACKUP_NAME

# Keep only last 7 backups
echo "🧹 Cleaning old backups..."
ls -t $BACKUP_DIR/backup_*.tar.gz | tail -n +8 | xargs -r sudo rm

echo "✅ Enhanced backup completed: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
EOF

chmod +x /var/www/course-platform/backup.sh

# Create enhanced restore script
echo "📝 Creating enhanced restore script..."
cat > /var/www/course-platform/restore.sh << 'EOF'
#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 backup_20231201_120000.tar.gz"
    exit 1
fi

BACKUP_FILE="/var/backups/course-platform/$1"
RESTORE_DIR="/tmp/restore_$(date +%Y%m%d_%H%M%S)"

echo "🔄 Starting enhanced restore from $BACKUP_FILE..."

# Extract backup
echo "📦 Extracting backup..."
mkdir -p $RESTORE_DIR
sudo tar -xzf $BACKUP_FILE -C $RESTORE_DIR

# Stop application
echo "⏹️ Stopping application..."
pm2 stop course-platform

# Restore MongoDB
echo "📊 Restoring MongoDB..."
mongorestore --gzip $RESTORE_DIR/*/mongodb

# Restore application files
echo "📁 Restoring application files..."
sudo tar -xzf $RESTORE_DIR/*/app.tar.gz -C /var

# Restore logs
echo "📋 Restoring logs..."
sudo tar -xzf $RESTORE_DIR/*/logs.tar.gz -C /var

# Restore configuration files
echo "⚙️ Restoring configuration files..."
sudo tar -xzf $RESTORE_DIR/*/config.tar.gz -C /etc

# Start application
echo "▶️ Starting application..."
pm2 start course-platform

# Cleanup
rm -rf $RESTORE_DIR

echo "✅ Enhanced restore completed successfully!"
EOF

chmod +x /var/www/course-platform/restore.sh

# Create enhanced monitoring script
echo "📝 Creating enhanced monitoring script..."
cat > /var/www/course-platform/monitor.sh << 'EOF'
#!/bin/bash

echo "📊 Course Platform Enhanced Monitoring Report"
echo "============================================="
echo "Date: $(date)"
echo ""

# System status with latest tools
echo "🖥️ System Status:"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Technology versions
echo "🔧 Technology Versions:"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "PM2: $(pm2 --version)"
echo "MongoDB: $(mongod --version | head -n 1)"
echo "Nginx: $(nginx -v 2>&1)"
echo ""

# Application status
echo "🚀 Application Status:"
pm2 status
echo ""

# MongoDB status
echo "📊 MongoDB Status:"
sudo systemctl status mongod --no-pager -l
echo ""

# Nginx status
echo "🌐 Nginx Status:"
sudo systemctl status nginx --no-pager -l
echo ""

# Network connections
echo "🌐 Network Connections:"
echo "Active connections: $(ss -tuln | grep LISTEN | wc -l)"
echo ""

# Recent logs
echo "📋 Recent Application Logs:"
tail -n 20 /var/log/course-platform/combined.log
EOF

chmod +x /var/www/course-platform/monitor.sh

# Set up enhanced log rotation
echo "📋 Setting up enhanced log rotation..."
sudo tee /etc/logrotate.d/course-platform << 'EOF'
/var/log/course-platform/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        pm2 reloadLogs
    endscript
    dateext
    dateformat -%Y%m%d
}
EOF

# Create systemd service for PM2 startup
echo "⚙️ Setting up PM2 startup service..."
pm2 startup systemd
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp /home/$USER

# Final instructions
echo ""
echo "🎉 Enhanced server setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Clone your repository to /var/www/course-platform"
echo "2. Copy env.example to .env and configure your environment variables"
echo "3. Run: cd /var/www/course-platform && npm install"
echo "4. Run: pm2 start ecosystem.config.js --env production"
echo "5. Set up SSL certificate: sudo certbot --nginx -d e-dars.uz -d www.e-dars.uz"
echo "6. Configure your domain DNS to point to this server's IP"
echo ""
echo "📚 Useful commands:"
echo "- Deploy updates: ./deploy.sh"
echo "- Monitor system: ./monitor.sh"
echo "- Create backup: ./backup.sh"
echo "- Restore backup: ./restore.sh <backup_file>"
echo "- View logs: pm2 logs course-platform"
echo "- Restart app: pm2 restart course-platform"
echo ""
echo "🔒 Security notes:"
echo "- Change default SSH port"
echo "- Set up fail2ban"
echo "- Configure firewall rules"
echo "- Keep system updated regularly"
echo ""
echo "🚀 Latest Technologies Installed:"
echo "- Node.js 20.x (Latest LTS)"
echo "- MongoDB 8.0 (Latest stable)"
echo "- PM2 (Latest version)"
echo "- Nginx (Latest from Ubuntu repos)"
echo "- Certbot (Latest version)"
echo "- Enhanced security features"
echo "- Latest SSL/TLS configurations" 