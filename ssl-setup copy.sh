#!/bin/bash

# Let's Encrypt SSL Certificate Management Script
# Usage: ./ssl-setup.sh [init|renew]

set -e

DOMAIN="guard-e-loo.co.uk"
WWW_DOMAIN="www.guard-e-loo.co.uk"
EMAIL="admin@guard-e-loo.co.uk"
WEBROOT_PATH="/var/www/certbot"
CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
fi

# Ensure certbot is installed
if ! command -v certbot &> /dev/null; then
    log "Installing certbot..."
    apt-get update
    apt-get install -y certbot
fi

# Create webroot directory if it doesn't exist
mkdir -p "$WEBROOT_PATH"

init_certificates() {
    log "Initializing SSL certificates for $DOMAIN and $WWW_DOMAIN"

    # Check if certificates already exist
    if [[ -d "$CERT_PATH" ]]; then
        warn "Certificates already exist at $CERT_PATH"
        read -p "Do you want to force renewal? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Skipping certificate generation"
            return 0
        fi
        FORCE_RENEW="--force-renewal"
    fi

    # Stop nginx temporarily for standalone mode
    log "Stopping nginx for certificate generation..."
    docker compose -f /home/weedom/toilet/website/docker-compose.yml stop nginx || true

    # Generate certificates using standalone mode
    log "Generating certificates..."
    certbot certonly \
        --standalone \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --domains "$DOMAIN,$WWW_DOMAIN" \
        $FORCE_RENEW

    # Set proper permissions
    chmod -R 755 /etc/letsencrypt/live/
    chmod -R 755 /etc/letsencrypt/archive/

    # Restart nginx
    log "Starting nginx with SSL certificates..."
    docker compose -f /home/weedom/toilet/website/docker-compose.yml up -d nginx

    log "SSL certificates initialized successfully!"
}

renew_certificates() {
    log "Renewing SSL certificates..."

    # Create a temporary nginx config for renewal
    cat > /tmp/nginx-renewal.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name guard-e-loo.co.uk www.guard-e-loo.co.uk;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$server_name$request_uri;
        }
    }
}
EOF

    # Temporarily replace nginx config
    cp /home/weedom/toilet/website/nginx.conf /tmp/nginx-backup.conf
    cp /tmp/nginx-renewal.conf /home/weedom/toilet/website/nginx.conf

    # Reload nginx with renewal config
    docker compose -f /home/weedom/toilet/website/docker-compose.yml exec nginx nginx -s reload || {
        docker compose -f /home/weedom/toilet/website/docker-compose.yml restart nginx
    }

    # Renew certificates
    certbot renew \
        --webroot \
        --webroot-path="$WEBROOT_PATH" \
        --quiet

    # Restore original nginx config
    cp /tmp/nginx-backup.conf /home/weedom/toilet/website/nginx.conf

    # Reload nginx with SSL config
    docker compose -f /home/weedom/toilet/website/docker-compose.yml exec nginx nginx -s reload || {
        docker compose -f /home/weedom/toilet/website/docker-compose.yml restart nginx
    }

    log "Certificate renewal completed successfully!"
}

case "${1:-}" in
    "init")
        init_certificates
        ;;
    "renew")
        renew_certificates
        ;;
    *)
        echo "Usage: $0 [init|renew]"
        echo ""
        echo "Commands:"
        echo "  init   - Initialize SSL certificates (first time setup)"
        echo "  renew  - Renew existing certificates"
        echo ""
        echo "Examples:"
        echo "  sudo $0 init    # First time setup"
        echo "  sudo $0 renew   # Renew certificates"
        exit 1
        ;;
esac