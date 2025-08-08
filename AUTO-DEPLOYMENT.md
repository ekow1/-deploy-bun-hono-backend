# 🤖 Bun Hono Auto-Deployment Guide

This guide covers the **fully automated deployment** using GitHub Actions that handles everything from scratch.

## 🚀 Quick Start (5 minutes)

### **Step 1: Add GitHub Secrets**
Go to your repository → Settings → Secrets and variables → Actions, and add:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `VPS_HOST` | SSH host (IP or domain) | `server.ekowlabs.space` |
| `VPS_USERNAME` | SSH username | `ubuntu` |
| `VPS_SSH_KEY` | Private SSH key | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `VPS_SSH_PASSPHRASE` | Private key passphrase (optional) | `your-passphrase` |
| `VPS_SUDO_PASSWORD` | Sudo password for the SSH user (optional) | `your-sudo-password` |
| `VPS_PORT` | SSH port (optional) | `22` |
| `PORT` | Application port | `8080` |
| `DOMAIN_NAME` | Your domain name | `server.ekowlabs.space` |
| `EMAIL` | Email for SSL notifications | `admin@ekowlabs.space` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://user:pass@host:port/db` |
| `JWT_SECRET` | JWT secret key | `your-super-secret-key` |
| `RESEND` | Resend API key | `re_123456789` |
| `SENDER_MAIL` | Resend sender email | `noreply@ekowlabs.space` |

### **Step 2: Generate SSH Key**
```bash
# On your local machine
ssh-keygen -t rsa -b 4096 -C "github-actions" -f ~/.ssh/github_actions

# Copy the public key to your VPS
ssh-copy-id -i ~/.ssh/github_actions.pub user@your-vps-ip

# Copy the private key content to GitHub secret VPS_SSH_KEY
cat ~/.ssh/github_actions
```

### **Step 3: Deploy**
```bash
git push origin main
```

**That's it!** 🎉 The workflow will automatically:
- Set up your VPS environment
- Install Bun, nginx, SSL certificates
- Deploy your application
- Test everything

## 🔄 How It Works

### **First Deployment** (Automatic Setup):
1. **Detects** first-time setup
2. **Clones** your repository to `/var/www/bun-hono`
3. **Runs** `deploy-setup.sh` (installs everything)
4. **Runs** `ssl-setup.sh` (configures SSL)
5. **Deploys** your application

### **Subsequent Deployments** (Automatic Updates):
1. **Pulls** latest code
2. **Updates** dependencies
3. **Renews** SSL certificates
4. **Restarts** application
5. **Tests** deployment

## 📋 What Gets Installed Automatically

### **System Packages**:
- ✅ Bun (latest version)
- ✅ Node.js (for compatibility)
- ✅ Nginx (reverse proxy)
- ✅ Certbot (SSL certificates)
- ✅ UFW (firewall)

### **Application Setup**:
- ✅ Repository cloning
- ✅ Systemd service configuration
- ✅ Nginx configuration with SSL
- ✅ Environment file creation
- ✅ SSL certificate installation

### **Security Features**:
- ✅ HTTP to HTTPS redirect
- ✅ Security headers
- ✅ Firewall configuration
- ✅ SSL certificate auto-renewal

## 🌐 Your Application Will Be Available At

- **HTTPS**: `https://server.ekowlabs.space`
- **Health Check**: `https://server.ekowlabs.space/health`

## 📊 Monitoring

### **Check Deployment Status**:
- Go to your GitHub repository → Actions tab
- View the latest deployment run

### **Check Application Status** (on VPS):
```bash
# Service status
sudo systemctl status bun-hono

# Application logs
sudo journalctl -u bun-hono -f

# Nginx status
sudo systemctl status nginx

# SSL certificate status
sudo certbot certificates
```

## 🔧 Troubleshooting

### **If Deployment Fails**:
1. Check GitHub Actions logs for errors
2. Verify all secrets are set correctly
3. Ensure your VPS is accessible via SSH
4. Check domain DNS points to your VPS

### **Common Issues**:
- **SSH auth error (passphrase)**: Set `VPS_SSH_PASSPHRASE` to match your private key passphrase, or use a deploy key without a passphrase.
- **Sudo requires password**: Set `VPS_SUDO_PASSWORD`, or configure passwordless sudo (NOPASSWD) for the deploy user, or use `root`.
- **Bun install fails: unzip required**: Install it first: `sudo apt install -y unzip`.
- **bun: command not found**: Ensure Bun is on PATH for the SSH session:
  - `echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.profile && source ~/.profile`
  - The workflow also attempts to export PATH and symlink Bun to `/usr/local/bin/bun`.
- **Nginx site file missing**: If `/etc/nginx/sites-available/bun-hono` does not exist, the SSL script now creates a minimal site automatically before running Certbot.
- **Backups location**: Backups are stored under `~/bun-hono-backups` on the VPS.
- **SSH host**: You can set `VPS_HOST` to your domain (e.g., `server.ekowlabs.space`) instead of IP.
- **SSL Certificate**: Domain must point to VPS IP
- **Port Conflicts**: Ensure port 8080 is available
- **Permissions**: VPS user needs sudo access
- **DNS/SSL mismatch during SSL**: The SSL script compares IPv4 records. Ensure your A record points to the VPS IPv4. You can override in CI by setting environment variable `SSL_FORCE=1` (already handled in the workflow script call). If using IPv6/AAAA only, add an A record or adjust DNS.
- **Workflow times out during SSL**: Ensure DNS is propagated and port 80 is open. Certbot may take time if DNS just changed; re-run after propagation. Increase job timeout if needed.

## 🚀 Deployment Triggers

### **Automatic Triggers**:
- Push to `main` branch
- Push to `master` branch

### **Manual Trigger**:
- Go to Actions tab → Deploy to VPS → Run workflow

## 📈 Scaling

### **Future Enhancements**:
- Multiple environment support (staging/production)
- Database migrations
- Zero-downtime deployments
- Monitoring integration

## 🔒 Security

### **Automatic Security Setup**:
- ✅ Firewall configuration
- ✅ SSL/TLS encryption
- ✅ Security headers
- ✅ Nginx hardening

### **Best Practices**:
- Keep secrets secure
- Regularly update dependencies
- Monitor application logs
- Set up backup strategy

---

**Your deployment is now 100% automated!** 🎉

Just add secrets and push to deploy! 🚀 