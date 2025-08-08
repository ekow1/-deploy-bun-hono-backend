#!/bin/bash

# Fix Nginx Reverse Proxy Configuration
set -e

echo "🔧 Configuring Nginx as reverse proxy for Bun + Hono..."

# Backup current config
sudo cp /etc/nginx/sites-available/bun-hono /etc/nginx/sites-available/bun-hono.backup.$(date +%Y%m%d-%H%M%S)

# Create proper Nginx configuration for Bun + Hono
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
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;
    
    # Proxy all requests to Bun + Hono application
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
        
        # Buffer settings for better performance
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8080/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        access_log off;
    }
    
    # API routes
    location /api/ {
        proxy_pass http://localhost:8080/api/;
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

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

# Reload Nginx
echo "🔄 Reloading Nginx..."
sudo systemctl reload nginx

echo "✅ Nginx reverse proxy configured!"
echo ""
echo "📋 Verification steps:"
echo ""
echo "1. Check if Bun + Hono app is running:"
echo "   sudo systemctl status bun-hono"
echo ""
echo "2. Test local application:"
echo "   curl http://localhost:8080/health"
echo ""
echo "3. Test through Nginx (HTTP):"
echo "   curl http://server.ekowlabs.space/health"
echo ""
echo "4. Check Nginx logs if issues:"
echo "   sudo tail -f /var/log/nginx/error.log"
echo "   sudo tail -f /var/log/nginx/access.log"
echo ""
echo "5. Set up SSL certificate:"
echo "   sudo certbot --nginx -d server.ekowlabs.space"
echo ""
echo "🎯 Your Bun + Hono app should now be accessible at:"
echo "   - http://server.ekowlabs.space (redirects to HTTPS)"
echo "   - https://server.ekowlabs.space (after SSL setup)"
echo "   - http://server.ekowlabs.space/health (health check)"
echo "   - http://server.ekowlabs.space/api/users (API endpoints)" 