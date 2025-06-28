#!/bin/bash

# Deployment script for course-platform
# Usage: ./deploy.sh

set -e  # Exit on any error

echo "🚀 Starting deployment..."

# Navigate to project directory
cd /var/www/course-platform

# Pull latest changes from GitHub
echo "📥 Pulling latest changes from GitHub..."
git pull origin main

# Install/update dependencies
echo "📦 Installing dependencies..."
# npm install --production

# Create/update .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Please create it manually with your configuration."
    echo "Required environment variables:"
    echo "- MONGO_URI"
    echo "- SESSION_SECRET"
    echo "- ADMIN_EMAIL"
    echo "- ADMIN_PASSWORD"
    echo "- PORT (optional, defaults to 3001)"
fi

# Restart the application
echo "🔄 Restarting application..."
sudo systemctl restart course-platform

# Check if the service is running
if sudo systemctl is-active --quiet course-platform; then
    echo "✅ Deployment successful! Application is running."
    echo "🌐 Your app should be available at: https://e-dars.uz"
else
    echo "❌ Deployment failed! Application is not running."
    echo "Check logs with: sudo journalctl -u course-platform -f"
    exit 1
fi

echo "🎉 Deployment completed!" 