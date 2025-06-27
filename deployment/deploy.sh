#!/bin/bash

# Course Platform Deployment Script
# This script handles deployment updates

set -e

echo "🚀 Starting Course Platform deployment..."

# Configuration
APP_DIR="/var/www/course-platform"
BACKUP_BEFORE_DEPLOY=true
RESTART_SERVICES=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Install dependencies
print_status "Installing dependencies..."
npm ci --only=production

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
print_status "Your application is available at: https://e-dars.uz" 