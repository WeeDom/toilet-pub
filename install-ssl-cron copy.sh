#!/bin/bash

# SSL Cron Job Installation Script
# Run this once to set up automatic SSL certificate renewal

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

log "Setting up SSL certificate auto-renewal cron job..."

# Create the cron job entry
CRON_JOB="0 3 1 * * /home/weedom/toilet/website/ssl-renewal-cron.sh"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "ssl-renewal-cron.sh"; then
    warn "SSL renewal cron job already exists"
    echo "Current SSL-related cron jobs:"
    crontab -l | grep ssl-renewal-cron.sh
    echo ""
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Keeping existing cron job"
        exit 0
    fi

    # Remove existing SSL cron jobs
    crontab -l | grep -v ssl-renewal-cron.sh | crontab -
fi

# Add the new cron job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

log "SSL certificate auto-renewal cron job installed successfully!"
echo ""
echo "Cron job details:"
echo "  Command: $CRON_JOB"
echo "  Schedule: 3:00 AM on the 1st of every month"
echo "  Log file: /var/log/ssl-renewal.log"
echo ""
echo "Current crontab:"
crontab -l
echo ""
log "SSL certificates will now renew automatically every month"
log "Run 'sudo tail -f /var/log/ssl-renewal.log' to monitor renewals"