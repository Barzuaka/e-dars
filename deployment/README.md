# Course Platform Deployment Guide

This guide provides step-by-step instructions for deploying the Course Platform to Digital Ocean with a robust, secure, and scalable setup.

## 🚀 Quick Start

### Prerequisites
- A fresh Ubuntu 22.04 LTS Digital Ocean droplet
- Domain name (e-dars.uz) configured to point to your droplet
- SSH access to your droplet
- Git repository with your course platform code

### 1. Initial Server Setup

Connect to your droplet and run the setup script:

```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/your-repo/course-platform/main/deployment/setup-digitalocean.sh | bash
```

Or manually copy and run the setup script:

```bash
# Copy the setup script to your server
scp deployment/setup-digitalocean.sh root@your-server-ip:/tmp/
ssh root@your-server-ip "chmod +x /tmp/setup-digitalocean.sh && /tmp/setup-digitalocean.sh"
```

### 2. Clone Your Repository

```bash
# SSH into your server
ssh your-username@your-server-ip

# Clone your repository
cd /var/www
git clone https://github.com/your-username/course-platform.git
cd course-platform
```

### 3. Configure Environment Variables

```bash
# Copy the environment template
cp env.example .env

# Edit the environment file
nano .env
```

Configure the following variables in your `.env` file:

```env
# Database Configuration
MONGO_URI=mongodb://localhost:27017/course_platform

# Session Configuration
SESSION_SECRET=your-super-secret-session-key-here

# Admin User Configuration
ADMIN_EMAIL=admin@e-dars.uz
ADMIN_PASSWORD=your-secure-admin-password

# Server Configuration
PORT=3001
NODE_ENV=production

# Domain Configuration
DOMAIN=e-dars.uz
PROTOCOL=https
```

### 4. Install Dependencies and Start Application

```bash
# Install dependencies
npm ci --only=production

# Start the application with PM2
pm2 start ecosystem.config.js --env production

# Save PM2 configuration
pm2 save

# Check application status
pm2 status
```

### 5. Set Up SSL Certificate

```bash
# Install SSL certificate using Let's Encrypt
sudo certbot --nginx -d e-dars.uz -d www.e-dars.uz

# Test automatic renewal
sudo certbot renew --dry-run
```

### 6. Configure Domain DNS

In your domain registrar's DNS settings, add these records:

```
Type: A
Name: @
Value: your-server-ip

Type: A
Name: www
Value: your-server-ip
```

## 🔒 Security Setup

Run the security setup script for additional protection:

```bash
# Run security setup
sudo bash deployment/security-setup.sh
```

This will install and configure:
- Fail2ban for intrusion prevention
- UFW firewall
- Automatic security updates
- Rkhunter for rootkit detection
- ClamAV antivirus
- SSH security hardening

## 📦 Deployment Process

### Initial Deployment

1. **Server Setup**: Run the setup script
2. **Code Deployment**: Clone your repository
3. **Environment Configuration**: Set up `.env` file
4. **Dependencies**: Install Node.js packages
5. **Database**: MongoDB is automatically installed
6. **Application Start**: Start with PM2
7. **SSL Setup**: Configure HTTPS
8. **Security**: Run security hardening

### Ongoing Deployments

For future updates, use the deployment script:

```bash
# Navigate to application directory
cd /var/www/course-platform

# Run deployment
./deploy.sh
```

Or manually:

```bash
# Pull latest changes
git pull origin main

# Install dependencies
npm ci --only=production

# Restart application
pm2 restart course-platform
```

## 🛠️ Management Commands

### Application Management

```bash
# Check application status
pm2 status

# View logs
pm2 logs course-platform

# Restart application
pm2 restart course-platform

# Stop application
pm2 stop course-platform

# Start application
pm2 start course-platform
```

### System Monitoring

```bash
# Check system status
./monitor.sh

# Security check
sudo /usr/local/bin/security-check

# Check disk space
df -h

# Check memory usage
free -h

# Check running processes
htop
```

### Backup and Restore

```bash
# Create backup
./backup.sh

# Create encrypted backup
sudo /usr/local/bin/secure-backup

# Restore from backup
./restore.sh backup_20231201_120000.tar.gz
```

### Log Management

```bash
# View application logs
tail -f /var/log/course-platform/combined.log

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# View system logs
sudo journalctl -u nginx -f
sudo journalctl -u mongod -f
```

## 🔧 Configuration Files

### Nginx Configuration
- Location: `/etc/nginx/sites-available/course-platform`
- Features: SSL, compression, rate limiting, security headers
- Static file serving with caching

### PM2 Configuration
- Location: `/var/www/course-platform/ecosystem.config.js`
- Features: Cluster mode, auto-restart, log management
- Memory limits and health checks

### MongoDB Configuration
- Location: `/etc/mongod.conf`
- Features: Authentication, logging, performance tuning

## 📊 Monitoring and Alerts

### Health Checks

The application includes a health check endpoint:
```
GET https://e-dars.uz/health
```

### Automated Monitoring

- **System Monitoring**: CPU, memory, disk usage
- **Application Monitoring**: PM2 process status
- **Security Monitoring**: Failed login attempts, suspicious activities
- **SSL Certificate**: Expiry monitoring

### Log Rotation

Logs are automatically rotated:
- Application logs: Daily rotation, 30 days retention
- Security logs: Weekly rotation, 12 weeks retention
- Nginx logs: Daily rotation, 30 days retention

## 🚨 Troubleshooting

### Common Issues

1. **Application won't start**
   ```bash
   # Check logs
   pm2 logs course-platform
   
   # Check environment variables
   cat .env
   
   # Check MongoDB connection
   mongo --eval "db.adminCommand('ping')"
   ```

2. **SSL certificate issues**
   ```bash
   # Check certificate status
   sudo certbot certificates
   
   # Renew certificate
   sudo certbot renew
   
   # Check Nginx configuration
   sudo nginx -t
   ```

3. **Database connection issues**
   ```bash
   # Check MongoDB status
   sudo systemctl status mongod
   
   # Check MongoDB logs
   sudo journalctl -u mongod -f
   
   # Test connection
   mongo course_platform --eval "db.stats()"
   ```

4. **High memory usage**
   ```bash
   # Check memory usage
   free -h
   
   # Check PM2 memory usage
   pm2 monit
   
   # Restart application
   pm2 restart course-platform
   ```

### Performance Optimization

1. **Enable Nginx caching**
2. **Optimize MongoDB queries**
3. **Use CDN for static assets**
4. **Implement database indexing**
5. **Monitor and adjust PM2 cluster size**

## 🔄 Update Process

### Regular Updates

1. **Security Updates**: Automatic via unattended-upgrades
2. **Application Updates**: Manual via deploy script
3. **System Updates**: Weekly via cron jobs

### Major Updates

1. **Create backup**: `./backup.sh`
2. **Test in staging**: Use separate environment
3. **Deploy to production**: `./deploy.sh`
4. **Monitor**: Check logs and performance
5. **Rollback if needed**: Use backup restore

## 📞 Support

For deployment issues:

1. Check the logs: `pm2 logs course-platform`
2. Verify configuration: `nginx -t`
3. Test connectivity: `curl -I https://e-dars.uz/health`
4. Check system resources: `./monitor.sh`

## 🔐 Security Checklist

- [ ] SSL certificate installed and auto-renewing
- [ ] Firewall configured (UFW)
- [ ] Fail2ban active
- [ ] SSH key authentication only
- [ ] Automatic security updates enabled
- [ ] Regular backups scheduled
- [ ] Monitoring and alerting configured
- [ ] Strong passwords and session secrets
- [ ] Rate limiting configured
- [ ] Security headers implemented

## 📈 Scaling Considerations

### Vertical Scaling
- Increase droplet size for more CPU/memory
- Optimize MongoDB configuration
- Add more PM2 instances

### Horizontal Scaling
- Use load balancer with multiple droplets
- Implement MongoDB replica sets
- Use external file storage (S3, Bunny.net)

### Performance Monitoring
- Monitor response times
- Track database query performance
- Monitor resource usage
- Set up alerting for thresholds 