#!/bin/bash

# WordPress Database Backup Script
# Usage: ./backup-db.sh

set -e

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="wordpress_backup_${DATE}.sql"

echo "Creating database backup..."

# Create backups directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Create database backup
docker-compose exec -T db mysqldump -u wpuser -p${MYSQL_PASSWORD:-wppass} wordpress > "$BACKUP_DIR/$BACKUP_FILE"

# Compress the backup
gzip "$BACKUP_DIR/$BACKUP_FILE"

echo "✅ Database backup created: $BACKUP_DIR/${BACKUP_FILE}.gz"

# Optional: Keep only the last 7 backups
find $BACKUP_DIR -name "wordpress_backup_*.sql.gz" -type f -mtime +7 -delete

echo "📁 Old backups cleaned up (keeping last 7 days)"