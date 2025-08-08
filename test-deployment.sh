#!/bin/bash

# Test Bun + Hono Deployment
set -e

echo "🧪 Testing Bun + Hono deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

echo "📋 Checking system services..."

# Check if Bun + Hono service is running
if sudo systemctl is-active --quiet bun-hono; then
    print_status 0 "Bun + Hono service is running"
else
    print_status 1 "Bun + Hono service is not running"
    echo "   Run: sudo systemctl status bun-hono"
fi

# Check if Nginx is running
if sudo systemctl is-active --quiet nginx; then
    print_status 0 "Nginx service is running"
else
    print_status 1 "Nginx service is not running"
    echo "   Run: sudo systemctl status nginx"
fi

echo ""
echo "🔍 Checking port availability..."

# Check if port 8080 is listening
if sudo netstat -tlnp | grep -q ":8080 "; then
    print_status 0 "Port 8080 is listening"
else
    print_status 1 "Port 8080 is not listening"
    echo "   Run: sudo netstat -tlnp | grep :8080"
fi

# Check if port 80 is listening
if sudo netstat -tlnp | grep -q ":80 "; then
    print_status 0 "Port 80 is listening"
else
    print_status 1 "Port 80 is not listening"
fi

echo ""
echo "🌐 Testing local connectivity..."

# Test local application
if curl -s -f http://localhost:8080/health > /dev/null; then
    print_status 0 "Local application responds (localhost:8080)"
else
    print_status 1 "Local application does not respond"
    echo "   Run: curl -v http://localhost:8080/health"
fi

# Test Nginx proxy
if curl -s -f http://localhost/health > /dev/null; then
    print_status 0 "Nginx proxy responds (localhost)"
else
    print_status 1 "Nginx proxy does not respond"
    echo "   Run: curl -v http://localhost/health"
fi

echo ""
echo "🌍 Testing external connectivity..."

# Test external HTTP
if curl -s -f http://server.ekowlabs.space/health > /dev/null; then
    print_status 0 "External HTTP responds"
else
    print_status 1 "External HTTP does not respond"
    echo "   Run: curl -v http://server.ekowlabs.space/health"
fi

# Test external HTTPS (if SSL is set up)
if curl -s -f https://server.ekowlabs.space/health > /dev/null 2>/dev/null; then
    print_status 0 "External HTTPS responds"
else
    print_status 1 "External HTTPS does not respond (SSL may not be set up)"
    echo "   Run: sudo certbot --nginx -d server.ekowlabs.space"
fi

echo ""
echo "📊 Application endpoints test..."

# Test health endpoint
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health 2>/dev/null || echo "FAILED")
if [[ "$HEALTH_RESPONSE" == *"Server is running"* ]]; then
    print_status 0 "Health endpoint returns correct response"
else
    print_status 1 "Health endpoint response: $HEALTH_RESPONSE"
fi

# Test API endpoint
API_RESPONSE=$(curl -s http://localhost:8080/api/users 2>/dev/null || echo "FAILED")
if [[ "$API_RESPONSE" != "FAILED" ]]; then
    print_status 0 "API endpoint responds"
else
    print_status 1 "API endpoint does not respond"
fi

echo ""
echo "📝 Recent logs..."

# Show recent application logs
echo "📋 Recent Bun + Hono logs:"
sudo journalctl -u bun-hono -n 10 --no-pager | tail -10

echo ""
echo "📋 Recent Nginx error logs:"
sudo tail -5 /var/log/nginx/error.log 2>/dev/null || echo "No error logs found"

echo ""
echo "🎯 Summary:"
echo "   - Your Bun + Hono app should be accessible at:"
echo "     * http://server.ekowlabs.space (redirects to HTTPS)"
echo "     * https://server.ekowlabs.space (after SSL setup)"
echo "     * http://server.ekowlabs.space/health (health check)"
echo "     * http://server.ekowlabs.space/api/users (API endpoints)"
echo ""
echo "   - If you see ❌ errors above, check the troubleshooting guide:"
echo "     * TROUBLESHOOTING.md"
echo ""
echo "   - To set up SSL certificate:"
echo "     * sudo certbot --nginx -d server.ekowlabs.space" 