#!/bin/bash

# Bun Hono VPS Deployment Setup Script
# Run this script on your VPS to set up the deployment environment

set -e

echo "🚀 Setting up Bun Hono deployment environment..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

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
echo "🌐 Configuring nginx with SSL support..."
sudo tee /etc/nginx/sites-available/bun-hono << EOF
server {
    listen 80;
    server_name server.ekowlabs.space;  # Replace with your domain
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name server.ekowlabs.space;  # Your domain
    
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

echo "✅ Setup complete!"
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
echo "5. Run SSL setup: sudo certbot --nginx -d your-domain.com"
echo "6. Start the service: sudo systemctl start bun-hono"
echo ""
echo "🌐 Your application will be available at: https://your-domain.com"
echo "🔒 SSL certificate will be automatically renewed" 