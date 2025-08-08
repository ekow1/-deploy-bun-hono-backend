# Troubleshooting Guide

## Connection Refused Error

If you're getting `ERR_CONNECTION_REFUSED` when trying to access your site, follow these steps:

### 1. Check if the application is running

```bash
# SSH into your VPS
ssh your-username@your-vps-ip

# Check if the bun-hono service is running
sudo systemctl status bun-hono

# Check the logs for errors
sudo journalctl -u bun-hono -n 50 --no-pager
```

### 2. Check if the port is listening

```bash
# Check if anything is listening on port 8080
sudo netstat -tlnp | grep :8080

# Or using ss
sudo ss -tlnp | grep :8080
```

### 3. Check Nginx status

```bash
# Check if Nginx is running
sudo systemctl status nginx

# Check Nginx configuration
sudo nginx -t

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### 4. Check firewall settings

```bash
# Check UFW status
sudo ufw status

# Make sure ports 80, 443, and 22 are open
sudo ufw status numbered
```

### 5. Test the application locally

```bash
# Navigate to the application directory
cd /var/www/bun-hono

# Check if .env exists and has correct values
cat .env

# Test the application manually
bun run server.js
```

### 6. Check DNS resolution

```bash
# Check if your domain resolves to the correct IP
nslookup server.ekowlabs.space

# Check your server's public IP
curl ifconfig.me
```

## Common Issues and Solutions

### Issue: Application not starting
**Symptoms:** `Failed to execute /usr/local/bin/bun: Permission denied`

**Solution:**
```bash
# Fix Bun permissions
sudo chmod +x /usr/local/bin/bun
sudo chown www-data:www-data /usr/local/bin/bun

# Restart the service
sudo systemctl restart bun-hono
```

### Issue: Port already in use
**Symptoms:** `EADDRINUSE` error

**Solution:**
```bash
# Find what's using the port
sudo lsof -i :8080

# Kill the process if needed
sudo kill -9 <PID>

# Restart the service
sudo systemctl restart bun-hono
```

### Issue: SSL certificate not working
**Symptoms:** Browser shows SSL errors or redirects fail

**Solution:**
```bash
# Check if SSL certificate exists
sudo certbot certificates

# If no certificate, run SSL setup
sudo certbot --nginx -d server.ekowlabs.space

# Test SSL renewal
sudo certbot renew --dry-run
```

### Issue: Nginx 404 errors
**Symptoms:** Nginx serves 404 instead of your application

**Solution:**
```bash
# Check if the site is enabled
sudo ls -la /etc/nginx/sites-enabled/

# Check the Nginx configuration
sudo cat /etc/nginx/sites-available/bun-hono

# Reload Nginx
sudo systemctl reload nginx
```

### Issue: Environment variables not loading
**Symptoms:** Application fails with undefined environment variables

**Solution:**
```bash
# Check if .env file exists and has correct permissions
ls -la /var/www/bun-hono/.env

# Check the contents (be careful with sensitive data)
sudo cat /var/www/bun-hono/.env

# Fix permissions if needed
sudo chown www-data:www-data /var/www/bun-hono/.env
sudo chmod 600 /var/www/bun-hono/.env
```

## Manual Deployment Steps

If the automated deployment fails, you can deploy manually:

### 1. SSH into your VPS
```bash
ssh your-username@your-vps-ip
```

### 2. Clone the repository
```bash
cd /var/www
sudo git clone https://github.com/your-username/your-repo.git bun-hono
sudo chown -R $USER:$USER bun-hono
cd bun-hono
```

### 3. Install dependencies
```bash
bun install --production
```

### 4. Create .env file
```bash
cat > .env << EOF
PORT=8080
MONGODB_URI=your-mongodb-connection-string
JWT_SECRET=your-jwt-secret
RESEND=your-resend-api-key
SENDER_MAIL=your-sender-email
EOF
```

### 5. Set up the service
```bash
sudo cp bun-hono.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable bun-hono
sudo systemctl start bun-hono
```

### 6. Set up SSL
```bash
sudo certbot --nginx -d server.ekowlabs.space
```

### 7. Test the deployment
```bash
# Test locally
curl http://localhost:8080

# Test via Nginx
curl http://server.ekowlabs.space
```

## Debugging Commands

### Check all services
```bash
# Check all relevant services
sudo systemctl status nginx bun-hono

# Check all listening ports
sudo netstat -tlnp

# Check disk space
df -h

# Check memory usage
free -h
```

### Check logs
```bash
# Application logs
sudo journalctl -u bun-hono -f

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# System logs
sudo journalctl -f
```

### Test connectivity
```bash
# Test local application
curl -v http://localhost:8080

# Test Nginx proxy
curl -v http://localhost:80

# Test external access
curl -v http://server.ekowlabs.space
```

## Emergency Recovery

If everything is broken, you can reset:

```bash
# Stop all services
sudo systemctl stop nginx bun-hono

# Remove the application
sudo rm -rf /var/www/bun-hono

# Remove Nginx configuration
sudo rm /etc/nginx/sites-enabled/bun-hono
sudo rm /etc/nginx/sites-available/bun-hono

# Restart Nginx
sudo systemctl start nginx

# Then re-run the setup scripts
```

## Getting Help

If you're still having issues:

1. Check the GitHub Actions logs for detailed error messages
2. Run the debugging commands above
3. Check if your VPS provider has any firewall rules
4. Verify your domain DNS settings point to the correct IP
5. Ensure all required secrets are set in GitHub repository settings 