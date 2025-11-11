#!/bin/bash

# Multi-Domain SSL Certificate Management Script for Guard-e-Loo
# Manages SSL certificates for: www.guard-e-loo.co.uk, op.guard-e-loo.co.uk, staging.guard-e-loo.co.uk
# Usage: ./ssl-multi-domain.sh [init|renew|status]

set -e

# Domain Configuration
MAIN_DOMAIN="guard-e-loo.co.uk"
ALL_DOMAINS="guard-e-loo.co.uk,www.guard-e-loo.co.uk,op.guard-e-loo.co.uk,staging.guard-e-loo.co.uk,op.guard-e-loo.co.uk,pm.guard-e-loo.co.uk"
EMAIL="admin@guard-e-loo.co.uk"

# Paths - centralized SSL storage
SSL_BASE_DIR="/opt/guard-e-loo-ssl"
CERT_PATH="$SSL_BASE_DIR/certs"
WEBROOT_PATH="$SSL_BASE_DIR/webroot"
LOGS_DIR="$SSL_BASE_DIR/logs"

# Current website stack location
WEBSITE_STACK="/home/weedom/toilet/website"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Setup directory structure
setup_directories() {
    log "Setting up SSL directory structure..."

    # Create base directories
    mkdir -p "$SSL_BASE_DIR"
    mkdir -p "$CERT_PATH"
    mkdir -p "$WEBROOT_PATH"
    mkdir -p "$LOGS_DIR"

    # Create symlink for website stack to access certificates
    mkdir -p "$WEBSITE_STACK/ssl"

    # Create symlink (remove existing first)
    rm -f "$WEBSITE_STACK/ssl/live" 2>/dev/null || true
    ln -sf "/etc/letsencrypt/live" "$WEBSITE_STACK/ssl/live"

    # Set permissions
    chown -R root:docker "$SSL_BASE_DIR" 2>/dev/null || chown -R root:root "$SSL_BASE_DIR"
    chmod -R 755 "$SSL_BASE_DIR"

    log "SSL directory structure created at $SSL_BASE_DIR"
}
# Install certbot if needed
install_certbot() {
    if ! command -v certbot &> /dev/null; then
        log "Installing certbot..."
        apt-get update
        apt-get install -y certbot
    else
        info "Certbot already installed"
    fi
}

# Stop nginx container
stop_nginx_containers() {
    log "Stopping nginx container for certificate generation..."

    if [[ -f "$WEBSITE_STACK/docker-compose.yml" ]]; then
        info "Stopping nginx in website stack"
        cd "$WEBSITE_STACK"
        docker-compose stop nginx 2>/dev/null || true
    fi
}

# Start nginx container
start_nginx_containers() {
    log "Starting nginx container..."

    if [[ -f "$WEBSITE_STACK/docker-compose.yml" ]]; then
        info "Starting nginx in website stack"
        cd "$WEBSITE_STACK"
        docker-compose up -d nginx 2>/dev/null || true
    fi
}
# Initialize certificates for all domains
init_certificates() {
    log "Initializing SSL certificates for all Guard-e-Loo domains"
    info "Domains: $ALL_DOMAINS"

    setup_directories
    install_certbot

    # Check if certificates already exist
    if [[ -d "/etc/letsencrypt/live/$MAIN_DOMAIN" ]]; then
        warn "Certificates already exist for $MAIN_DOMAIN"
        read -p "Do you want to force renewal? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Skipping certificate generation"
            return 0
        fi
        FORCE_RENEW="--force-renewal"
    fi

    # Stop all nginx containers
    stop_nginx_containers

    # Generate certificates using standalone mode for all domains
    log "Generating certificates for all domains..."
    certbot certonly \
        --standalone \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --domains "$ALL_DOMAINS" \
        $FORCE_RENEW \
        --cert-name "$MAIN_DOMAIN"

    # Set proper permissions
    chmod -R 755 /etc/letsencrypt/live/
    chmod -R 755 /etc/letsencrypt/archive/

    # Start all nginx containers
    start_nginx_containers

    log "SSL certificates initialized successfully for all domains!"
    show_status
}

# Renew certificates
renew_certificates() {
    log "Renewing SSL certificates for all Guard-e-Loo domains..."

    # Create renewal webroot if it doesn't exist
    mkdir -p "$WEBROOT_PATH"

    # Renew certificates using webroot
    certbot renew \
        --webroot \
        --webroot-path="$WEBROOT_PATH" \
        --quiet \
        --deploy-hook="systemctl reload nginx 2>/dev/null || /opt/guard-e-loo-ssl/reload-nginx.sh"

    # Reload nginx container
    log "Reloading nginx container..."
    if [[ -f "$WEBSITE_STACK/docker-compose.yml" ]]; then
        info "Reloading nginx in website stack"
        cd "$WEBSITE_STACK"
        docker-compose exec nginx nginx -s reload 2>/dev/null || docker-compose restart nginx 2>/dev/null || true
    fi

    log "Certificate renewal completed successfully!"
}
# Show certificate status
show_status() {
    log "SSL Certificate Status:"
    echo ""

    if [[ -d "/etc/letsencrypt/live/$MAIN_DOMAIN" ]]; then
        info "Certificate found for $MAIN_DOMAIN"
        echo "Certificate details:"
        openssl x509 -in "/etc/letsencrypt/live/$MAIN_DOMAIN/cert.pem" -text -noout | grep -E "(Subject:|DNS:|Not After)"
        echo ""

        echo "Domains covered:"
        openssl x509 -in "/etc/letsencrypt/live/$MAIN_DOMAIN/cert.pem" -text -noout | grep -A 10 "Subject Alternative Name" | grep DNS || echo "No SAN found"
        echo ""
    else
        warn "No certificates found for $MAIN_DOMAIN"
    fi

    echo "Certbot status:"
    certbot certificates 2>/dev/null || warn "Certbot not properly configured"
}

# Create nginx reload script
create_reload_script() {
    cat > "$SSL_BASE_DIR/reload-nginx.sh" << 'EOF'
#!/bin/bash
# Reload Guard-e-Loo nginx container after certificate renewal

WEBSITE_STACK="/home/weedom/toilet/website"

if [[ -f "$WEBSITE_STACK/docker-compose.yml" ]]; then
    echo "Reloading nginx in website stack"
    cd "$WEBSITE_STACK"
    docker-compose exec nginx nginx -s reload 2>/dev/null || docker-compose restart nginx 2>/dev/null || true
fi
EOF

    chmod +x "$SSL_BASE_DIR/reload-nginx.sh"
}
# Main script logic
case "${1:-}" in
    "init")
        check_root
        setup_directories
        create_reload_script
        init_certificates
        ;;
    "renew")
        check_root
        renew_certificates
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Multi-Domain SSL Certificate Manager for Guard-e-Loo"
        echo "Manages certificates for: www, op, and staging subdomains"
        echo ""
        echo "Usage: $0 [init|renew|status]"
        echo ""
        echo "Commands:"
        echo "  init     - Initialize SSL certificates for all domains (first time setup)"
        echo "  renew    - Renew existing certificates for all domains"
        echo "  status   - Show current certificate status"
        echo ""
        echo "Domains managed:"
        echo "  - guard-e-loo.co.uk"
        echo "  - www.guard-e-loo.co.uk"
        echo "  - op.guard-e-loo.co.uk"
        echo "  - staging.guard-e-loo.co.uk"
        echo "  - pm.guard-e-loo.co.uk"
        echo ""
        echo "Examples:"
        echo "  sudo $0 init     # First time setup for all domains"
        echo "  sudo $0 renew    # Renew all certificates"
        echo "  sudo $0 status   # Check certificate status"
        exit 1
        ;;
esac

