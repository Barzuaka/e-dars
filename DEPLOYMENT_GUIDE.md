# Course Platform Deployment Guide

This guide provides a robust deployment strategy for your course platform on DigitalOcean with zero-downtime updates and database safety.

## 🚀 Quick Start

### 1. Create DigitalOcean Droplet

1. **Create a new droplet:**
   - Choose Ubuntu 22.04 LTS
   - Select plan: Basic → Regular → $6/month (1GB RAM, 1 CPU, 25GB SSD)
   - Choose datacenter region close to your users
   - Add your SSH key
   - Choose a hostname (e.g., `course-platform-prod`)

2. **Connect to your droplet:**
   ```bash
   ssh root@your-droplet-ip
   ```

### 2. Initial Server Setup

Run the setup script on your fresh droplet:

```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/your-repo/course-platform/main/setup-digitalocean.sh | bash
```

This script will:
- Update system packages
- Install Docker, Nginx, Node.js, PM2
- Configure firewall
- Set up monitoring and backup scripts
- Create necessary directories

### 3. Configure Environment Variables

1. **Create your `.env` file:**
   ```bash
   cp /opt/course-platform/.env.template /opt/course-platform/.env
   nano /opt/course-platform/.env
   ```

2. **Fill in your actual values:**
   ```env
   # Database Configuration
   MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/course-platform?retryWrites=true&w=majority
   
   # Session Configuration
   SESSION_SECRET=your-super-secure-random-string-here
   
   # Admin Configuration
   ADMIN_EMAIL=admin@yourdomain.com
   ADMIN_PASSWORD=your-secure-admin-password
   
   # Telegram Configuration (optional)
   TELEGRAM_BOT_TOKEN=your-telegram-bot-token
   TELEGRAM_CHAT_ID=your-telegram-chat-id
   
   # Bunny Storage Configuration (optional)
   BUNNY_STORAGE_ZONE=your-bunny-storage-zone
   BUNNY_API_KEY=your-bunny-api-key
   
   # Environment
   NODE_ENV=production
   PORT=3001
   ```

### 4. Deploy Your Application

#### Option A: Docker Deployment (Recommended)

1. **Copy your application files:**
   ```bash
   # From your local machine
   rsync -avz --exclude 'node_modules' --exclude '.git' --exclude 'uploads' ./ root@your-droplet-ip:/opt/course-platform/
   ```

2. **Start with Docker Compose:**
   ```bash
   cd /opt/course-platform
   docker-compose up -d
   ```

#### Option B: Direct Node.js Deployment

1. **Copy your application files:**
   ```bash
   # From your local machine
   rsync -avz --exclude 'node_modules' --exclude '.git' --exclude 'uploads' ./ root@your-droplet-ip:/opt/course-platform/
   ```

2. **Install dependencies and start:**
   ```bash
   cd /opt/course-platform
   npm install --production
   systemctl start course-platform
   systemctl enable course-platform
   ```

### 5. Configure Domain and SSL

1. **Point your domain to the droplet IP**

2. **Update Nginx configuration:**
   ```bash
   nano /etc/nginx/sites-available/course-platform
   ```
   Replace `your-domain.com` with your actual domain

3. **Test and reload Nginx:**
   ```bash
   nginx -t
   systemctl reload nginx
   ```

4. **Set up SSL certificate:**
   ```bash
   certbot --nginx -d your-domain.com -d www.your-domain.com
   ```

## 🔄 Deployment Strategies

### Strategy 1: Zero-Downtime Deployment (Recommended)

Use the provided deployment script:

```bash
# From your local machine
./deploy.sh deploy
```

This script will:
- Create a backup before deployment
- Copy new code to server
- Build and deploy with Docker
- Verify health check
- Rollback automatically if deployment fails

### Strategy 2: Blue-Green Deployment

For even safer deployments:

1. **Set up two identical environments**
2. **Deploy to inactive environment**
3. **Test thoroughly**
4. **Switch traffic to new environment**
5. **Keep old environment as backup**

### Strategy 3: Rolling Updates

For Docker Swarm or Kubernetes:
```bash
docker service update --image your-app:new-version course-platform
```

## 🛡️ Database Safety

### MongoDB Atlas (Recommended)

1. **Use MongoDB Atlas for production:**
   - Automatic backups
   - Point-in-time recovery
   - Global distribution
   - Built-in security

2. **Connection string format:**
   ```
   mongodb+srv://username:password@cluster.mongodb.net/course-platform?retryWrites=true&w=majority
   ```

### Local MongoDB (Alternative)

If using local MongoDB:

1. **Set up MongoDB:**
   ```bash
   docker run -d --name mongodb \
     -p 27017:27017 \
     -v mongodb_data:/data/db \
     -e MONGO_INITDB_ROOT_USERNAME=admin \
     -e MONGO_INITDB_ROOT_PASSWORD=password \
     mongo:6
   ```

2. **Regular backups:**
   ```bash
   # Manual backup
   docker exec mongodb mongodump --out /backup
   
   # Automated backup (already configured in setup script)
   # Runs daily at 2 AM
   ```

## 📊 Monitoring and Maintenance

### Health Checks

The application includes a health check endpoint:
```bash
curl https://your-domain.com/health
```

### Monitoring Scripts

Automated monitoring is already set up:
- **Application health:** Every 5 minutes
- **System resources:** Disk and memory usage
- **Auto-restart:** If application goes down

### Log Management

View logs:
```bash
# Application logs
journalctl -u course-platform -f

# Docker logs
docker-compose logs -f

# Nginx logs
tail -f /var/log/nginx/access.log

# Monitor logs
tail -f /var/log/course-platform/monitor.log
```

### Backup Management

Backups are automatically created:
- **Application backups:** Daily at 2 AM
- **Database backups:** If using local MongoDB
- **Retention:** Last 7 backups kept

Manual backup:
```bash
/opt/backup.sh
```

## 🔧 Update Procedures

### Safe Update Process

1. **Create backup:**
   ```bash
   ./deploy.sh backup
   ```

2. **Deploy new version:**
   ```bash
   ./deploy.sh deploy
   ```

3. **Verify deployment:**
   ```bash
   ./deploy.sh status
   ```

4. **Monitor logs:**
   ```bash
   ./deploy.sh logs
   ```

### Rollback Procedure

If something goes wrong:
```bash
./deploy.sh rollback
```

### Dependency Updates

Update dependencies safely:
```bash
./deploy.sh update-deps
```

## 🔒 Security Best Practices

### 1. Environment Variables
- Never commit `.env` files to git
- Use strong, unique secrets
- Rotate secrets regularly

### 2. Firewall Configuration
- Only allow necessary ports (22, 80, 443)
- Use fail2ban for SSH protection
- Regular security updates

### 3. SSL/TLS
- Always use HTTPS in production
- Enable HSTS headers
- Regular certificate renewal

### 4. Database Security
- Use connection strings with authentication
- Enable network access restrictions
- Regular security audits

## 🚨 Troubleshooting

### Common Issues

1. **Application won't start:**
   ```bash
   # Check logs
   journalctl -u course-platform -f
   
   # Check environment variables
   systemctl show course-platform --property=Environment
   ```

2. **Nginx errors:**
   ```bash
   # Test configuration
   nginx -t
   
   # Check error logs
   tail -f /var/log/nginx/error.log
   ```

3. **Database connection issues:**
   ```bash
   # Test MongoDB connection
   node -e "require('mongoose').connect(process.env.MONGO_URI).then(() => console.log('Connected')).catch(console.error)"
   ```

4. **SSL certificate issues:**
   ```bash
   # Renew certificate
   certbot renew
   
   # Check certificate status
   certbot certificates
   ```

### Performance Optimization

1. **Enable gzip compression** (already configured)
2. **Use CDN for static assets**
3. **Implement caching strategies**
4. **Monitor and optimize database queries**

## 📈 Scaling Considerations

### Vertical Scaling
- Upgrade droplet size as needed
- Monitor resource usage
- Set up alerts for high usage

### Horizontal Scaling
- Use load balancer
- Multiple application instances
- Database read replicas

### CDN Integration
- Use Cloudflare or Bunny CDN
- Cache static assets
- Reduce server load

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to DigitalOcean

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Deploy to DigitalOcean
        uses: appleboy/ssh-action@v0.1.5
        with:
          host: ${{ secrets.DROPLET_IP }}
          username: ${{ secrets.DROPLET_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/course-platform
            git pull origin main
            docker-compose down
            docker-compose build --no-cache
            docker-compose up -d
```

## 📞 Support and Maintenance

### Regular Maintenance Tasks

1. **Weekly:**
   - Check application logs
   - Monitor resource usage
   - Review security updates

2. **Monthly:**
   - Update dependencies
   - Review backup integrity
   - Performance analysis

3. **Quarterly:**
   - Security audit
   - SSL certificate renewal
   - Infrastructure review

### Emergency Contacts

- **Server access:** SSH to droplet
- **Application logs:** `/var/log/course-platform/`
- **Backup location:** `/backups/`
- **Health check:** `https://your-domain.com/health`

---

This deployment strategy ensures your course platform runs reliably with safe, zero-downtime updates and comprehensive monitoring. 