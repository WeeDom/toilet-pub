# Guard-e-Loo Multi-Domain SSL & WordPress Setup

## 🎯 Current Status
✅ **WordPress with MySQL** running on http://localhost (development)
✅ **Multi-domain SSL certificates** ready for all subdomains
✅ **Centralized SSL management** at `/opt/guard-e-loo-ssl/`
✅ **Database persistence** with Docker volumes
✅ **Production-ready** configuration for AWS deployment

## 🌐 Domain Strategy
All domains point to same IP, same website (for now):
- **www.guard-e-loo.co.uk** → Main website
- **op.guard-e-loo.co.uk** → Future operations dashboard
- **staging.guard-e-loo.co.uk** → Future staging environment

Single ACME challenge verifies all domains at once!

## 🔐 SSL Certificate Setup
```bash
# Initial setup (run once on server)
sudo ./ssl-multi-domain.sh init

# Install auto-renewal (run once)
sudo ./install-multi-domain-ssl-cron.sh

# Check status anytime
sudo ./ssl-multi-domain.sh status
```

## 🚀 Deployment to AWS
1. **Point all DNS** (www, op, staging) to AWS instance IP
2. **Run SSL setup** - all domains verified together
3. **Deploy WordPress** with docker-compose up -d
4. **Complete WordPress setup** at https://www.guard-e-loo.co.uk

## 📁 File Structure
```
/home/weedom/toilet/
├── website/                    # Current WordPress stack
│   ├── docker-compose.yml     # MySQL + WordPress + Nginx
│   ├── nginx.conf             # Multi-domain ready
│   └── backup-db.sh           # Database backups
├── ssl-multi-domain.sh        # SSL management for all domains
└── install-multi-domain-ssl-cron.sh  # Auto-renewal setup
```

## 🔄 Future Growth
When ready for subdomains:
1. Certificates already exist ✅
2. Add nginx routing rules for subdomains
3. Create separate Docker stacks as needed
4. All pointing to centralized SSL at `/opt/guard-e-loo-ssl/`

Ready to build your investor-focused WordPress site! 🚽💰