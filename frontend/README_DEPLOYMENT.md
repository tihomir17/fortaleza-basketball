# 🏀 Fortaleza Basketball Analytics - Frontend Deployment Ready!

## 🚀 Quick Start

Your frontend is now **deploy-ready**! Here's everything you need to deploy:

### 📦 What's Included

✅ **Docker Configuration**
- `Dockerfile` - Multi-stage build with Flutter and Nginx
- `docker-compose.yml` - Complete service orchestration
- `nginx.conf` - Production-ready web server configuration

✅ **Deployment Scripts**
- `deploy.sh` - One-command deployment script
- `build.sh` - Flutter build script (if Flutter is available locally)

✅ **Documentation**
- `DEPLOYMENT.md` - Comprehensive deployment guide
- `DEPLOYMENT_CHECKLIST.md` - Step-by-step deployment checklist
- `production.env` - Environment configuration template

✅ **Production Optimizations**
- Gzip compression enabled
- Static asset caching (1 year)
- Security headers configured
- Health check endpoint (`/health`)
- PWA manifest updated
- Window constraints for web app

## 🎯 Deployment Commands

### Option 1: One-Command Deployment (Recommended)
```bash
./deploy.sh
```

### Option 2: Manual Docker Build
```bash
docker build -t fortaleza-frontend .
docker-compose up -d
```

### Option 3: With Clean Build
```bash
./deploy.sh --clean
```

## 🔧 Pre-Deployment Configuration

Before deploying, update these files:

1. **API Configuration**: Update `flutter_app/lib/core/api/api_client.dart` with your backend URL
2. **Domain**: Update `docker-compose.yml` Traefik labels with your domain
3. **Environment**: Update `production.env` with your production values

## 📊 Features Ready for Production

✅ **Performance**
- Optimized Flutter web build
- Nginx with gzip compression
- Static asset caching
- HTML renderer for better compatibility

✅ **Security**
- Security headers (X-Frame-Options, X-XSS-Protection, etc.)
- Hidden file access denied
- CORS handled by backend
- Production environment variables

✅ **Monitoring**
- Health check endpoint
- Nginx access/error logs
- Docker container monitoring
- Service status checks

✅ **Scalability**
- Docker containerization
- Load balancer ready (Traefik labels)
- Horizontal scaling support
- CDN-ready static assets

## 🌐 Access Points

After deployment:
- **Main App**: `http://your-server:8080`
- **Health Check**: `http://your-server:8080/health`
- **With Domain**: `https://your-domain.com` (if configured)

## 📋 Next Steps

1. **Upload** the entire `frontend/` directory to your server
2. **Configure** API URLs and domain settings
3. **Run** `./deploy.sh` on your server
4. **Verify** deployment with health checks
5. **Test** all application features

## 🆘 Support

If you encounter issues:
1. Check `DEPLOYMENT_CHECKLIST.md` for troubleshooting
2. Review logs: `docker-compose logs -f`
3. Verify health: `curl http://localhost:8080/health`

## 🎉 Ready to Deploy!

Your Fortaleza Basketball Analytics frontend is now production-ready with:
- ✅ Docker containerization
- ✅ Production optimizations
- ✅ Security configurations
- ✅ Monitoring and health checks
- ✅ Comprehensive documentation
- ✅ One-command deployment

**Happy Deploying!** 🚀🏀



Procedura deploy-a:
One time cmd lokalno za authentifikaciju dokera i auth registry:
gcloud auth configure-docker us-central1-docker.pkg.dev

iz backenda na svaku izmjenu koju hoces da deploy

docker build . -t backend -f Dockerfile
docker tag backend us-central1-docker.pkg.dev/inat-drive/inatdrive/backend
docker push us-central1-docker.pkg.dev/inat-drive/inatdrive/backend

iz frontenda na svaku izmjenu koju hoces da deploy

docker build . -t frontend -f Dockerfile
docker tag frontend us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend
docker push us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend
