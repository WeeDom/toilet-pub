# Guard-e-Loo WordPress Deployment Guide

## Database Persistence ✅
- **MySQL data**: Stored in Docker volume `db_data`
- **WordPress files**: Stored in Docker volume `wp_data`
- **Backups**: Stored in `./backups` directory (mapped to host)

## Local Development
```bash
# Start development environment
docker-compose up -d

# Access site
http://localhost

# Create database backup
./backup-db.sh
```

## Production Deployment to AWS

### 1. Server Setup
```bash
# On AWS EC2 instance
sudo apt update
sudo apt install docker.io docker-compose git
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

### 2. Domain & SSL Setup
- Point `www.guard-e-loo.co.uk` DNS to your AWS instance
- Set up SSL certificates (Let's Encrypt recommended)
- Place certificates in `./ssl/` directory

### 3. Production Configuration
```bash
# Copy environment file
cp .env.example .env

# Edit with strong passwords
nano .env

# Start production stack
docker-compose up -d
```

### 4. WordPress Configuration
- Complete WordPress setup at https://www.guard-e-loo.co.uk
- Install security plugins
- Configure backup schedule

## Key Features
- **Persistent Database**: All WordPress data survives container restarts
- **Auto-restart**: Containers restart automatically on failure
- **Health Checks**: Database health monitoring
- **Security**: HTTPS redirect, security headers, file upload limits
- **Performance**: Static file caching, optimized MySQL settings
- **Backups**: Automated database backup script

## Environment Variables
- `MYSQL_PASSWORD`: Database user password
- `MYSQL_ROOT_PASSWORD`: Database root password
- Domain automatically configured for www.guard-e-loo.co.uk

## Backup Strategy
- Run `./backup-db.sh` regularly
- Volume data is persistent in `/var/lib/docker/volumes/`
- Consider AWS EBS snapshots for full volume backups