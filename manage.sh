#!/bin/bash

# Guard-e-Loo Dual-Stack Website Management Script
# Manages production and staging environments with reverse proxy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRODUCTION_DIR="$SCRIPT_DIR/production"
STAGING_DIR="$SCRIPT_DIR/staging"
OPENPROJECT_DIR="$SCRIPT_DIR/openproject"
PROXY_DIR="$SCRIPT_DIR/proxy"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

show_usage() {
    echo "Guard-e-Loo Website Management"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start [env]        Start services (env: production, staging, proxy, all)"
    echo "  stop [env]         Stop services (env: production, staging, proxy, all)"
    echo "  restart [env]      Restart services (env: production, staging, proxy, all)"
    echo "  status             Show status of all services"
    echo "  logs [env]         Show logs (env: production, staging, proxy)"
    echo "  backup [env]       Backup database (env: production, staging, both)"
    echo "  promote            Promote staging to production (with backup)"
    echo "  update             Update and restart all services"
    echo "  wp-diff            Show differences between staging and production WordPress files"
    echo "  wp-backup [env]    Backup WordPress files (env: production, staging, both)"
    echo ""
    echo "Examples:"
    echo "  $0 start all"
    echo "  $0 restart production"
    echo "  $0 backup both"
    echo "  $0 promote"
    echo "  $0 wp-diff"
}

start_services() {
    local env=${1:-all}

    case $env in
        production)
            log "Starting production services..."
            cd "$PRODUCTION_DIR" && docker compose  up -d
            ;;
        staging)
            log "Starting staging services..."
            cd "$STAGING_DIR" && docker compose  up -d
            ;;
        proxy)
            log "Starting reverse proxy..."
            cd "$PROXY_DIR" && docker compose  up -d
            ;;
        openproject)
            log "Starting OpenProject services..."
            cd "$OPENPROJECT_DIR" && docker compose  up -d
            ;;
        all)
            log "Starting all services..."
            cd "$PRODUCTION_DIR" && docker compose  up -d
            cd "$OPENPROJECT_DIR" && docker compose  up -d
            cd "$STAGING_DIR" && docker compose  up -d
            cd "$PROXY_DIR" && docker compose  up -d
            ;;
        *)
            error "Invalid environment: $env"
            return 1
            ;;
    esac
}

stop_services() {
    local env=${1:-all}

    case $env in
        production)
            log "Stopping production services..."
            cd "$PRODUCTION_DIR" && docker compose  down
            ;;
        staging)
            log "Stopping staging services..."
            cd "$STAGING_DIR" && docker compose  down
            ;;
        proxy)
            log "Stopping reverse proxy..."
            cd "$PROXY_DIR" && docker compose  down
            ;;
        openproject)
            log "Stopping OpenProject services..."
            cd "$OPENPROJECT_DIR" && docker compose  down
            ;;
        all)
            log "Stopping all services..."
            cd "$PROXY_DIR" && docker compose  down
            cd "$STAGING_DIR" && docker compose  down
            cd "$PRODUCTION_DIR" && docker compose  down
            ;;
        *)
            error "Invalid environment: $env"
            return 1
            ;;
    esac
}

restart_services() {
    local env=${1:-all}
    log "Restarting $env services..."
    stop_services "$env"
    sleep 3
    start_services "$env"
}

show_status() {
    log "Service Status Overview:"
    echo ""

    info "Production Services:"
    cd "$PRODUCTION_DIR" && docker compose  ps
    echo ""

    info "Staging Services:"
    cd "$STAGING_DIR" && docker compose  ps
    echo ""

    info "Reverse Proxy:"
    cd "$PROXY_DIR" && docker compose  ps
    echo ""
    info "OpenProject Services:"
    cd "$OPENPROJECT_DIR" && docker compose  ps
    echo ""
}

show_logs() {
    local env=${1:-production}

    case $env in
        production)
            log "Production logs:"
            cd "$PRODUCTION_DIR" && docker compose  logs -f
            ;;
        staging)
            log "Staging logs:"
            cd "$STAGING_DIR" && docker compose  logs -f
            ;;
        proxy)
            log "Proxy logs:"
            cd "$PROXY_DIR" && docker compose  logs -f
            ;;
        openproject)
            log "OpenProject logs:"
            cd "$OPENPROJECT_DIR" && docker compose  logs -f
            ;;
        *)
            error "Invalid environment: $env"
            return 1
            ;;
    esac
}

backup_database() {
    local env=${1:-both}
    local timestamp=$(date +%Y%m%d_%H%M%S)

    case $env in
        production)
            log "Backing up production database..."
            cd "$PRODUCTION_DIR"
            docker compose  exec -T db mysqldump -u wpuser_prod -pwppass_prod wordpress_prod > "backups/production_backup_$timestamp.sql"
            ;;
        staging)
            log "Backing up staging database..."
            cd "$STAGING_DIR"
            docker compose  exec -T db mysqldump -u wpuser_staging -pwppass_staging wordpress_staging > "backups/staging_backup_$timestamp.sql"
            ;;
        openproject)
            log "Backing up OpenProject database..."
            cd "$OPENPROJECT_DIR"
            docker compose  exec -T db pg_dump -U openproject openproject > "backups/openproject_backup_$timestamp.sql"
            ;;
        all)
            backup_database production
            backup_database staging
            backup_database openproject
            ;;
        *)
            error "Invalid environment: $env"
            return 1
            ;;
    esac
}

promote_staging() {
    log "Promoting staging to production..."

    # 1. Backup current production
    warning "Creating production backup before promotion..."
    backup_database production

    # 2. Stop production
    log "Stopping production services..."
    stop_services production

    # 3. Export staging database
    log "Exporting staging database..."
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cd "$STAGING_DIR"
    docker compose  exec -T db mysqldump -u wpuser_staging -pwppass_staging wordpress_staging > "/tmp/staging_export_$timestamp.sql"

    # 4. Update staging export for production (replace URLs)
    log "Preparing database for production..."
    sed -i 's/staging\.guard-e-loo\.co\.uk/www.guard-e-loo.co.uk/g' "/tmp/staging_export_$timestamp.sql"

    # 5. Import to production
    log "Importing to production database..."
    cd "$PRODUCTION_DIR"
    start_services production
    sleep 10  # Wait for services to be ready
    docker compose  exec -T db mysql -u wpuser_prod -pwppass_prod wordpress_prod < "/tmp/staging_export_$timestamp.sql"

    # 6. Copy WordPress files (from Docker volumes)
    log "Syncing WordPress files..."

    # Create temporary directories for volume data extraction
    mkdir -p "/tmp/wp_sync_$timestamp"

    # Extract staging WordPress files from Docker volume
    log "Extracting staging WordPress files..."
    cd "$STAGING_DIR"
    docker compose  exec -T wordpress tar -czf /tmp/staging_wp_files.tar.gz -C /var/www/html .
    docker cp $(docker compose  ps -q wordpress):/tmp/staging_wp_files.tar.gz "/tmp/wp_sync_$timestamp/"

    # Stop production to ensure clean file sync
    log "Temporarily stopping production for file sync..."
    cd "$PRODUCTION_DIR"
    docker compose  stop wordpress nginx

    # Backup current production WordPress files
    log "Backing up current production WordPress files..."
    docker compose  start db  # Only start DB for backup
    sleep 5
    docker compose  run --rm wordpress tar -czf /backups/wp_files_backup_$timestamp.tar.gz -C /var/www/html . || true

    # Import staging files to production
    log "Importing staging files to production..."
    docker compose  run --rm -v "/tmp/wp_sync_$timestamp:/tmp_sync" wordpress sh -c "
        cd /var/www/html &&
        rm -rf ./* &&
        tar -xzf /tmp_sync/staging_wp_files.tar.gz &&
        chown -R www-data:www-data /var/www/html"

    # Cleanup temporary files
    rm -rf "/tmp/wp_sync_$timestamp"

    # 7. Restart production
    log "Restarting production services..."
    restart_services production

    # 8. Cleanup
    rm -f "/tmp/staging_export_$timestamp.sql"

    log "Promotion complete! Staging has been promoted to production."
    warning "Please test the production site and verify everything is working correctly."
}

update_all() {
    log "Updating all services..."

    # Pull latest images
    cd "$PRODUCTION_DIR" && docker compose  pull
    cd "$STAGING_DIR" && docker compose  pull
    cd "$PROXY_DIR" && docker compose  pull
    cd "$OPENPROJECT_DIR" && docker compose  pull

    # Restart all services
    restart_services all

    log "Update complete!"
}

# WordPress file management functions
wp_file_diff() {
    log "Comparing WordPress files between staging and production..."

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local temp_dir="/tmp/wp_diff_$timestamp"
    mkdir -p "$temp_dir/staging" "$temp_dir/production"

    # Extract files from both environments
    info "Extracting staging WordPress files..."
    cd "$STAGING_DIR"
    if docker compose  ps wordpress | grep -q "Up"; then
        docker compose  exec -T wordpress tar -czf /tmp/staging_files.tar.gz -C /var/www/html ./wp-content
        docker cp $(docker compose  ps -q wordpress):/tmp/staging_files.tar.gz "$temp_dir/"
        cd "$temp_dir" && tar -xzf staging_files.tar.gz -C staging/
    else
        warning "Staging WordPress is not running. Start it first with: ./manage.sh start staging"
        return 1
    fi

    info "Extracting production WordPress files..."
    cd "$PRODUCTION_DIR"
    if docker compose  ps wordpress | grep -q "Up"; then
        docker compose  exec -T wordpress tar -czf /tmp/production_files.tar.gz -C /var/www/html ./wp-content
        docker cp $(docker compose  ps -q wordpress):/tmp/production_files.tar.gz "$temp_dir/"
        cd "$temp_dir" && tar -xzf production_files.tar.gz -C production/
    else
        warning "Production WordPress is not running. Start it first with: ./manage.sh start production"
        return 1
    fi

    # Show differences
    info "WordPress file differences (staging vs production):"
    echo "Files in staging but not in production:"
    comm -23 <(find "$temp_dir/staging" -type f | sed "s|$temp_dir/staging/||" | sort) \
             <(find "$temp_dir/production" -type f | sed "s|$temp_dir/production/||" | sort) || true

    echo ""
    echo "Files in production but not in staging:"
    comm -13 <(find "$temp_dir/staging" -type f | sed "s|$temp_dir/staging/||" | sort) \
             <(find "$temp_dir/production" -type f | sed "s|$temp_dir/production/||" | sort) || true

    echo ""
    echo "Modified files (different between environments):"
    for file in $(comm -12 <(find "$temp_dir/staging" -type f | sed "s|$temp_dir/staging/||" | sort) \
                            <(find "$temp_dir/production" -type f | sed "s|$temp_dir/production/||" | sort)); do
        if ! cmp -s "$temp_dir/staging/$file" "$temp_dir/production/$file" 2>/dev/null; then
            echo "  $file"
        fi
    done

    # Cleanup
    rm -rf "$temp_dir"
}

wp_file_backup() {
    local env=${1:-both}
    local timestamp=$(date +%Y%m%d_%H%M%S)

    case $env in
        production)
            log "Backing up production WordPress files..."
            cd "$PRODUCTION_DIR"
            if docker compose  ps wordpress | grep -q "Up"; then
                docker compose  exec -T wordpress tar -czf /backups/wp_files_backup_$timestamp.tar.gz -C /var/www/html .
                log "✅ Production WordPress files backed up to: backups/wp_files_backup_$timestamp.tar.gz"
            else
                error "Production WordPress is not running"
                return 1
            fi
            ;;
        staging)
            log "Backing up staging WordPress files..."
            cd "$STAGING_DIR"
            if docker compose  ps wordpress | grep -q "Up"; then
                docker compose  exec -T wordpress tar -czf /backups/wp_files_backup_$timestamp.tar.gz -C /var/www/html .
                log "✅ Staging WordPress files backed up to: backups/wp_files_backup_$timestamp.tar.gz"
            else
                error "Staging WordPress is not running"
                return 1
            fi
            ;;
        both)
            wp_file_backup production
            wp_file_backup staging
            ;;
        *)
            error "Invalid environment: $env"
            return 1
            ;;
    esac
}

# Main script logic
case ${1:-help} in
    start)
        start_services "$2"
        ;;
    stop)
        stop_services "$2"
        ;;
    restart)
        restart_services "$2"
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    backup)
        backup_database "$2"
        ;;
    promote)
        promote_staging
        ;;
    update)
        update_all
        ;;
    wp-diff)
        wp_file_diff
        ;;
    wp-backup)
        wp_file_backup "$2"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
