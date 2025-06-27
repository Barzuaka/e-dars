#!/bin/bash

# Deployment script for DigitalOcean droplet
# Run this script on your droplet

set -e  # Exit on any error

echo "🚀 Starting deployment of Course Platform..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo "🐳 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create application directory
APP_DIR="/opt/course-platform"
echo "📁 Creating application directory: $APP_DIR"
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Clone the repository (if not already done)
if [ ! -d "$APP_DIR/.git" ]; then
    echo "📥 Cloning repository..."
    cd $APP_DIR
    git clone https://github.com/Barzuaka/e-dars.git .
else
    echo "📥 Updating repository..."
    cd $APP_DIR
    git pull origin main
fi

# Create .env file if it doesn't exist
if [ ! -f "$APP_DIR/.env" ]; then
    echo "⚙️ Creating .env file..."
    cat > $APP_DIR/.env << EOF
# Database Configuration
MONGO_URI=mongodb://localhost:27017/course_platform

# Session Configuration
SESSION_SECRET=your-super-secret-session-key-change-this

# Admin Configuration
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=admin123

# Telegram Bot Configuration (optional)
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
TELEGRAM_CHAT_ID=your-telegram-chat-id

# Bunny Storage Configuration (optional)
BUNNY_STORAGE_ZONE=your-bunny-storage-zone
BUNNY_API_KEY=your-bunny-api-key

# Application Configuration
NODE_ENV=production
PORT=3001
EOF
    echo "⚠️  Please edit $APP_DIR/.env with your actual configuration values"
fi

# Create uploads directory with proper permissions
echo "📁 Setting up uploads directory..."
mkdir -p $APP_DIR/public/uploads/gallery
mkdir -p $APP_DIR/public/uploads/thumbnails
chmod -R 755 $APP_DIR/public/uploads

# Build and start the application
echo "🔨 Building and starting application..."
cd $APP_DIR
docker-compose down || true
docker-compose build --no-cache
docker-compose up -d

# Wait for application to start
echo "⏳ Waiting for application to start..."
sleep 30

# Check if application is running
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    echo "✅ Application is running successfully!"
    echo "🌐 Your application is available at: http://your-domain.com:3001"
else
    echo "❌ Application failed to start. Check logs with: docker-compose logs"
    docker-compose logs
fi

echo "🎉 Deployment completed!"
echo ""
echo "📋 Useful commands:"
echo "  View logs: cd $APP_DIR && docker-compose logs -f"
echo "  Stop app: cd $APP_DIR && docker-compose down"
echo "  Restart app: cd $APP_DIR && docker-compose restart"
echo "  Update app: cd $APP_DIR && git pull && docker-compose up -d --build" 