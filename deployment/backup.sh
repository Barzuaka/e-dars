#!/bin/bash

# Backup script for course-platform
# Usage: ./backup.sh

set -e  # Exit on any error

echo "💾 Starting backup..."

# Create backup directory
BACKUP_DIR="/var/backups/course-platform"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_$DATE"

mkdir -p "$BACKUP_DIR"

# Backup MongoDB database
echo "📦 Backing up MongoDB database..."
mongodump --db course-platform --out "$BACKUP_DIR/$BACKUP_NAME"

# Backup uploads directory
echo "📁 Backing up uploads..."
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_uploads.tar.gz" -C /var/www/course-platform/public uploads/

# Create a combined backup archive
echo "📦 Creating backup archive..."
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}_full.tar.gz" "$BACKUP_NAME" "${BACKUP_NAME}_uploads.tar.gz"

# Clean up temporary files
rm -rf "$BACKUP_NAME" "${BACKUP_NAME}_uploads.tar.gz"

# Keep only last 7 backups
echo "🧹 Cleaning old backups (keeping last 7)..."
ls -t "$BACKUP_DIR"/backup_*_full.tar.gz | tail -n +8 | xargs -r rm

echo "✅ Backup completed: $BACKUP_DIR/${BACKUP_NAME}_full.tar.gz" 