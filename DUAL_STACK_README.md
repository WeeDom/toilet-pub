# Guard-e-Loo Dual-Stack WordPress Architecture

This repository contains a dual-stack WordPress setup for the Guard-e-Loo website with separate production and staging environments managed by a reverse proxy.

## Architecture Overview

```
                    Internet
                       |
                 [Reverse Proxy]
               (nginx with SSL termination)
                       |
            ┌──────────┴──────────┐
            |                     |
    [Production Stack]      [Staging Stack]
    www.guard-e-loo.co.uk   staging.guard-e-loo.co.uk
    ├─ WordPress (PHP-FPM)  ├─ WordPress (PHP-FPM)
    ├─ MySQL Database       ├─ MySQL Database
    └─ Nginx (internal)     └─ Nginx (internal)
```

## Directory Structure

```
/home/weedom/toilet/
├── production/          # Production WordPress stack
│   ├── docker-compose.yml
│   ├── nginx.conf
│   ├── .env
│   └── wordpress/       # WordPress files
├── staging/             # Staging WordPress stack
│   ├── docker-compose.yml
│   ├── nginx.conf
│   ├── .env
│   └── wordpress/       # WordPress files
├── proxy/               # Reverse proxy
│   ├── docker-compose.yml
│   └── nginx.conf
├── manage.sh            # Management script
└── ssl-multi-domain.sh  # SSL certificate management
```

## SSL Certificate Configuration

The setup uses a single multi-domain SSL certificate that covers:
- `guard-e-loo.co.uk`
- `www.guard-e-loo.co.uk`
- `staging.guard-e-loo.co.uk`
- `op.guard-e-loo.co.uk` (future operations dashboard)

## Getting Started

### 1. Stop Current Services
If you have existing services running:
```bash
cd /home/weedom/toilet/website
docker-compose down
```

### 2. Start the New Architecture
```bash
cd /home/weedom/toilet
./manage.sh start all
```

### 3. Check Status
```bash
./manage.sh status
```

## Management Commands

The `manage.sh` script provides comprehensive management:

### Service Management
```bash
# Start all services
./manage.sh start all

# Start specific environment
./manage.sh start production
./manage.sh start staging
./manage.sh start proxy

# Stop services
./manage.sh stop all
./manage.sh stop production

# Restart services
./manage.sh restart staging
```

### Database Operations
```bash
# Backup databases
./manage.sh backup both
./manage.sh backup production
./manage.sh backup staging
```

### Staging to Production Promotion
```bash
# Promote staging to production (with automatic backup)
./manage.sh promote
```

### Monitoring
```bash
# Check service status
./manage.sh status

# View logs
./manage.sh logs production
./manage.sh logs staging
./manage.sh logs proxy
```

## Environment Configuration

### Production Environment
- **URL**: https://www.guard-e-loo.co.uk
- **Database**: `wordpress_prod`
- **Debug**: Disabled
- **Environment file**: `production/.env`

### Staging Environment
- **URL**: https://staging.guard-e-loo.co.uk
- **Database**: `wordpress_staging`
- **Debug**: Enabled
- **Environment file**: `staging/.env`

## Development Workflow

1. **Make changes in staging**:
   - Access https://staging.guard-e-loo.co.uk
   - Test your changes thoroughly
   - Verify functionality

2. **Promote to production**:
   ```bash
   ./manage.sh promote
   ```
   This will:
   - Backup current production
   - Export staging database
   - Update URLs for production
   - Import to production
   - Sync WordPress files
   - Restart production services

3. **Verify production**:
   - Check https://www.guard-e-loo.co.uk
   - Ensure all functionality works

## Database Management

### Manual Database Operations

#### Production Database Access
```bash
cd production
docker-compose exec db mysql -u wpuser_prod -p wordpress_prod
```

#### Staging Database Access
```bash
cd staging
docker-compose exec db mysql -u wpuser_staging -p wordpress_staging
```

#### Manual Backup
```bash
# Production backup
cd production
docker-compose exec db mysqldump -u wpuser_prod -p wordpress_prod > backups/manual_backup_$(date +%Y%m%d_%H%M%S).sql

# Staging backup
cd staging
docker-compose exec db mysqldump -u wpuser_staging -p wordpress_staging > backups/manual_backup_$(date +%Y%m%d_%H%M%S).sql
```

## Network Architecture

- **Production Stack**: Internal network `production_default`
- **Staging Stack**: Internal network `staging_default`
- **Reverse Proxy**: Connected to both production and staging networks
- **External Access**: Only through reverse proxy on ports 80/443

## Security Features

1. **SSL Termination**: All SSL handling at reverse proxy level
2. **Internal Communication**: Backend services only accessible internally
3. **Separate Databases**: Production and staging completely isolated
4. **Environment Variables**: Sensitive data in `.env` files
5. **Security Headers**: Configured in reverse proxy

## Troubleshooting

### Check Service Status
```bash
./manage.sh status
```

### View Logs
```bash
# Production logs
./manage.sh logs production

# Staging logs
./manage.sh logs staging

# Proxy logs
./manage.sh logs proxy
```

### Common Issues

1. **Services won't start**: Check if ports are already in use
2. **Database connection errors**: Verify environment variables in `.env` files
3. **SSL certificate issues**: Check certificate paths in proxy configuration
4. **Network connectivity**: Ensure Docker networks are properly created

### Emergency Recovery

If something goes wrong, you can restore from the old setup:
```bash
# Stop new architecture
./manage.sh stop all

# Start old architecture
cd /home/weedom/toilet/website
docker-compose up -d
```

## Maintenance

### Regular Backups
Set up a cron job for regular backups:
```bash
# Add to crontab (crontab -e)
0 2 * * * /home/weedom/toilet/manage.sh backup both
```

### SSL Certificate Renewal
The existing SSL renewal system continues to work with this architecture.

### Updates
```bash
# Update all services
./manage.sh update
```

## Future Enhancements

1. **Operations Dashboard**: The `op.guard-e-loo.co.uk` subdomain is ready for a future operations dashboard
2. **Automated Testing**: Consider adding automated tests before promotion
3. **Blue-Green Deployment**: Could be enhanced for zero-downtime deployments
4. **Monitoring**: Add health checks and monitoring solutions

## Support

For issues or questions about this setup, refer to the management script help:
```bash
./manage.sh help
```