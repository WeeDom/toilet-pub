#!/bin/bash

# Multi-Domain SSL Certificate Renewal Cron Job
# Renews certificates for all Guard-e-Loo domains
# This script should be added to root's crontab to run monthly

# Set up logging
LOGFILE="/var/log/guard-e-loo-ssl-renewal.log"
exec > >(tee -a "$LOGFILE")
exec 2>&1

echo "=================================================="
echo "Guard-e-Loo Multi-Domain SSL Certificate Renewal"
echo "Started: $(date)"
echo "=================================================="

# Change to the script directory
cd /home/weedom/toilet

# Run the multi-domain SSL renewal
./ssl-multi-domain.sh renew

# Check if renewal was successful
if [ $? -eq 0 ]; then
    echo "SUCCESS: All SSL certificates renewed successfully at $(date)"
    echo "Domains renewed: guard-e-loo.co.uk, www.guard-e-loo.co.uk, op.guard-e-loo.co.uk, staging.guard-e-loo.co.uk"

    # Optional: Send success notification (uncomment if you want email notifications)
    # echo "All SSL certificates for Guard-e-Loo domains renewed successfully on $(date)" | \
    #     mail -s "Multi-Domain SSL Renewal Success - Guard-e-Loo" admin@guard-e-loo.co.uk
else
    echo "ERROR: SSL certificate renewal failed at $(date)"

    # Optional: Send failure notification (uncomment if you want email notifications)
    # echo "SSL certificate renewal for Guard-e-Loo domains FAILED on $(date). Please check manually." | \
    #     mail -s "Multi-Domain SSL Renewal FAILED - Guard-e-Loo" admin@guard-e-loo.co.uk

    exit 1
fi

echo "=================================================="
echo "Multi-Domain SSL Certificate Renewal Complete"
echo "Finished: $(date)"
echo "=================================================="