#!/bin/bash

# SSL Setup Script for Bun Hono Application
# This script helps manage SSL certificates for your domain

set -e

DOMAIN_NAME=${1:-""}
EMAIL=${2:-"admin@example.com"}

if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Error: Domain name is required"
    echo "Usage: ./ssl-setup.sh <domain-name> [email]"
    echo "Example: ./ssl-setup.sh example.com admin@example.com"
    exit 1
fi

echo "🔒 Setting up SSL for domain: $DOMAIN_NAME"
echo "📧 Email for certificate notifications: $EMAIL"

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "❌ Error: nginx is not installed"
    exit 1
fi

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing certbot..."
    sudo apt update
    sudo apt install certbot python3-certbot-nginx -y
fi

# Update nginx configuration with domain name
echo "🌐 Updating nginx configuration..."
sudo sed -i "s/your-domain.com/$DOMAIN_NAME/g" /etc/nginx/sites-available/bun-hono

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
sudo nginx -t

# Reload nginx
echo "🔄 Reloading nginx..."
sudo systemctl reload nginx

# Check if domain resolves to this server
echo "🔍 Checking domain resolution..."
SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $DOMAIN_NAME | head -1)

if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    echo "⚠️  Warning: Domain $DOMAIN_NAME does not resolve to this server's IP ($SERVER_IP)"
    echo "   Domain resolves to: $DOMAIN_IP"
    echo "   This may cause SSL certificate issues"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install SSL certificate
echo "📜 Installing SSL certificate..."
sudo certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos --email $EMAIL

# Test SSL certificate
echo "🧪 Testing SSL certificate..."
if curl -f https://$DOMAIN_NAME > /dev/null 2>&1; then
    echo "✅ SSL certificate installed successfully!"
    echo "🌐 Your application is now available at: https://$DOMAIN_NAME"
    echo "🔍 Testing backend connection on port 8080..."
    if curl -f http://localhost:8080 > /dev/null 2>&1; then
        echo "✅ Backend application is running on port 8080"
    else
        echo "⚠️  Warning: Backend application not responding on port 8080"
    fi
else
    echo "❌ SSL certificate installation failed"
    exit 1
fi

# Setup automatic renewal
echo "🔄 Setting up automatic certificate renewal..."
sudo crontab -l 2>/dev/null | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet"; } | sudo crontab -

# Test certificate renewal
echo "🧪 Testing certificate renewal..."
sudo certbot renew --dry-run

echo ""
echo "✅ SSL setup completed successfully!"
echo ""
echo "📋 SSL Certificate Information:"
echo "   Domain: $DOMAIN_NAME"
echo "   Certificate Path: /etc/letsencrypt/live/$DOMAIN_NAME/"
echo "   Auto-renewal: Enabled (runs daily at 12:00 PM)"
echo ""
echo "🔧 Useful commands:"
echo "   Check certificate status: sudo certbot certificates"
echo "   Renew certificate manually: sudo certbot renew"
echo "   Check nginx status: sudo systemctl status nginx"
echo "   View nginx logs: sudo tail -f /var/log/nginx/error.log" 