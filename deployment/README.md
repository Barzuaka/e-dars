# Course Platform Deployment Guide

This guide will help you deploy your course platform to Digital Ocean with minimal configuration.

## Prerequisites

- A fresh Digital Ocean droplet (Ubuntu 22.04 LTS)
- Domain name pointing to your droplet (e-dars.uz → 167.172.186.30)
- GitHub repository with your code

## Quick Deployment

### 1. Initial Server Setup

SSH into your Digital Ocean droplet and run:

```bash

# Download and run the setup script
curl -sSL https://raw.githubusercontent.com/Barzuaka/e-dars/main/deployment/quick-deploy.sh | bash


### 2. Configure Environment Variables

Create the `.env` file:

```bash
cd /var/www/course-platform
cp deployment/env.example .env
nano .env
```

Update the following variables:
- `MONGO_URI`: `mongodb://localhost:27017/course-platform`
- `SESSION_SECRET`: Generate a random string
- `ADMIN_EMAIL`: Your admin email
- `ADMIN_PASSWORD`: Secure admin password

### 3. Restart the Application

```bash
sudo systemctl restart course-platform
```

## Future Deployments

For future updates, simply run:

```bash
cd /var/www/course-platform
./deployment/deploy.sh
```

## Useful Commands

### Check Application Status
```bash
sudo systemctl status course-platform
```

### View Application Logs
```bash
sudo journalctl -u course-platform -f
```

### Monitor System Health
```bash
cd /var/www/course-platform
./deployment/monitor.sh
```

### Create Backup
```bash
cd /var/www/course-platform
./deployment/backup.sh
```

### Restart Services
```bash
sudo systemctl restart course-platform
sudo systemctl restart nginx
sudo systemctl restart mongod
```

## File Structure

```
/var/www/course-platform/
├── app.js
├── .env                    # Environment variables
├── deployment/
│   ├── deploy.sh          # Deployment script
│   ├── setup-digitalocean.sh
│   ├── backup.sh          # Backup script
│   ├── monitor.sh         # Health check
│   └── env.example        # Environment template
└── public/
    └── uploads/           # User uploads
```

## Troubleshooting

### Application Not Starting
1. Check logs: `sudo journalctl -u course-platform -f`
2. Verify .env file exists and has correct values
3. Check MongoDB is running: `sudo systemctl status mongod`

### Domain Not Working
1. Verify DNS settings point to 167.172.186.30
2. Check Nginx: `sudo systemctl status nginx`
3. Test locally: `curl http://localhost:3001`

### Database Issues
1. Check MongoDB: `sudo systemctl status mongod`
2. Connect to MongoDB: `mongosh`
3. Check database: `use course-platform; show collections;`

## Security Notes

- Change default admin password after first login
- Keep your .env file secure
- Regularly update your system: `sudo apt update && sudo apt upgrade`
- Monitor logs for suspicious activity

## Backup and Recovery

Backups are stored in `/var/backups/course-platform/` and include:
- MongoDB database dump
- Uploaded files
- Automatic cleanup (keeps last 7 backups)

To restore from backup:
```bash
# Restore database
mongorestore --db course-platform /path/to/backup/dump/course-platform/

# Restore uploads
tar -xzf /path/to/backup/backup_YYYYMMDD_HHMMSS_uploads.tar.gz -C /var/www/course-platform/public/
``` 