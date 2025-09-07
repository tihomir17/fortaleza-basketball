# 🚀 Clean Production Deployment Instructions

## Overview
This deployment approach ensures **NO SOURCE CODE** is stored on your production server. Only Docker containers run on production.

## What Gets Deployed
- ✅ **Backend**: Latest version with HEAD COACH ordering fixes
- ✅ **Frontend**: Latest version with mobile sidebar fixes
- ✅ **Database**: PostgreSQL with all migrations and play definitions
- ✅ **Redis**: For caching and session management

## Prerequisites
1. **Local Machine**: Docker, gcloud CLI, and source code
2. **Production Server**: Docker, gcloud CLI, and network access
3. **Google Cloud**: Artifact Registry access configured

## Deployment Steps

### Step 1: Build and Push Images (Local Machine)
```bash
# Run this script on your local machine
./scripts/deploy-clean-production.sh
```

This will:
- Build backend and frontend Docker images
- Push images to Google Cloud Artifact Registry
- Create deployment files for production

### Step 2: Deploy to Production Server
```bash
# Copy deployment files to production server
scp docker-compose.clean-production.yml root@your-server:/root/
scp .env.production.template root@your-server:/root/
scp deploy-to-production.sh root@your-server:/root/

# SSH into production server
ssh root@your-server

# Configure environment
cp .env.production.template .env.production
# Edit .env.production with your actual values

# Run deployment
chmod +x deploy-to-production.sh
./deploy-to-production.sh
```

## What's on Production Server
- ✅ **Docker containers only** (no source code)
- ✅ **Environment configuration** (.env.production)
- ✅ **Docker Compose file** (docker-compose.clean-production.yml)
- ✅ **Deployment script** (deploy-to-production.sh)

## What's NOT on Production Server
- ❌ **No source code files**
- ❌ **No Python/Dart source files**
- ❌ **No build artifacts**
- ❌ **No development tools**

## Updating the Application
To update the application:

1. **Make changes locally**
2. **Run the build script**: `./scripts/deploy-clean-production.sh`
3. **Deploy to production**: `./deploy-to-production.sh` (on production server)

## Security Benefits
- ✅ **No source code exposure** on production server
- ✅ **Containerized application** with minimal attack surface
- ✅ **Environment variables** for sensitive configuration
- ✅ **Health checks** for all services
- ✅ **Automatic restarts** on failure

## Monitoring
- **Backend Health**: `docker exec fortaleza-basketball_web_1 python manage.py check --deploy`
- **Frontend Health**: `curl -f http://localhost:80`
- **Database Health**: `docker exec fortaleza-basketball_db_1 pg_isready -U postgres`
- **Redis Health**: `docker exec fortaleza-basketball_redis_1 redis-cli ping`

## Troubleshooting
- **Container logs**: `docker-compose -f docker-compose.clean-production.yml logs`
- **Restart services**: `docker-compose -f docker-compose.clean-production.yml restart`
- **Full reset**: `docker-compose -f docker-compose.clean-production.yml down && ./deploy-to-production.sh`
