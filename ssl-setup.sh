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

# Determine app port (read from .env if available, fallback to 8080)
APP_PORT=8080
if [ -f /var/www/bun-hono/.env ]; then
  PORT_FROM_ENV=$(grep -E '^PORT=' /var/www/bun-hono/.env | cut -d '=' -f2 | tr -d '"' | tr -d "'")
  if [ -n "$PORT_FROM_ENV" ]; then
    APP_PORT=$PORT_FROM_ENV
  fi
fi

# Ensure nginx site exists; if not, create a minimal HTTP config to allow Certbot to proceed
NGINX_SITE="/etc/nginx/sites-available/bun-hono"
if [ ! -f "$NGINX_SITE" ]; then
  echo "🛠️  Nginx site not found. Creating minimal HTTP config at $NGINX_SITE..."
  sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  sudo tee "$NGINX_SITE" >/dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;
    
    # SSL configuration will be added by Certbot
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;
    
    # Proxy all requests to Bun + Hono application
    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings for better performance
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:$APP_PORT/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        access_log off;
    }
    
    # API routes
    location /api/ {
        proxy_pass http://localhost:$APP_PORT/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers for API
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        
        # Handle preflight requests
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, Authorization";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
    
    # Security: Hide nginx version
    server_tokens off;
}
EOF
  sudo ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/bun-hono
fi

# Update nginx configuration with domain name (idempotent)
echo "🌐 Updating nginx configuration..."
sudo sed -i "s/your-domain.com/$DOMAIN_NAME/g" "$NGINX_SITE" || true

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
sudo nginx -t

# Reload nginx
echo "🔄 Reloading nginx..."
sudo systemctl reload nginx

# Check if domain resolves to this server (IPv4 comparison to avoid false IPv6 mismatches)
echo "🔍 Checking domain resolution..."
SERVER_IP=$(curl -4 -s ifconfig.me || curl -4 -s icanhazip.com || curl -4 -s api.ipify.org || echo "")
DOMAIN_IP=$(dig +short A $DOMAIN_NAME | head -1)

if [ -n "$SERVER_IP" ] && [ -n "$DOMAIN_IP" ] && [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    echo "⚠️  Warning: Domain $DOMAIN_NAME IPv4 ($DOMAIN_IP) does not match server IPv4 ($SERVER_IP)"
    echo "   This may cause SSL certificate issues"
    if [ -n "$CI" ] || [ "$SSL_FORCE" = "1" ]; then
        echo "   CI mode detected or SSL_FORCE=1 set. Continuing non-interactively..."
    else
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
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
    echo "🔍 Testing backend connection on port $APP_PORT..."
    if curl -f http://localhost:$APP_PORT > /dev/null 2>&1; then
        echo "✅ Backend application is running on port $APP_PORT"
    else
        echo "⚠️  Warning: Backend application not responding on port $APP_PORT"
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