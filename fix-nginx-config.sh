#!/bin/bash

# Fix Nginx configuration script
set -e

echo "🔧 Fixing Nginx configuration..."

# Backup current config
sudo cp /etc/nginx/sites-available/bun-hono /etc/nginx/sites-available/bun-hono.backup

# Create correct Nginx configuration
sudo tee /etc/nginx/sites-available/bun-hono << EOF
server {
    listen 80;
    server_name server.ekowlabs.space;
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name server.ekowlabs.space;
    
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
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;
    
    location / {
        proxy_pass http://localhost:8080;
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
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Security: Hide nginx version
    server_tokens off;
}
EOF

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

# Reload Nginx
echo "🔄 Reloading Nginx..."
sudo systemctl reload nginx

echo "✅ Nginx configuration fixed!"
echo ""
echo "📋 Next steps:"
echo "1. Set up SSL certificate:"
echo "   sudo certbot --nginx -d server.ekowlabs.space"
echo ""
echo "2. Check if your application is running:"
echo "   sudo systemctl status bun-hono"
echo ""
echo "3. Test the site:"
echo "   curl -I http://server.ekowlabs.space" 