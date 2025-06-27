#!/bin/bash

# E-Dars GitHub Deployment Script
# Run this from your local machine to deploy updates via GitHub

set -e

REMOTE_HOST="167.172.186.30"
REMOTE_USER="root"

echo "🚀 Deploying E-Dars via GitHub..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    echo "Please initialize git and push your code to GitHub first"
    exit 1
fi

# Check if there are uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Warning: You have uncommitted changes"
    echo "Current changes:"
    git status --short
    read -p "Do you want to commit these changes? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "Auto-commit before deployment $(date)"
    else
        echo "❌ Deployment cancelled. Please commit your changes first."
        exit 1
    fi
fi

# Push to GitHub
echo "📤 Pushing to GitHub..."
git push origin main

# Trigger deployment on server
echo "🔧 Triggering deployment on server..."
ssh $REMOTE_USER@$REMOTE_HOST << 'EOF'
cd /var/www/e-dars
./deploy-github.sh
EOF

echo "🎉 Deployment completed!"
echo "🌐 Your application should be available at: https://e-dars.uz"
echo "📊 Check logs with: ssh root@167.172.186.30 'pm2 logs e-dars'" 