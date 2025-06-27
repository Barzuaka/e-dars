#!/bin/bash

# Monitoring script for course-platform
# Usage: ./monitor.sh

echo "🔍 Course Platform Health Check"
echo "================================"

# Check if application service is running
if sudo systemctl is-active --quiet course-platform; then
    echo "✅ Application service: RUNNING"
else
    echo "❌ Application service: STOPPED"
fi

# Check if MongoDB is running
if sudo systemctl is-active --quiet mongod; then
    echo "✅ MongoDB service: RUNNING"
else
    echo "❌ MongoDB service: STOPPED"
fi

# Check if Nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx service: RUNNING"
else
    echo "❌ Nginx service: STOPPED"
fi

# Check application health endpoint
echo ""
echo "🏥 Application Health Check:"
if curl -s http://localhost:3001/health > /dev/null; then
    echo "✅ Health endpoint: RESPONDING"
else
    echo "❌ Health endpoint: NOT RESPONDING"
fi

# Check disk usage
echo ""
echo "💾 Disk Usage:"
df -h / | tail -1

# Check memory usage
echo ""
echo "🧠 Memory Usage:"
free -h

# Check recent application logs
echo ""
echo "📋 Recent Application Logs (last 10 lines):"
sudo journalctl -u course-platform -n 10 --no-pager 