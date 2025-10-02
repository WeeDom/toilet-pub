#!/bin/bash

# Guard-e-Loo Dual-Stack Migration Script
# Migrates from single WordPress installation to dual-stack architecture

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBSITE_DIR="$SCRIPT_DIR/website"
PRODUCTION_DIR="$SCRIPT_DIR/production"
STAGING_DIR="$SCRIPT_DIR/staging"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if old website exists
check_existing_website() {
    if [ ! -d "$WEBSITE_DIR" ]; then
        error "No existing website directory found at $WEBSITE_DIR"
        error "This script is for migrating from an existing WordPress setup."
        exit 1
    fi

    if [ ! -f "$WEBSITE_DIR/docker-compose.yml" ]; then
        error "No docker-compose.yml found in $WEBSITE_DIR"
        exit 1
    fi

    log "✅ Found existing website installation"
}

# Backup current website
backup_current_website() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$SCRIPT_DIR/migration_backup_$timestamp"

    log "Creating backup of current website..."

    # Create backup directory
    mkdir -p "$backup_dir"

    # Backup database if website is running
    cd "$WEBSITE_DIR"
    if docker-compose ps | grep -q "Up"; then
        log "Backing up current database..."
        docker-compose exec -T db mysqldump -u wpuser -p${MYSQL_PASSWORD:-wppass} wordpress > "$backup_dir/website_database_backup.sql" || {
            warning "Could not backup database automatically. You may need to backup manually."
        }

        # Backup WordPress files
        log "Backing up WordPress files..."
        docker-compose exec -T wordpress tar -czf /tmp/wordpress_files.tar.gz -C /var/www/html . || {
            warning "Could not backup WordPress files automatically."
        }
        docker cp $(docker-compose ps -q wordpress):/tmp/wordpress_files.tar.gz "$backup_dir/" || true
    else
        warning "Website is not running. Starting it to create backup..."
        docker-compose up -d
        sleep 15

        # Try backup again
        docker-compose exec -T db mysqldump -u wpuser -p${MYSQL_PASSWORD:-wppass} wordpress > "$backup_dir/website_database_backup.sql" || {
            warning "Could not backup database. Please backup manually before proceeding."
        }

        docker-compose exec -T wordpress tar -czf /tmp/wordpress_files.tar.gz -C /var/www/html . || {
            warning "Could not backup WordPress files."
        }
        docker cp $(docker-compose ps -q wordpress):/tmp/wordpress_files.tar.gz "$backup_dir/" || true
    fi

    # Copy configuration files
    cp -r "$WEBSITE_DIR/"* "$backup_dir/"

    log "✅ Backup created at: $backup_dir"
    echo "MIGRATION_BACKUP_DIR=$backup_dir" > "$SCRIPT_DIR/.migration_info"
}

# Initialize dual-stack from backup
initialize_dual_stack() {
    log "Initializing dual-stack architecture..."

    # Stop current website
    log "Stopping current website..."
    cd "$WEBSITE_DIR"
    docker-compose down

    # Start production stack
    log "Starting production environment..."
    cd "$PRODUCTION_DIR"
    docker-compose up -d

    # Wait for production to be ready
    log "Waiting for production environment to be ready..."
    sleep 20

    # Import backup data to production if available
    if [ -f "$SCRIPT_DIR/.migration_info" ]; then
        source "$SCRIPT_DIR/.migration_info"
        if [ -f "$MIGRATION_BACKUP_DIR/website_database_backup.sql" ]; then
            log "Importing database backup to production..."
            docker-compose exec -T db mysql -u wpuser_prod -p${MYSQL_PASSWORD:-wppass_prod} wordpress_prod < "$MIGRATION_BACKUP_DIR/website_database_backup.sql" || {
                warning "Database import failed. You may need to import manually."
            }
        fi

        if [ -f "$MIGRATION_BACKUP_DIR/wordpress_files.tar.gz" ]; then
            log "Importing WordPress files to production..."
            docker cp "$MIGRATION_BACKUP_DIR/wordpress_files.tar.gz" $(docker-compose ps -q wordpress):/tmp/
            docker-compose exec wordpress sh -c "cd /var/www/html && tar -xzf /tmp/wordpress_files.tar.gz && chown -R www-data:www-data /var/www/html" || {
                warning "WordPress files import failed. You may need to import manually."
            }
        fi
    fi

    # Copy production to staging
    log "Setting up staging environment..."
    cd "$PRODUCTION_DIR"
    docker-compose exec -T db mysqldump -u wpuser_prod -p${MYSQL_PASSWORD:-wppass_prod} wordpress_prod > "/tmp/prod_export.sql"
    docker-compose exec -T wordpress tar -czf /tmp/prod_wp_files.tar.gz -C /var/www/html .
    docker cp $(docker-compose ps -q wordpress):/tmp/prod_wp_files.tar.gz "/tmp/"

    # Start staging
    cd "$STAGING_DIR"
    docker-compose up -d
    sleep 15

    # Import production data to staging
    log "Importing production data to staging..."
    sed 's/www\.guard-e-loo\.co\.uk/staging.guard-e-loo.co.uk/g' "/tmp/prod_export.sql" > "/tmp/staging_import.sql"
    docker-compose exec -T db mysql -u wpuser_staging -p${MYSQL_PASSWORD:-wppass_staging} wordpress_staging < "/tmp/staging_import.sql"

    # Import WordPress files to staging
    docker cp "/tmp/prod_wp_files.tar.gz" $(docker-compose ps -q wordpress):/tmp/
    docker-compose exec wordpress sh -c "cd /var/www/html && tar -xzf /tmp/prod_wp_files.tar.gz && chown -R www-data:www-data /var/www/html"

    # Start reverse proxy
    log "Starting reverse proxy..."
    cd "$SCRIPT_DIR/proxy"
    docker-compose up -d

    # Cleanup
    rm -f "/tmp/prod_export.sql" "/tmp/staging_import.sql" "/tmp/prod_wp_files.tar.gz"

    log "✅ Dual-stack architecture initialized!"
}

# Verify migration
verify_migration() {
    log "Verifying migration..."

    cd "$SCRIPT_DIR"
    ./manage.sh status

    info "Migration complete! Please verify:"
    echo "1. Production site: https://www.guard-e-loo.co.uk"
    echo "2. Staging site: https://staging.guard-e-loo.co.uk"
    echo "3. Check that all your content is present"
    echo ""
    echo "Useful commands:"
    echo "  ./manage.sh status    - Check service status"
    echo "  ./manage.sh logs production - View production logs"
    echo "  ./manage.sh logs staging - View staging logs"
    echo "  ./manage.sh wp-diff   - Compare staging vs production files"
    echo ""
    warning "Don't forget to test thoroughly before removing the backup!"
}

# Main migration process
main() {
    log "🚀 Starting Guard-e-Loo Dual-Stack Migration"
    echo ""

    check_existing_website
    backup_current_website
    initialize_dual_stack
    verify_migration

    log "🎉 Migration completed successfully!"
}

# Show usage
show_usage() {
    echo "Guard-e-Loo Dual-Stack Migration"
    echo ""
    echo "This script migrates your existing WordPress installation to the new dual-stack architecture."
    echo ""
    echo "Usage: $0 [--help]"
    echo ""
    echo "What this script does:"
    echo "1. Backs up your current website (database + files)"
    echo "2. Stops the old website"
    echo "3. Initializes production environment with your data"
    echo "4. Creates staging environment as a copy of production"
    echo "5. Starts the reverse proxy"
    echo ""
    echo "Requirements:"
    echo "- Existing WordPress installation in ./website/"
    echo "- Docker and docker-compose installed"
    echo "- SSL certificates already configured"
}

case ${1:-migrate} in
    migrate|"")
        main
        ;;
    --help|-h|help)
        show_usage
        ;;
    *)
        error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac