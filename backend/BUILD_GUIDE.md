# 🏗️ Build Guide - Fortaleza Basketball Analytics

## 🚀 Quick Build Commands

Since Docker is not available on this system, here are the commands to run on your deployment server:

### Option 1: Build All Services
```bash
cd fortaleza-basketball/backend
./build-all.sh
```

### Option 2: Manual Docker Compose Build
```bash
cd fortaleza-basketball/backend

# Build all services
docker-compose build

# Or with newer Docker Compose syntax
docker compose build
```

### Option 3: Build with Clean (removes old images)
```bash
./build-all.sh --clean
```

## 📦 What Gets Built

The unified build process creates these Docker images:

| Service | Image | Description |
|---------|-------|-------------|
| **web** | `fortaleza-basketball-analytics_web` | Django backend API |
| **frontend** | `fortaleza-basketball-analytics_frontend` | Flutter web application |
| **nginx** | `fortaleza-basketball-analytics_nginx` | Unified reverse proxy |
| **db** | `postgres:15` | PostgreSQL database |
| **redis** | `redis:7-alpine` | Redis cache |

## 🔧 Build Process Details

### Backend Build (Django)
- Installs Python dependencies from `requirements.txt`
- Sets up Django application
- Configures production settings
- Prepares static files

### Frontend Build (Flutter)
- Installs Flutter SDK
- Gets Flutter dependencies
- Builds Flutter web app for production
- Creates optimized static files

### Nginx Build
- Configures unified reverse proxy
- Sets up routing for both backend and frontend
- Configures security headers and caching

## 📊 Build Output

After successful build, you'll see:
```
✅ All Docker images built successfully!

Built images:
fortaleza-basketball-analytics_web     latest    [size]
fortaleza-basketball-analytics_frontend latest    [size]
fortaleza-basketball-analytics_nginx   latest    [size]
postgres:15                            latest    [size]
redis:7-alpine                         latest    [size]
```

## 🚀 After Build - Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Create admin user
docker-compose exec web python manage.py createsuperuser
```

## 🔍 Troubleshooting

### Build Fails
```bash
# Check Docker is running
docker --version
docker-compose --version

# Clean and rebuild
./build-all.sh --clean

# Check logs
docker-compose logs
```

### Out of Space
```bash
# Clean up unused images
docker system prune -f

# Remove specific images
docker rmi fortaleza-basketball-analytics_web
```

### Permission Issues
```bash
# Make scripts executable
chmod +x build-all.sh
chmod +x deploy-unified.sh
```

## 📋 Build Checklist

Before building:
- [ ] Docker and Docker Compose installed
- [ ] Sufficient disk space (at least 2GB free)
- [ ] Network access for downloading base images
- [ ] All source code is present

After building:
- [ ] All images built successfully
- [ ] No build errors in logs
- [ ] Images are properly tagged
- [ ] Ready for deployment

## 🎯 Next Steps

1. **Build**: Run `./build-all.sh`
2. **Deploy**: Run `./deploy-unified.sh`
3. **Verify**: Check health endpoints
4. **Configure**: Set up admin user
5. **Test**: Verify all functionality

---

**Your Fortaleza Basketball Analytics platform is ready to build and deploy!** 🏀🚀
