# 🚀 Production Deployment Guide

## 🎯 Overview

This guide covers deploying Fortaleza Basketball Analytics to production using Google Container Registry and Caddy reverse proxy.

## 📋 Prerequisites

- ✅ Google Cloud Platform account
- ✅ Docker and Docker Compose installed
- ✅ Google Cloud SDK (`gcloud`) installed and configured
- ✅ Caddy web server configured (as per your Caddyfile)
- ✅ Domain DNS pointing to your GCE machine

## 🔧 Setup Steps

### 1. Environment Configuration

Create your production environment file:

```bash
# Copy the template
cp production.env .env

# Edit with your actual values
nano .env
```

Required environment variables:
```bash
SECRET_KEY=your-super-secret-key-here
DB_PASSWORD=your-secure-database-password
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

### 2. Google Container Registry Authentication

```bash
# Authenticate Docker with GCR
gcloud auth configure-docker us-central1-docker.pkg.dev

# Verify authentication
gcloud auth list
```

### 3. Deploy to Production

```bash
# Run the production deployment script
./deploy-production.sh
```

## 🏗️ Architecture

```
Internet → Caddy (admin.inatdrive.com) → Docker Compose → Backend API
                                        ↓
                                   PostgreSQL + Redis
```

### Service Mapping

| Service | Container | Port | External Access |
|---------|-----------|------|-----------------|
| **Backend API** | `fortaleza-backend` | 8080 | Via Caddy proxy |
| **Database** | `fortaleza-db` | 5432 | Direct (optional) |
| **Redis** | `fortaleza-redis` | 6379 | Direct (optional) |
| **Frontend** | `fortaleza-frontend` | 8081 | Direct (optional) |

## 🌐 Caddy Integration

Your Caddyfile configuration:
```caddy
admin.inatdrive.com {
    reverse_proxy localhost:8080
    log {
        output file /var/log/caddy/admin.inatdrive.com.log
    }
}
```

This proxies `https://admin.inatdrive.com` to `http://localhost:8080` (your backend API).

## 🔍 Verification

### Health Checks

```bash
# Backend health
curl http://localhost:8080/api/health/

# Via Caddy (if DNS is configured)
curl https://admin.inatdrive.com/api/health/
```

### Service Status

```bash
# Check all services
docker-compose -f docker-compose.production.yml ps

# View logs
docker-compose -f docker-compose.production.yml logs -f
```

## 👤 Admin Setup

```bash
# Create superuser
docker-compose -f docker-compose.production.yml exec web python manage.py createsuperuser

# Access admin panel
# https://admin.inatdrive.com/admin/
```

## 🔧 Management Commands

### Start Services
```bash
docker-compose -f docker-compose.production.yml up -d
```

### Stop Services
```bash
docker-compose -f docker-compose.production.yml down
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.production.yml logs -f

# Specific service
docker-compose -f docker-compose.production.yml logs -f web
```

### Update Services
```bash
# Pull latest images and restart
docker-compose -f docker-compose.production.yml pull
docker-compose -f docker-compose.production.yml up -d
```

## 🛡️ Security Considerations

### Environment Variables
- ✅ Use strong, unique passwords
- ✅ Keep `.env` file secure (not in version control)
- ✅ Rotate secrets regularly

### Network Security
- ✅ Only expose necessary ports
- ✅ Use Caddy for SSL termination
- ✅ Configure firewall rules on GCE

### Database Security
- ✅ Use strong database passwords
- ✅ Regular backups
- ✅ Monitor access logs

## 📊 Monitoring

### Logs
- **Application logs**: `docker-compose logs -f web`
- **Caddy logs**: `/var/log/caddy/admin.inatdrive.com.log`
- **System logs**: `journalctl -u docker`

### Health Monitoring
- **Backend**: `http://localhost:8080/api/health/`
- **Database**: `docker-compose exec db pg_isready`
- **Redis**: `docker-compose exec redis redis-cli ping`

## 🔄 Backup Strategy

### Database Backup
```bash
# Create backup
docker-compose -f docker-compose.production.yml exec db pg_dump -U postgres basketball_analytics > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
docker-compose -f docker-compose.production.yml exec -T db psql -U postgres basketball_analytics < backup_file.sql
```

### Media Files Backup
```bash
# Backup media files
docker cp fortaleza-backend:/app/media ./media_backup_$(date +%Y%m%d_%H%M%S)
```

## 🚨 Troubleshooting

### Common Issues

1. **Services won't start**
   ```bash
   # Check logs
   docker-compose -f docker-compose.production.yml logs
   
   # Check environment variables
   cat .env
   ```

2. **Database connection issues**
   ```bash
   # Check database status
   docker-compose -f docker-compose.production.yml exec db pg_isready
   
   # Check database logs
   docker-compose -f docker-compose.production.yml logs db
   ```

3. **Caddy proxy issues**
   ```bash
   # Check Caddy status
   systemctl status caddy
   
   # Check Caddy logs
   tail -f /var/log/caddy/admin.inatdrive.com.log
   ```

### Performance Issues

1. **High memory usage**
   ```bash
   # Check container resource usage
   docker stats
   ```

2. **Slow database queries**
   ```bash
   # Check database logs
   docker-compose -f docker-compose.production.yml logs db
   ```

## 📈 Scaling

### Horizontal Scaling
- Use load balancer in front of Caddy
- Scale backend containers
- Use external database (Cloud SQL)

### Vertical Scaling
- Increase GCE machine resources
- Optimize database configuration
- Add Redis clustering

---

**Your Fortaleza Basketball Analytics platform is now ready for production!** 🏀🚀
