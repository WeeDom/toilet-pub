#!/bin/bash

# Monthly SSL Certificate Renewal Cron Job
# This script should be added to root's crontab to run monthly

# Set up logging
LOGFILE="/var/log/ssl-renewal.log"
exec > >(tee -a "$LOGFILE")
exec 2>&1

echo "======================================"
echo "SSL Certificate Renewal - $(date)"
echo "======================================"

# Change to the website directory
cd /home/weedom/toilet/website

# Run the SSL renewal
./ssl-setup.sh renew

# Check if renewal was successful
if [ $? -eq 0 ]; then
    echo "SUCCESS: SSL certificates renewed successfully at $(date)"

    # Optional: Send success notification (uncomment if you want email notifications)
    # echo "SSL certificates for guard-e-loo.co.uk renewed successfully on $(date)" | \
    #     mail -s "SSL Renewal Success - Guard-e-Loo" admin@guard-e-loo.co.uk
else
    echo "ERROR: SSL certificate renewal failed at $(date)"

    # Optional: Send failure notification (uncomment if you want email notifications)
    # echo "SSL certificate renewal for guard-e-loo.co.uk FAILED on $(date). Please check manually." | \
    #     mail -s "SSL Renewal FAILED - Guard-e-Loo" admin@guard-e-loo.co.uk

    exit 1
fi

echo "======================================"
echo "SSL Certificate Renewal Complete"
echo "======================================"