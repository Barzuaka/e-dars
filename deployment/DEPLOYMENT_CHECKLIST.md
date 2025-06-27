# Course Platform Deployment Checklist

## 🚀 Pre-Deployment Checklist

### Server Requirements
- [ ] Fresh Ubuntu 22.04 LTS Digital Ocean droplet
- [ ] Minimum 2GB RAM, 2 vCPUs, 50GB SSD
- [ ] Domain name (e-dars.uz) configured
- [ ] SSH access to droplet
- [ ] Git repository ready

### Domain Configuration
- [ ] Domain DNS A record pointing to server IP
- [ ] www subdomain configured
- [ ] DNS propagation completed (can take up to 48 hours)

## 📋 Deployment Steps

### Step 1: Initial Server Setup
- [ ] SSH into your droplet: `ssh root@your-server-ip`
- [ ] Run setup script: `bash deployment/setup-digitalocean.sh`
- [ ] Verify all services installed:
  - [ ] Node.js 18.x
  - [ ] MongoDB 7.0
  - [ ] PM2
  - [ ] Nginx
  - [ ] Certbot

### Step 2: Application Deployment
- [ ] Clone repository: `git clone https://github.com/your-repo/course-platform.git /var/www/course-platform`
- [ ] Navigate to app: `cd /var/www/course-platform`
- [ ] Copy environment template: `cp env.example .env`
- [ ] Configure environment variables in `.env`:
  - [ ] `MONGO_URI=mongodb://localhost:27017/course_platform`
  - [ ] `SESSION_SECRET=your-super-secret-key`
  - [ ] `ADMIN_EMAIL=admin@e-dars.uz`
  - [ ] `ADMIN_PASSWORD=secure-password`
  - [ ] `NODE_ENV=production`
  - [ ] `DOMAIN=e-dars.uz`
  - [ ] `PROTOCOL=https`

### Step 3: Application Setup
- [ ] Install dependencies: `npm ci --only=production`
- [ ] Start application: `pm2 start ecosystem.config.js --env production`
- [ ] Save PM2 config: `pm2 save`
- [ ] Verify app is running: `pm2 status`

### Step 4: SSL Certificate
- [ ] Install SSL: `sudo certbot --nginx -d e-dars.uz -d www.e-dars.uz`
- [ ] Test renewal: `sudo certbot renew --dry-run`
- [ ] Verify HTTPS redirect works

### Step 5: Security Setup
- [ ] Run security script: `sudo bash deployment/security-setup.sh`
- [ ] Configure SSH key authentication
- [ ] Test fail2ban: `sudo fail2ban-client status`
- [ ] Verify firewall: `sudo ufw status`

## ✅ Post-Deployment Verification

### Application Health
- [ ] Website loads: `https://e-dars.uz`
- [ ] Health check: `https://e-dars.uz/health`
- [ ] Admin login works
- [ ] File uploads work
- [ ] Database operations work

### Security Verification
- [ ] HTTPS redirect works
- [ ] HTTP requests redirect to HTTPS
- [ ] Security headers present
- [ ] Rate limiting active
- [ ] Fail2ban monitoring

### Performance Check
- [ ] Page load times < 3 seconds
- [ ] Static files served with caching
- [ ] Gzip compression active
- [ ] PM2 cluster mode working
- [ ] Memory usage reasonable

### Monitoring Setup
- [ ] Log rotation configured
- [ ] Backup system working
- [ ] Monitoring scripts accessible
- [ ] Alert system configured

## 🔧 Configuration Files

### Nginx Configuration
- [ ] File: `/etc/nginx/sites-available/course-platform`
- [ ] Symlink: `/etc/nginx/sites-enabled/course-platform`
- [ ] SSL configuration added by Certbot
- [ ] Security headers implemented
- [ ] Rate limiting configured
- [ ] Static file caching enabled

### PM2 Configuration
- [ ] File: `/var/www/course-platform/ecosystem.config.js`
- [ ] Cluster mode enabled
- [ ] Auto-restart configured
- [ ] Log management set up
- [ ] Memory limits configured

### MongoDB Configuration
- [ ] Service running: `sudo systemctl status mongod`
- [ ] Database created: `course_platform`
- [ ] Collections accessible
- [ ] Backup system configured

## 📊 Monitoring Commands

### Application Status
```bash
# Check PM2 status
pm2 status

# View application logs
pm2 logs course-platform

# Monitor resources
pm2 monit
```

### System Status
```bash
# Check system resources
./monitor.sh

# Security check
sudo /usr/local/bin/security-check

# Disk usage
df -h

# Memory usage
free -h
```

### Service Status
```bash
# Nginx status
sudo systemctl status nginx

# MongoDB status
sudo systemctl status mongod

# Fail2ban status
sudo fail2ban-client status
```

## 🔄 Update Process

### Regular Updates
- [ ] Create backup: `./backup.sh`
- [ ] Pull changes: `git pull origin main`
- [ ] Install dependencies: `npm ci --only=production`
- [ ] Restart app: `pm2 restart course-platform`
- [ ] Verify health: `curl https://e-dars.uz/health`

### Automated Deployment
- [ ] Use deploy script: `./deploy.sh`
- [ ] Script includes backup and health checks
- [ ] Automatic rollback on failure

## 🚨 Troubleshooting

### Common Issues
- [ ] Application won't start → Check logs: `pm2 logs course-platform`
- [ ] SSL issues → Check cert: `sudo certbot certificates`
- [ ] Database issues → Check MongoDB: `sudo systemctl status mongod`
- [ ] High memory → Monitor: `pm2 monit`

### Emergency Procedures
- [ ] Stop application: `pm2 stop course-platform`
- [ ] Restore from backup: `./restore.sh backup_file.tar.gz`
- [ ] Rollback code: `git reset --hard HEAD~1`
- [ ] Restart services: `sudo systemctl restart nginx mongod`

## 📞 Support Information

### Log Locations
- Application logs: `/var/log/course-platform/`
- Nginx logs: `/var/log/nginx/`
- System logs: `/var/log/syslog`
- Security logs: `/var/log/auth.log`

### Important Files
- Environment: `/var/www/course-platform/.env`
- PM2 config: `/var/www/course-platform/ecosystem.config.js`
- Nginx config: `/etc/nginx/sites-available/course-platform`
- Backup location: `/var/backups/course-platform/`

### Contact Information
- Server IP: [Your Server IP]
- Domain: e-dars.uz
- Admin email: admin@e-dars.uz
- SSH access: `ssh your-username@your-server-ip`

## 🔐 Security Checklist

### SSL/TLS
- [ ] SSL certificate installed and valid
- [ ] Auto-renewal configured
- [ ] HTTPS redirect working
- [ ] Security headers implemented

### Firewall & Access
- [ ] UFW firewall active
- [ ] Only necessary ports open
- [ ] SSH key authentication only
- [ ] Root login disabled

### Monitoring & Alerts
- [ ] Fail2ban active
- [ ] Security monitoring configured
- [ ] Backup system working
- [ ] Log monitoring active

### Application Security
- [ ] Strong session secrets
- [ ] Rate limiting active
- [ ] Input validation working
- [ ] File upload security

## 📈 Performance Optimization

### Current Settings
- [ ] PM2 cluster mode: max instances
- [ ] Nginx gzip compression
- [ ] Static file caching
- [ ] Database indexing

### Future Optimizations
- [ ] CDN for static assets
- [ ] Database query optimization
- [ ] Image compression
- [ ] Caching strategies

## ✅ Final Verification

Before going live:
- [ ] All functionality tested
- [ ] Security measures active
- [ ] Monitoring systems working
- [ ] Backup system tested
- [ ] SSL certificate valid
- [ ] Domain resolving correctly
- [ ] Performance acceptable
- [ ] Documentation complete

---

**Deployment Date:** _______________
**Deployed By:** _______________
**Server IP:** _______________
**Domain:** e-dars.uz

**Notes:** _______________ 