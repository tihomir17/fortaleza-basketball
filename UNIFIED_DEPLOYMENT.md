# 🏀 Fortaleza Basketball Analytics - Unified Deployment

## 🎯 Overview

This repository now includes a **unified deployment setup** that deploys both the backend API and frontend web application together using Docker Compose. This optimizes deployment by:

- ✅ **Single Command Deployment**: Deploy everything with one script
- ✅ **Unified Nginx Configuration**: One reverse proxy for both backend and frontend
- ✅ **Optimized Resource Usage**: Shared infrastructure and networking
- ✅ **Simplified Management**: One docker-compose.yml for all services
- ✅ **Production Ready**: Includes health checks, monitoring, and security

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Git (to clone the repository)

### Deploy Everything
```bash
# Clone the repository
git clone <your-repo-url>
cd fortaleza-basketball/backend

# Deploy with one command
./deploy-unified.sh

# Create admin user
docker-compose exec web python manage.py createsuperuser
```

That's it! Your complete basketball analytics platform is now running.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Nginx (Port 80/443)                     │
│                   Reverse Proxy & Load Balancer            │
└─────────────────┬───────────────────────────────────────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
    ▼             ▼             ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Backend │ │Frontend │ │  Other  │
│  API    │ │  Web    │ │Services │
│ :8000   │ │  :80    │ │         │
└─────────┘ └─────────┘ └─────────┘
    │             │
    ▼             ▼
┌─────────┐ ┌─────────┐
│PostgreSQL│ │  Redis  │
│  :5432   │ │  :6379  │
└─────────┘ └─────────┘
```

## 📦 Services Included

| Service | Description | Port | Health Check |
|---------|-------------|------|--------------|
| **nginx** | Reverse proxy serving both backend and frontend | 80/443 | Built-in |
| **web** | Django backend API | 8000 | `/api/health/` |
| **frontend** | Flutter web application | 80 | `/health` |
| **db** | PostgreSQL database | 5432 | `pg_isready` |
| **redis** | Redis cache | 6379 | `redis-cli ping` |

## 🌐 Access Points

After deployment, access your application at:

- **🏠 Main Application**: `http://localhost`
- **🔧 API Endpoints**: `http://localhost/api/`
- **👨‍💼 Admin Panel**: `http://localhost/admin/`
- **❤️ Health Checks**:
  - Backend: `http://localhost/api/health/`
  - Frontend: `http://localhost/health`

## 🔧 Configuration

### Environment Variables
Set these before deployment (optional for development):

```bash
export SECRET_KEY="your-secret-key-here"
export DB_PASSWORD="your-db-password"
export EMAIL_HOST_USER="your-email@domain.com"
export EMAIL_HOST_PASSWORD="your-email-password"
```

### Domain Configuration
For production with a custom domain, update `docker-compose.yml`:

```yaml
labels:
  - "traefik.http.routers.frontend.rule=Host(`your-domain.com`)"
```

## 📋 Deployment Commands

### Basic Deployment
```bash
./deploy-unified.sh
```

### Clean Deployment (rebuilds all images)
```bash
./deploy-unified.sh --clean
```

### Manual Docker Compose
```bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 🔍 Monitoring & Maintenance

### Health Checks
```bash
# Check all services
docker-compose ps

# Test backend health
curl http://localhost/api/health/

# Test frontend health
curl http://localhost/health
```

### Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f frontend
docker-compose logs -f nginx
```

### Updates
```bash
# Pull latest changes
git pull

# Rebuild and redeploy
./deploy-unified.sh --clean
```

## 🛠️ Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using port 80
   sudo lsof -i :80
   
   # Stop conflicting services
   sudo systemctl stop apache2  # or nginx
   ```

2. **Build Failures**
   ```bash
   # Clean everything and rebuild
   docker-compose down
   docker system prune -f
   ./deploy-unified.sh --clean
   ```

3. **Database Connection Issues**
   ```bash
   # Check database logs
   docker-compose logs db
   
   # Restart database
   docker-compose restart db
   ```

### Performance Optimization

1. **Enable Gzip Compression**: Already configured in nginx
2. **Static File Caching**: Already configured
3. **Database Indexing**: Run migrations to ensure proper indexing
4. **Redis Caching**: Already configured for session and cache storage

## 🔒 Security Features

- ✅ **Security Headers**: X-Frame-Options, X-XSS-Protection, etc.
- ✅ **CORS Configuration**: Properly configured for API access
- ✅ **SSL Ready**: Traefik labels for automatic SSL
- ✅ **Hidden Files Protection**: Denies access to sensitive files
- ✅ **Health Check Endpoints**: For monitoring and load balancers

## 📊 Production Considerations

### Scaling
- Use a load balancer (nginx, traefik, etc.)
- Scale horizontally with multiple container instances
- Use external database and Redis for high availability

### Backup
- Database: Regular PostgreSQL backups
- Media files: Backup the `media_volume`
- Configuration: Version control all config files

### Monitoring
- Set up log aggregation (ELK stack, etc.)
- Monitor resource usage (CPU, memory, disk)
- Set up alerts for health check failures

## 🎉 Benefits of Unified Deployment

1. **Simplified Operations**: One command deploys everything
2. **Consistent Environment**: Same setup for dev, staging, and production
3. **Resource Efficiency**: Shared infrastructure reduces overhead
4. **Easy Scaling**: Scale all services together
5. **Unified Monitoring**: Single point for health checks and logs
6. **Simplified Networking**: Internal service communication optimized

## 📞 Support

For issues or questions:
1. Check the logs: `docker-compose logs -f`
2. Verify health checks: `curl http://localhost/health`
3. Review this documentation
4. Check the individual service documentation in `backend/DEPLOYMENT.md` and `frontend/DEPLOYMENT.md`

---

**Your Fortaleza Basketball Analytics platform is now ready for production!** 🏀🚀
