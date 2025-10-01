#!/bin/bash

# Multi-Domain SSL Cron Job Installation Script
# Sets up automatic SSL certificate renewal for all Guard-e-Loo domains
# Run this once to set up automatic SSL certificate renewal

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

log "Setting up multi-domain SSL certificate auto-renewal cron job..."
info "This will manage certificates for:"
info "  - guard-e-loo.co.uk"
info "  - www.guard-e-loo.co.uk"
info "  - op.guard-e-loo.co.uk"
info "  - staging.guard-e-loo.co.uk"

# Create the cron job entry (runs at 3:00 AM on the 1st of every month)
CRON_JOB="0 3 1 * * /home/weedom/toilet/ssl-multi-domain-cron.sh"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "ssl.*renewal\|ssl-multi-domain"; then
    warn "SSL renewal cron job already exists"
    echo "Current SSL-related cron jobs:"
    crontab -l | grep -E "ssl.*renewal|ssl-multi-domain"
    echo ""
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Keeping existing cron job"
        exit 0
    fi

    # Remove existing SSL cron jobs
    crontab -l | grep -vE "ssl.*renewal|ssl-multi-domain" | crontab -
fi

# Add the new cron job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

# Create log directory
mkdir -p /var/log
touch /var/log/guard-e-loo-ssl-renewal.log
chmod 644 /var/log/guard-e-loo-ssl-renewal.log

log "Multi-domain SSL certificate auto-renewal cron job installed successfully!"
echo ""
echo "Cron job details:"
echo "  Command: $CRON_JOB"
echo "  Schedule: 3:00 AM on the 1st of every month"
echo "  Log file: /var/log/guard-e-loo-ssl-renewal.log"
echo ""
echo "Domains managed:"
echo "  ✓ guard-e-loo.co.uk"
echo "  ✓ www.guard-e-loo.co.uk"
echo "  ✓ op.guard-e-loo.co.uk"
echo "  ✓ staging.guard-e-loo.co.uk"
echo ""
echo "Current crontab:"
crontab -l
echo ""
log "SSL certificates will now renew automatically every month for all domains"
log "Run 'sudo tail -f /var/log/guard-e-loo-ssl-renewal.log' to monitor renewals"
echo ""
info "Next steps:"
info "1. Run 'sudo /home/weedom/toilet/ssl-multi-domain.sh init' to set up initial certificates"
info "2. Configure your nginx to use the certificates from /etc/letsencrypt/live/guard-e-loo.co.uk/"