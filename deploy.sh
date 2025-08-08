#!/bin/bash

# Manual Deployment Script for Bun + Hono
set -e

echo "🚀 Starting manual deployment..."

# Check if server is set up
if [ ! -d "/var/www/bun-hono" ]; then
    echo "❌ Server not set up. Please run the server setup first:"
    echo "   ./deploy-setup.sh"
    exit 1
fi

# Navigate to project directory
cd /var/www/bun-hono

# Backup current version
BACKUP_DIR="$HOME/bun-hono-backups"
mkdir -p "$BACKUP_DIR"
echo "📦 Creating backup in $BACKUP_DIR..."
cp -r . "$BACKUP_DIR/bun-hono-backup-$(date +%Y%m%d-%H%M%S)" || echo "Skipping backup due to permissions"

# Pull latest changes
echo "📥 Pulling latest changes..."
git config --global --add safe.directory /var/www/bun-hono || true
git fetch origin
git reset --hard origin/main

# Install dependencies
echo "📦 Installing dependencies..."
bun install --production

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "🔧 Creating .env file..."
    cat > .env << EOF
PORT=8080
MONGODB_URI=your-mongodb-connection-string
JWT_SECRET=your-jwt-secret
RESEND=your-resend-api-key
SENDER_MAIL=your-sender-email
EOF
    echo "⚠️  Please update .env file with your actual values"
fi

# Ensure service user owns the app directory
echo "🔑 Setting ownership to www-data for service compatibility..."
sudo chown -R www-data:www-data /var/www/bun-hono

# Ensure systemd service exists
if ! systemctl list-unit-files | grep -q '^bun-hono.service'; then
    echo "⚙️  Installing systemd service bun-hono.service..."
    sudo cp bun-hono.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable bun-hono
fi

# Restart the application
echo "🔄 Restarting application..."
sudo systemctl daemon-reload
sudo systemctl restart bun-hono

# Wait for service to start
sleep 5

# Check if service is running
if sudo systemctl is-active --quiet bun-hono; then
    echo "✅ Service is running successfully"
else
    echo "❌ Service failed to start"
    sudo systemctl status bun-hono
    exit 1
fi

# Health check
echo "🩺 Health check..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
    exit 1
fi

echo "🎉 Manual deployment completed successfully!"
echo ""
echo "🌐 Your application is available at:"
echo "   - http://localhost:8080"
echo "   - http://localhost:8080/health (health check)"
echo "   - http://localhost:8080/api/users (API)"
echo ""
echo "📋 To set up SSL, run:"
echo "   sudo certbot --nginx -d your-domain.com" 