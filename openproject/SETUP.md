# OpenProject Setup Guide

## Current Status
✅ OpenProject containers running successfully
✅ Database initialized with default credentials
✅ Nginx proxy configuration added
✅ SSL certificate script updated for projects.guard-e-loo.co.uk

## Setup Steps

### 1. Ensure OpenProject is Running
```bash
cd ~/toilet/openproject
docker compose ps
# Both openproject_app and openproject_db should show "Up"
```

### 2. Update SSL Certificate
Add `projects.guard-e-loo.co.uk` to your Let's Encrypt certificate:

```bash
cd ~/toilet
sudo ./ssl-multi-domain.sh renew
```

**Note:** If this is the first time adding the domain, you may need to use `init` instead:
```bash
sudo ./ssl-multi-domain.sh init
```

### 3. Connect OpenProject to Proxy Network
The OpenProject containers need to be on the same network as the nginx proxy:

```bash
# First, ensure the proxy is running
cd ~/toilet/proxy
docker compose up -d

# Restart OpenProject to connect to the network
cd ~/toilet/openproject
docker compose down
docker compose up -d
```

### 4. Test Nginx Configuration
```bash
cd ~/toilet/proxy
docker compose exec nginx-proxy nginx -t
```

### 5. Reload Nginx Proxy
```bash
cd ~/toilet/proxy
docker compose restart nginx-proxy
```

### 6. Access OpenProject
Once DNS is configured for `projects.guard-e-loo.co.uk`, access:
- **URL:** https://projects.guard-e-loo.co.uk
- **Default Login:** admin
- **Default Password:** admin

**⚠️ IMPORTANT:** Change the admin password immediately after first login!

## Configuration Files

### Docker Compose
- **File:** `~/toilet/openproject/docker-compose.yml`
- **Services:** openproject (app), db (PostgreSQL 13)
- **Network:** `proxy_proxy_network` (external, shared with nginx)
- **Volumes:** `./assets`, `./db_data`

### Environment Variables
- **File:** `~/toilet/openproject/env/.env`
- **Key Variables:**
  - `POSTGRES_DB=openproject`
  - `POSTGRES_USER=openproject`
  - `POSTGRES_PASSWORD=change_me_strong` ⚠️ Change in production!
  - `OPENPROJECT_HOST=localhost:8082`

### Nginx Proxy
- **File:** `~/toilet/proxy/nginx.conf`
- **Upstream:** `openproject_app:80`
- **Domain:** `projects.guard-e-loo.co.uk`
- **SSL:** Shared certificate with other Guard-e-Loo domains

## Troubleshooting

### Check Container Logs
```bash
cd ~/toilet/openproject
docker compose logs -f
```

### Check if OpenProject is Responding
```bash
docker exec openproject_app curl -I http://localhost:80/
```

### Verify Network Connectivity
```bash
docker network inspect proxy_proxy_network
# Should show both openproject_app and nginx-proxy containers
```

### Database Connection Issues
Check that the database environment variables match between the app and db services.

## DNS Configuration
Before accessing via HTTPS, ensure DNS is configured:
```
projects.guard-e-loo.co.uk  →  [Your Server IP]
```

## Integration with manage.sh
The OpenProject stack can be managed separately from the main website stacks:

```bash
# Start OpenProject
cd ~/toilet/openproject && docker compose up -d

# Stop OpenProject
cd ~/toilet/openproject && docker compose down

# View logs
cd ~/toilet/openproject && docker compose logs -f
```

## Next Steps
1. ✅ OpenProject running locally
2. ⏳ Update SSL certificate with `projects.guard-e-loo.co.uk`
3. ⏳ Restart nginx proxy
4. ⏳ Configure DNS for projects.guard-e-loo.co.uk
5. ⏳ Test HTTPS access
6. ⏳ Change default admin password
7. ⏳ Configure OpenProject settings
