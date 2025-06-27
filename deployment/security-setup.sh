#!/bin/bash

# Security Setup Script for Course Platform
# This script adds additional security measures to the server

set -e

echo "🔒 Starting security setup for Course Platform..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Install fail2ban
echo "📦 Installing fail2ban..."
sudo apt install -y fail2ban

# Configure fail2ban
print_status "Configuring fail2ban..."
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 10

[nginx-botsearch]
enabled = true
filter = nginx-botsearch
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

# Start and enable fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Install and configure UFW firewall
print_status "Configuring UFW firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 3001
sudo ufw --force enable

# Install and configure automatic security updates
print_status "Setting up automatic security updates..."
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Configure automatic security updates
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

# Configure automatic updates
sudo tee /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Install and configure rkhunter for rootkit detection
print_status "Installing rkhunter..."
sudo apt install -y rkhunter
sudo rkhunter --update
sudo rkhunter --propupd

# Create rkhunter cron job
sudo tee /etc/cron.daily/rkhunter << 'EOF'
#!/bin/bash
/usr/bin/rkhunter --cronjob --update --quiet
EOF

sudo chmod +x /etc/cron.daily/rkhunter

# Install and configure ClamAV antivirus
print_status "Installing ClamAV..."
sudo apt install -y clamav clamav-daemon
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam

# Create ClamAV scan script
sudo tee /usr/local/bin/scan-virus << 'EOF'
#!/bin/bash
# Virus scan script for course platform
SCAN_DIR="/var/www/course-platform"
LOG_FILE="/var/log/clamav-scan.log"

echo "Starting virus scan at $(date)" | tee -a $LOG_FILE
clamscan -r --infected --log=$LOG_FILE $SCAN_DIR
echo "Virus scan completed at $(date)" | tee -a $LOG_FILE
EOF

sudo chmod +x /usr/local/bin/scan-virus

# Add ClamAV scan to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/scan-virus") | crontab -

# Configure SSH security
print_status "Configuring SSH security..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# SSH security settings
sudo tee -a /etc/ssh/sshd_config << 'EOF'

# Security settings
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Restart SSH service
sudo systemctl restart ssh

# Create security monitoring script
print_status "Creating security monitoring script..."
sudo tee /usr/local/bin/security-check << 'EOF'
#!/bin/bash

echo "🔒 Security Check Report - $(date)"
echo "=================================="

# Check fail2ban status
echo "📊 Fail2ban Status:"
sudo fail2ban-client status
echo ""

# Check UFW status
echo "🔥 UFW Firewall Status:"
sudo ufw status verbose
echo ""

# Check for failed login attempts
echo "🚫 Recent Failed Login Attempts:"
sudo grep "Failed password" /var/log/auth.log | tail -10
echo ""

# Check for suspicious activities
echo "⚠️ Recent Suspicious Activities:"
sudo grep -i "error\|warning\|failed\|denied" /var/log/nginx/error.log | tail -10
echo ""

# Check disk space
echo "💾 Disk Space:"
df -h
echo ""

# Check memory usage
echo "🧠 Memory Usage:"
free -h
echo ""

# Check running processes
echo "🔄 Top Processes by CPU:"
ps aux --sort=-%cpu | head -10
echo ""

# Check open ports
echo "🔌 Open Ports:"
sudo netstat -tlnp | grep LISTEN
echo ""

# Check SSL certificate expiry
echo "🔐 SSL Certificate Status:"
if [ -f /etc/letsencrypt/live/e-dars.uz/fullchain.pem ]; then
    openssl x509 -in /etc/letsencrypt/live/e-dars.uz/fullchain.pem -text -noout | grep -A 2 "Validity"
else
    echo "SSL certificate not found"
fi
EOF

sudo chmod +x /usr/local/bin/security-check

# Create backup security script
print_status "Creating secure backup script..."
sudo tee /usr/local/bin/secure-backup << 'EOF'
#!/bin/bash

# Secure backup script with encryption
BACKUP_DIR="/var/backups/course-platform"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="secure_backup_$DATE"
ENCRYPTION_KEY="your-encryption-key-here"  # Change this!

echo "🔐 Starting secure backup..."

# Create backup directory
sudo mkdir -p $BACKUP_DIR

# Backup MongoDB with encryption
echo "📊 Backing up MongoDB..."
mongodump --out $BACKUP_DIR/$BACKUP_NAME/mongodb
tar -czf $BACKUP_DIR/$BACKUP_NAME/mongodb.tar.gz -C $BACKUP_DIR/$BACKUP_NAME mongodb

# Encrypt MongoDB backup
openssl enc -aes-256-cbc -salt -in $BACKUP_DIR/$BACKUP_NAME/mongodb.tar.gz -out $BACKUP_DIR/$BACKUP_NAME/mongodb.tar.gz.enc -k $ENCRYPTION_KEY
rm $BACKUP_DIR/$BACKUP_NAME/mongodb.tar.gz

# Backup application files
echo "📁 Backing up application files..."
sudo tar -czf $BACKUP_DIR/$BACKUP_NAME/app.tar.gz -C /var/www course-platform

# Encrypt application backup
openssl enc -aes-256-cbc -salt -in $BACKUP_DIR/$BACKUP_NAME/app.tar.gz -out $BACKUP_DIR/$BACKUP_NAME/app.tar.gz.enc -k $ENCRYPTION_KEY
rm $BACKUP_DIR/$BACKUP_NAME/app.tar.gz

# Create final encrypted archive
cd $BACKUP_DIR
tar -czf $BACKUP_NAME.tar.gz $BACKUP_NAME
openssl enc -aes-256-cbc -salt -in $BACKUP_NAME.tar.gz -out $BACKUP_NAME.tar.gz.enc -k $ENCRYPTION_KEY
rm $BACKUP_NAME.tar.gz
rm -rf $BACKUP_NAME

# Keep only last 5 encrypted backups
ls -t $BACKUP_DIR/secure_backup_*.tar.gz.enc | tail -n +6 | xargs -r sudo rm

echo "✅ Secure backup completed: $BACKUP_DIR/$BACKUP_NAME.tar.gz.enc"
echo "🔑 Remember to keep your encryption key safe!"
EOF

sudo chmod +x /usr/local/bin/secure-backup

# Set up log monitoring
print_status "Setting up log monitoring..."
sudo tee /etc/logrotate.d/course-platform-security << 'EOF'
/var/log/course-platform/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        pm2 reloadLogs
    endscript
}

/var/log/clamav-scan.log {
    weekly
    missingok
    rotate 12
    compress
    notifempty
    create 644 root root
}
EOF

# Create security alert script
print_status "Creating security alert script..."
sudo tee /usr/local/bin/security-alert << 'EOF'
#!/bin/bash

# Security alert script - can be integrated with email or Slack
ALERT_LOG="/var/log/security-alerts.log"

log_alert() {
    echo "$(date): $1" >> $ALERT_LOG
    # Add email notification here if needed
    # echo "$1" | mail -s "Security Alert" admin@e-dars.uz
}

# Check for failed login attempts
FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)
if [ $FAILED_LOGINS -gt 10 ]; then
    log_alert "High number of failed login attempts: $FAILED_LOGINS"
fi

# Check for suspicious file modifications
SUSPICIOUS_FILES=$(find /var/www/course-platform -name "*.php" -mtime -1 2>/dev/null | wc -l)
if [ $SUSPICIOUS_FILES -gt 0 ]; then
    log_alert "Suspicious PHP files detected in uploads directory"
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    log_alert "Disk usage is high: ${DISK_USAGE}%"
fi

echo "Security check completed at $(date)"
EOF

sudo chmod +x /usr/local/bin/security-alert

# Add security alert to crontab
(crontab -l 2>/dev/null; echo "*/30 * * * * /usr/local/bin/security-alert") | crontab -

print_status "Security setup completed!"
echo ""
echo "🔒 Security measures implemented:"
echo "- Fail2ban for intrusion prevention"
echo "- UFW firewall configuration"
echo "- Automatic security updates"
echo "- Rkhunter for rootkit detection"
echo "- ClamAV antivirus scanning"
echo "- SSH security hardening"
echo "- Encrypted backup system"
echo "- Log monitoring and alerts"
echo ""
echo "📋 Next steps:"
echo "1. Set up SSH key authentication"
echo "2. Change the encryption key in /usr/local/bin/secure-backup"
echo "3. Configure email notifications in security-alert script"
echo "4. Run: /usr/local/bin/security-check"
echo "5. Test the backup system: /usr/local/bin/secure-backup"
echo ""
echo "⚠️ Important:"
echo "- Keep your SSH keys safe"
echo "- Regularly update the system"
echo "- Monitor security logs"
echo "- Test your backup and restore procedures" 