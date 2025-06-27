# E-Dars Course Platform - GitHub Deployment Guide

This guide uses GitHub for version control and deployment, making it much cleaner and more professional.

## 🚀 **Step-by-Step GitHub Deployment**

### **1. Prepare Your Local Repository**

1. **Initialize Git (if not already done):**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. **Create GitHub Repository:**
   - Go to GitHub.com
   - Create a new repository named `course-platform`
   - Don't initialize with README (you already have one)

3. **Push to GitHub:**
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/course-platform.git
   git branch -M main
   git push -u origin main
   ```

### **2. Initial Server Setup**

1. **Connect to your droplet:**
   ```bash
   ssh root@167.172.186.30
   ```

2. **Copy and run the GitHub setup script:**
   ```bash
   # Copy the setup script to your server
   scp deployment/setup-digitalocean-github.sh root@167.172.186.30:/root/
   
   # On the server, run:
   chmod +x setup-digitalocean-github.sh
   ./setup-digitalocean-github.sh
   ```

3. **Complete PM2 startup setup:**
   The script will show you a command to run. Execute it as shown.

### **3. Deploy from GitHub**

1. **Clone your repository on the server:**
   ```bash
   # On the server
   cd /var/www/e-dars
   git clone https://github.com/YOUR_USERNAME/course-platform.git .
   ```

2. **Configure environment:**
   ```bash
   cp .env.template .env
   nano .env  # Edit with your actual values
   ```

3. **Install dependencies and start:**
   ```bash
   npm install --production
   pm2 start ecosystem.config.js
   ```

4. **Set up SSL:**
   ```bash
   certbot --nginx -d e-dars.uz -d www.e-dars.uz
   ```

### **4. Future Updates (Super Easy!)**

**From your local machine, just run:**
```bash
# Windows
deploy-github.bat

# Linux/Mac
./deployment/deploy-github.sh
```

**Or manually:**
```bash
# Make your changes locally
git add .
git commit -m "Your update message"
git push origin main

# Then on the server
ssh root@167.172.186.30
cd /var/www/e-dars
./deploy-github.sh
```

## 🔧 **What This Setup Includes**

✅ **GitHub Integration** - Version control and easy deployment  
✅ **PM2** - Process manager with auto-restart  
✅ **Nginx** - Reverse proxy with SSL  
✅ **MongoDB** - Local database  
✅ **Let's Encrypt** - Free SSL certificates  
✅ **Automatic Backups** - Before each deployment  
✅ **Health Monitoring** - Built-in status checks  

## 📊 **Management Commands**

**Check Status:**
```bash
pm2 status e-dars
./monitor.sh
```

**View Logs:**
```bash
pm2 logs e-dars
```

**Manual Deployment:**
```bash
# On server
./deploy-github.sh
```

**Backup:**
```bash
./backup.sh
```

## 🔄 **Workflow for Updates**

1. **Make changes locally**
2. **Test your changes**
3. **Run deployment script:**
   ```bash
   # Windows
   deploy-github.bat
   
   # Linux/Mac  
   ./deployment/deploy-github.sh
   ```
4. **Done!** Your app is updated automatically

## 🎯 **Benefits of GitHub Deployment**

✅ **Version Control** - Track all changes  
✅ **Rollback** - Easy to revert to previous versions  
✅ **Collaboration** - Multiple developers can work together  
✅ **Backup** - Your code is safely stored on GitHub  
✅ **Professional** - Industry standard approach  
✅ **CI/CD Ready** - Easy to add automated testing later  

## 🔐 **Security Best Practices**

1. **Use SSH keys** for GitHub access
2. **Don't commit sensitive data** (use .env files)
3. **Add .env to .gitignore**
4. **Use strong passwords** in production
5. **Keep dependencies updated**

## 📝 **.gitignore Setup**

Make sure your `.gitignore` includes:
```
node_modules/
.env
uploads/
*.log
.DS_Store
```

## 🚨 **Troubleshooting**

**If deployment fails:**
```bash
# Check logs
pm2 logs e-dars

# Check git status
git status

# Manual pull
git pull origin main
npm install --production
pm2 restart e-dars
```

**If GitHub access fails:**
```bash
# Set up SSH keys or use HTTPS with token
git remote set-url origin https://YOUR_TOKEN@github.com/YOUR_USERNAME/course-platform.git
```

This GitHub-based approach is **much cleaner, more professional, and easier to maintain** than file uploads! 