#!/bin/bash

# Bun Hono VPS Deployment Setup Script
# Run this script on your VPS to set up the deployment environment

set -e

# Domain configuration: use $DOMAIN_NAME if set, else first arg, else default
DOMAIN_NAME=${DOMAIN_NAME:-${1:-server.ekowlabs.space}}

echo "🚀 Setting up Bun Hono deployment environment..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Ensure prerequisites
echo "🧰 Installing prerequisites (unzip)..."
sudo apt install -y unzip

# Install Bun
echo "🍞 Installing Bun..."
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc

# Install Node.js (for compatibility)
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install nginx
echo "🌐 Installing nginx..."
sudo apt install nginx -y

# Install Certbot for SSL certificates
echo "🔒 Installing Certbot for SSL..."
sudo apt install certbot python3-certbot-nginx -y

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /var/www/bun-hono
sudo chown -R $USER:$USER /var/www/bun-hono

# Copy systemd service file
echo "⚙️ Setting up systemd service..."
sudo cp bun-hono.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable bun-hono

# Configure nginx with SSL support
echo "🌐 Configuring nginx with SSL support for $DOMAIN_NAME..."
sudo tee /etc/nginx/sites-available/bun-hono << EOF
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

# Enable nginx site
sudo ln -sf /etc/nginx/sites-available/bun-hono /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t
sudo systemctl restart nginx

# Install PM2 for process management (alternative to systemd)
echo "📦 Installing PM2..."
sudo npm install -g pm2

# Setup firewall
echo "🔥 Setting up firewall..."
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

echo "✅ Setup complete for domain: $DOMAIN_NAME"
echo ""
echo "📋 Next steps:"
echo "1. Add your GitHub repository secrets:"
echo "   - VPS_HOST: Your VPS IP address"
echo "   - VPS_USERNAME: Your VPS username"
echo "   - VPS_SSH_KEY: Your private SSH key"
echo "   - VPS_PORT: SSH port (usually 22)"
echo "   - MONGODB_URI: Your MongoDB connection string"
echo "   - JWT_SECRET: Your JWT secret key"
echo "   - RESEND: Your Resend API key"
echo "   - SENDER_MAIL: Your Resend sender email"
echo "   - DOMAIN_NAME: Your domain name (for SSL)"
echo ""
echo "2. Clone your repository to /var/www/bun-hono"
echo "3. Create a .env file with your environment variables"
echo "4. Update the nginx configuration with your domain name"
echo "5. Run SSL setup: sudo certbot --nginx -d $DOMAIN_NAME"
echo "6. Start the service: sudo systemctl start bun-hono"
echo ""
echo "🌐 Your application will be available at: https://$DOMAIN_NAME"
echo "🔒 SSL certificate will be automatically renewed" 