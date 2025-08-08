# 🚀 Bun Hono VPS Deployment Guide

This guide will help you deploy your Bun Hono application to a VPS using GitHub Actions.

## 📋 Prerequisites

- A VPS running Ubuntu 20.04 or later
- SSH access to your VPS
- A GitHub repository with your code
- Domain name (optional but recommended)

## 🔧 VPS Setup

### 1. Initial Server Setup

SSH into your VPS and run the setup script:

```bash
# Upload the deploy-setup.sh script to your VPS
scp deploy-setup.sh user@your-vps-ip:/home/user/

# SSH into your VPS
ssh user@your-vps-ip

# Make the script executable and run it
chmod +x deploy-setup.sh
./deploy-setup.sh
```

### 2. Clone Your Repository

```bash
cd /var/www
sudo git clone https://github.com/your-username/bun-hono.git
sudo chown -R $USER:$USER bun-hono
cd bun-hono
```

### 3. Create Environment File

```bash
nano .env
```

Add your environment variables:

```env
PORT=8080
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
RESEND_API_KEY=your_resend_api_key
SENDER_EMAIL=noreply@yourdomain.com
```

## 🔐 GitHub Secrets Setup

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add these secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `VPS_HOST` | Your VPS IP address | `192.168.1.100` |
| `VPS_USERNAME` | SSH username | `ubuntu` |
| `VPS_SSH_KEY` | Private SSH key | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `VPS_PORT` | SSH port (optional) | `22` |
| `PORT` | Application port | `8080` |
| `DOMAIN_NAME` | Your domain name | `example.com` |
| `EMAIL` | Email for SSL notifications | `admin@example.com` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://user:pass@host:port/db` |
| `JWT_SECRET` | JWT secret key | `your-super-secret-key` |
| `RESEND_API_KEY` | Resend API key | `re_123456789` |
| `SENDER_EMAIL` | Resend sender email | `noreply@yourdomain.com` |

### Generate SSH Key for GitHub Actions

```bash
# On your local machine
ssh-keygen -t rsa -b 4096 -C "github-actions" -f ~/.ssh/github_actions
# Copy the public key to your VPS
ssh-copy-id -i ~/.ssh/github_actions.pub user@your-vps-ip
# Copy the private key content to GitHub secret VPS_SSH_KEY
cat ~/.ssh/github_actions
```

## 🌐 Nginx Configuration

Update the nginx configuration with your domain:

```bash
sudo nano /etc/nginx/sites-available/bun-hono
```

Replace `your-domain.com` with your actual domain name.

## 🔄 Manual Deployment

If you need to deploy manually:

```bash
cd /var/www/bun-hono
git pull origin main
bun install --production
sudo systemctl restart bun-hono
sudo systemctl status bun-hono
```

## 📊 Monitoring

### Check Application Status

```bash
# Check service status
sudo systemctl status bun-hono

# Check logs
sudo journalctl -u bun-hono -f

# Check nginx status
sudo systemctl status nginx

# Check nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Application Health Check

```bash
# Test the application
curl http://localhost:8080
curl http://your-domain.com
```

## 🔧 Troubleshooting

### Common Issues

1. **Service won't start**
   ```bash
   sudo journalctl -u bun-hono -n 50
   ```

2. **Permission issues**
   ```bash
   sudo chown -R www-data:www-data /var/www/bun-hono
   ```

3. **Port already in use**
   ```bash
   sudo netstat -tlnp | grep :8080
   sudo kill -9 <PID>
   ```

4. **Nginx configuration error**
   ```bash
   sudo nginx -t
   sudo systemctl restart nginx
   ```

### SSL/HTTPS Setup

#### Automatic SSL Setup (Recommended)

The deployment workflow will automatically set up SSL certificates if you provide the `DOMAIN_NAME` secret.

#### Manual SSL Setup

Use the provided SSL setup script:

```bash
# Make the script executable
chmod +x ssl-setup.sh

# Run SSL setup
./ssl-setup.sh your-domain.com admin@your-domain.com
```

Or manually install SSL:

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Update nginx configuration with your domain
sudo sed -i "s/your-domain.com/your-actual-domain.com/g" /etc/nginx/sites-available/bun-hono

# Install SSL certificate
sudo certbot --nginx -d your-domain.com --non-interactive --agree-tos --email admin@your-domain.com

# Test certificate renewal
sudo certbot renew --dry-run
```

#### SSL Certificate Management

```bash
# Check certificate status
sudo certbot certificates

# Renew certificates manually
sudo certbot renew

# Check certificate expiration
sudo certbot certificates | grep "VALID"

# Test SSL configuration
curl -I https://your-domain.com
```

## 📈 Scaling Considerations

- **Load Balancing**: Use nginx as a reverse proxy
- **Process Management**: Consider using PM2 instead of systemd
- **Database**: Use MongoDB Atlas for production
- **Monitoring**: Set up application monitoring with tools like New Relic or DataDog

## 🔒 Security Best Practices

1. **Firewall Setup**
   ```bash
   sudo ufw allow ssh
   sudo ufw allow 'Nginx Full'
   sudo ufw enable
   ```

2. **Regular Updates**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Backup Strategy**
   ```bash
   # Create backup script
   sudo crontab -e
   # Add: 0 2 * * * /var/www/backup.sh
   ```

## 📞 Support

If you encounter issues:

1. Check the logs: `sudo journalctl -u bun-hono -f`
2. Verify environment variables: `cat /var/www/bun-hono/.env`
3. Test the application locally: `cd /var/www/bun-hono && bun run server.js`
4. Check nginx configuration: `sudo nginx -t`

---

**Happy Deploying! 🎉** 