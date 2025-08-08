#!/bin/bash

# Backup script for Bun Hono application
# Run this script daily to backup your application

BACKUP_DIR="/var/backups/bun-hono"
DATE=$(date +%Y%m%d-%H%M%S)
APP_DIR="/var/www/bun-hono"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

echo "🔄 Starting backup at $(date)..."

# Backup application files
echo "📦 Backing up application files..."
tar -czf $BACKUP_DIR/app-$DATE.tar.gz -C /var/www bun-hono

# Backup environment file
echo "🔧 Backing up environment file..."
cp $APP_DIR/.env $BACKUP_DIR/env-$DATE.backup

# Backup nginx configuration
echo "🌐 Backing up nginx configuration..."
cp /etc/nginx/sites-available/bun-hono $BACKUP_DIR/nginx-$DATE.backup

# Backup systemd service file
echo "⚙️ Backing up systemd service file..."
cp /etc/systemd/system/bun-hono.service $BACKUP_DIR/service-$DATE.backup

# Backup SSL certificates
echo "🔒 Backing up SSL certificates..."
if [ -d /etc/letsencrypt ]; then
    sudo tar -czf $BACKUP_DIR/ssl-$DATE.tar.gz -C /etc letsencrypt
    echo "✅ SSL certificates backed up"
else
    echo "⚠️  No SSL certificates found to backup"
fi

# Backup nginx SSL configuration
echo "🌐 Backing up nginx SSL configuration..."
if [ -f /etc/nginx/sites-enabled/bun-hono ]; then
    cp /etc/nginx/sites-enabled/bun-hono $BACKUP_DIR/nginx-ssl-$DATE.backup
fi

# Clean up old backups (keep last 7 days)
echo "🧹 Cleaning up old backups..."
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*.backup" -mtime +7 -delete

echo "✅ Backup completed successfully!"
echo "📁 Backup location: $BACKUP_DIR"

# Optional: Upload to cloud storage (uncomment and configure)
# echo "☁️ Uploading to cloud storage..."
# rclone copy $BACKUP_DIR remote:backups/bun-hono/ 