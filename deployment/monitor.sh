#!/bin/bash

# E-Dars Monitoring Script
# Run this to check application health

echo "🔍 E-Dars Application Health Check"
echo "=================================="

# Check if PM2 is running
echo "📊 PM2 Status:"
pm2 status e-dars

echo ""

# Check application logs (last 10 lines)
echo "📋 Recent Application Logs:"
pm2 logs e-dars --lines 10 --nostream

echo ""

# Check MongoDB status
echo "🗄️ MongoDB Status:"
systemctl is-active mongod

echo ""

# Check disk usage
echo "💾 Disk Usage:"
df -h /var/www/e-dars

echo ""

# Check memory usage
echo "🧠 Memory Usage:"
free -h

echo ""

# Check if application is responding
echo "🌐 Application Health Check:"
if curl -f -s http://localhost:3001/health > /dev/null; then
    echo "✅ Application is responding"
    curl -s http://localhost:3001/health | jq . 2>/dev/null || curl -s http://localhost:3001/health
else
    echo "❌ Application is not responding"
fi

echo ""

# Check Nginx status
echo "🌐 Nginx Status:"
systemctl is-active nginx

echo ""

# Check SSL certificate
echo "🔒 SSL Certificate Status:"
if [ -f "/etc/letsencrypt/live/e-dars.uz/fullchain.pem" ]; then
    echo "✅ SSL certificate exists"
    openssl x509 -in /etc/letsencrypt/live/e-dars.uz/fullchain.pem -text -noout | grep "Not After" | head -1
else
    echo "⚠️ SSL certificate not found"
fi 