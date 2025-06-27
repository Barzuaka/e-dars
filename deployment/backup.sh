#!/bin/bash

# E-Dars Backup Script
# Run this on the server to backup database and uploads

set -e

BACKUP_DIR="/var/backups/e-dars"
DATE=$(date +%Y%m%d_%H%M%S)

echo "💾 Creating backup for E-Dars..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup MongoDB
echo "🗄️ Backing up MongoDB..."
mongodump --db e-dars --out $BACKUP_DIR/mongodb_$DATE

# Backup uploads directory
echo "📁 Backing up uploads..."
if [ -d "/var/www/e-dars/public/uploads" ]; then
    tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz -C /var/www/e-dars/public uploads
fi

# Backup application files (excluding node_modules)
echo "📦 Backing up application files..."
cd /var/www/e-dars
tar --exclude='node_modules' --exclude='backup' -czf $BACKUP_DIR/app_$DATE.tar.gz .

# Create backup info file
cat > $BACKUP_DIR/backup_info_$DATE.txt << EOF
Backup created: $(date)
Application: E-Dars Course Platform
Server: $(hostname)
Backup contents:
- MongoDB database
- Upload files
- Application source code

To restore:
1. MongoDB: mongorestore --db e-dars $BACKUP_DIR/mongodb_$DATE/e-dars/
2. Uploads: tar -xzf $BACKUP_DIR/uploads_$DATE.tar.gz -C /var/www/e-dars/public/
3. App: tar -xzf $BACKUP_DIR/app_$DATE.tar.gz -C /var/www/e-dars/
EOF

# Keep only last 7 backups
echo "🧹 Cleaning old backups (keeping last 7)..."
cd $BACKUP_DIR
ls -t | tail -n +8 | xargs -r rm -rf

echo "✅ Backup completed successfully!"
echo "📁 Backup location: $BACKUP_DIR"
echo "📊 Backup size: $(du -sh $BACKUP_DIR | cut -f1)" 