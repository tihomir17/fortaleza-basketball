# Fortaleza Basketball Analytics - Unified Deployment Guide

This guide covers deploying the complete Fortaleza Basketball Analytics application (backend + frontend) to production.

## Prerequisites

- Docker and Docker Compose
- Domain name (optional, for production)
- SSL Certificate (optional, for HTTPS)

## 🚀 Quick Unified Deployment

The easiest way to deploy both backend and frontend together:

```bash
# Clone the repository
git clone <your-repo-url>
cd fortaleza-basketball/backend

# Set environment variables (optional for development)
export SECRET_KEY="your-secret-key-here"
export DB_PASSWORD="your-db-password"
export EMAIL_HOST_USER="your-email@domain.com"
export EMAIL_HOST_PASSWORD="your-email-password"

# Deploy everything with one command
./deploy-unified.sh

# Create superuser
docker-compose exec web python manage.py createsuperuser
```

## 🎯 What Gets Deployed

The unified deployment includes:

- **Backend API** (Django + PostgreSQL + Redis)
- **Frontend** (Flutter Web App)
- **Nginx** (Reverse proxy serving both backend and frontend)
- **Database** (PostgreSQL with persistent storage)
- **Cache** (Redis for performance)

## 🌐 Access Points

After deployment:
- **Main Application**: `http://localhost` (or your domain)
- **API Endpoints**: `http://localhost/api/`
- **Admin Panel**: `http://localhost/admin/`
- **Health Checks**:
  - Backend: `http://localhost/api/health/`
  - Frontend: `http://localhost/health`

## Manual Deployment

### 1. Install Dependencies

```bash
# Install Python dependencies
pip install -r requirements.txt
pip install gunicorn

# Install system dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib redis-server nginx
```

### 2. Setup Database

```bash
# Create PostgreSQL database
sudo -u postgres createdb basketball_analytics

# Run the setup script
python setup_database.py
```

### 3. Configure Environment Variables

Create a `.env` file:

```bash
# Database
DB_NAME=basketball_analytics
DB_USER=postgres
DB_PASSWORD=your-db-password
DB_HOST=localhost
DB_PORT=5432

# Redis
REDIS_URL=redis://localhost:6379/0

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@domain.com
EMAIL_HOST_PASSWORD=your-email-password
DEFAULT_FROM_EMAIL=noreply@yourdomain.com

# Security
SECRET_KEY=your-very-secure-secret-key-here

# Domain
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
```

### 4. Deploy Application

```bash
# Run the deployment script
python deploy.py

# Or manually:
python manage.py collectstatic --noinput
python manage.py migrate
python manage.py createsuperuser
```

### 5. Configure Web Server

The deployment script generates `nginx.conf` and `basketball-analytics.service` files.

```bash
# Copy systemd service
sudo cp basketball-analytics.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable basketball-analytics
sudo systemctl start basketball-analytics

# Configure Nginx
sudo cp nginx.conf /etc/nginx/sites-available/basketball-analytics
sudo ln -s /etc/nginx/sites-available/basketball-analytics /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Environment-Specific Settings

### Development
```bash
export DJANGO_SETTINGS_MODULE=basketball_analytics.settings
python manage.py runserver
```

### Production
```bash
export DJANGO_SETTINGS_MODULE=basketball_analytics.settings_production
gunicorn --bind 0.0.0.0:8000 --workers 3 basketball_analytics.wsgi:application
```

## Health Checks

The application provides several health check endpoints:

- `/api/health/` - General health check
- `/api/health/ready/` - Readiness check (for Kubernetes)
- `/api/health/live/` - Liveness check (for Kubernetes)

## Monitoring

### Performance Monitoring

The application includes built-in performance monitoring:

- Slow query logging (configurable threshold)
- Request performance tracking
- High query count detection
- Redis cache monitoring

### Logs

Logs are written to:
- `logs/app.log` - Application logs
- `logs/requests.log` - Request logs
- `logs/slow_queries.log` - Slow query logs

## Scaling

### Horizontal Scaling

For high-traffic deployments:

1. Use a load balancer (Nginx, HAProxy)
2. Run multiple Gunicorn workers
3. Use Redis for session storage
4. Consider database read replicas

### Vertical Scaling

- Increase Gunicorn workers: `--workers 4`
- Increase Redis memory
- Optimize PostgreSQL settings
- Use SSD storage

## Security

### SSL/TLS

1. Obtain SSL certificates (Let's Encrypt recommended)
2. Update Nginx configuration
3. Enable HTTPS redirects
4. Set security headers

### Database Security

1. Use strong passwords
2. Limit database access
3. Enable SSL connections
4. Regular backups

### Application Security

1. Keep dependencies updated
2. Use environment variables for secrets
3. Enable security headers
4. Regular security audits

## Backup Strategy

### Database Backups

```bash
# Daily backup script
pg_dump basketball_analytics > backup_$(date +%Y%m%d).sql

# Restore
psql basketball_analytics < backup_20240101.sql
```

### Media Files

```bash
# Backup media files
tar -czf media_backup_$(date +%Y%m%d).tar.gz media/
```

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Check PostgreSQL is running
   - Verify connection settings
   - Check firewall rules

2. **Redis Connection Errors**
   - Check Redis is running
   - Verify Redis configuration
   - Check memory usage

3. **Static Files Not Loading**
   - Run `collectstatic`
   - Check Nginx configuration
   - Verify file permissions

4. **Performance Issues**
   - Check slow query logs
   - Monitor Redis cache hit rate
   - Review database indexes

### Log Analysis

```bash
# View application logs
tail -f logs/app.log

# View slow queries
tail -f logs/slow_queries.log

# View systemd logs
journalctl -u basketball-analytics -f
```

## Maintenance

### Regular Tasks

1. **Weekly**
   - Review slow query logs
   - Check disk space
   - Update dependencies

2. **Monthly**
   - Database maintenance
   - Security updates
   - Performance review

3. **Quarterly**
   - Full security audit
   - Backup testing
   - Capacity planning

## Support

For deployment issues:

1. Check the logs
2. Review this documentation
3. Check the health endpoints
4. Contact the development team

## Performance Optimization

The application includes several performance optimizations:

- Database indexing
- Query optimization
- Redis caching
- Response compression
- Rate limiting
- Connection pooling

These optimizations are automatically enabled in production settings.
