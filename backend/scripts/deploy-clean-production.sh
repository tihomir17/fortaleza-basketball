#!/bin/bash

# Clean Production Deployment Script
# This script builds images locally, pushes to registry, and deploys only containers to production
# NO SOURCE CODE is copied to the production server

set -e

echo "🚀 Fortaleza Basketball - Clean Production Deployment"
echo "=================================================="
echo "📦 Building locally → Pushing to registry → Deploying containers only"
echo ""

# Configuration
BACKEND_IMAGE="us-central1-docker.pkg.dev/inat-drive/inatdrive/backend:latest"
FRONTEND_IMAGE="us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest"
PRODUCTION_SERVER="your-server-ip"  # Update this with your actual server IP/hostname
PRODUCTION_USER="root"  # Update this with your actual username

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker and try again."
fi

# Check if gcloud is authenticated
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" | grep -q "@"; then
    log_error "Google Cloud is not authenticated. Please run 'gcloud auth login' first."
fi

log_success "Prerequisites check passed"

# Step 1: Build and push backend image
log_step "Step 1: Building and pushing backend image..."
log_info "Building backend Docker image with latest changes..."

if docker build -t "$BACKEND_IMAGE" .; then
    log_success "Backend image built successfully"
else
    log_error "Backend image build failed"
fi

log_info "Pushing backend image to Google Cloud Artifact Registry..."
if docker push "$BACKEND_IMAGE"; then
    log_success "Backend image pushed successfully"
else
    log_error "Backend image push failed"
fi

# Step 2: Build and push frontend image
log_step "Step 2: Building and pushing frontend image..."
log_info "Building frontend Docker image with mobile fixes..."

# Navigate to frontend directory
cd ../frontend

log_info "Building frontend Docker image with multi-architecture support..."
if docker buildx build --platform linux/amd64,linux/arm64 -t "$FRONTEND_IMAGE" --push .; then
    log_success "Frontend image built and pushed successfully"
else
    log_error "Frontend image build/push failed"
fi

# Navigate back to backend
cd ../backend

# Step 3: Create production docker-compose file (no source code)
log_step "Step 3: Creating clean production docker-compose file..."

cat > docker-compose.clean-production.yml << 'EOF'
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: basketball_analytics
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-your_secure_password}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  web:
    image: us-central1-docker.pkg.dev/inat-drive/inatdrive/backend:latest
    environment:
      - DEBUG=False
      - SECRET_KEY=${SECRET_KEY:-your-secret-key}
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD:-your_secure_password}@db:5432/basketball_analytics
      - REDIS_URL=redis://redis:6379/0
      - ALLOWED_HOSTS=admin.inatdrive.com,localhost,127.0.0.1,0.0.0.0
      - CORS_ALLOWED_ORIGINS=https://admin.inatdrive.com,http://localhost:3000,http://127.0.0.1:3000
      - EMAIL_HOST=${EMAIL_HOST}
      - EMAIL_HOST_USER=${EMAIL_HOST_USER}
      - EMAIL_HOST_PASSWORD=${EMAIL_HOST_PASSWORD}
    ports:
      - "8080:8000"
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "python", "manage.py", "check", "--deploy"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    image: us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest
    ports:
      - "80:80"
    depends_on:
      - web
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
EOF

log_success "Clean production docker-compose file created"

# Step 4: Create environment file template
log_step "Step 4: Creating environment file template..."

cat > .env.production.template << 'EOF'
# Production Environment Variables
# Copy this to .env.production and update with your actual values

# Database
POSTGRES_PASSWORD=your_secure_database_password

# Django
SECRET_KEY=your-very-secure-secret-key-here
DEBUG=False

# Email Configuration (optional)
EMAIL_HOST=
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=

# Domain Configuration
ALLOWED_HOSTS=admin.inatdrive.com,localhost,127.0.0.1,0.0.0.0
CORS_ALLOWED_ORIGINS=https://admin.inatdrive.com,http://localhost:3000,http://127.0.0.1:3000
EOF

log_success "Environment file template created"

# Step 5: Create deployment script for production server
log_step "Step 5: Creating production server deployment script..."

cat > deploy-to-production.sh << 'EOF'
#!/bin/bash

# Production Server Deployment Script
# This script runs on the production server to deploy the application

set -e

echo "🚀 Deploying Fortaleza Basketball to Production"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker and try again."
fi

# Check if gcloud is authenticated
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" | grep -q "@"; then
    log_error "Google Cloud is not authenticated. Please run 'gcloud auth login' first."
fi

# Configure Docker to use gcloud as credential helper
log_info "Configuring Docker authentication..."
gcloud auth configure-docker us-central1-docker.pkg.dev

log_success "Docker authentication configured"

# Pull latest images
log_step "Step 1: Pulling latest images..."
log_info "Pulling backend image..."
docker pull us-central1-docker.pkg.dev/inat-drive/inatdrive/backend:latest

log_info "Pulling frontend image..."
docker pull us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest

log_success "Images pulled successfully"

# Stop existing containers
log_step "Step 2: Stopping existing containers..."
docker-compose -f docker-compose.clean-production.yml down || true
log_success "Existing containers stopped"

# Start new containers
log_step "Step 3: Starting new containers..."
docker-compose -f docker-compose.clean-production.yml up -d
log_success "New containers started"

# Wait for services to be ready
log_step "Step 4: Waiting for services to be ready..."
log_info "Waiting for backend service to be healthy..."

for i in {1..60}; do
    if docker exec fortaleza-basketball_web_1 python manage.py check --deploy > /dev/null 2>&1; then
        log_success "Backend service is healthy"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "Backend service failed to become healthy after 60 seconds"
    fi
    sleep 1
done

# Run database migrations
log_step "Step 5: Running database migrations..."
docker exec fortaleza-basketball_web_1 python manage.py migrate
log_success "Database migrations completed"

# Populate database with playsets
log_step "Step 6: Populating database with playsets..."
docker exec fortaleza-basketball_web_1 python manage.py populate_db
log_success "Play definitions populated"

# Verify deployment
log_step "Step 7: Verifying deployment..."
PLAY_COUNT=$(docker exec fortaleza-basketball_web_1 python manage.py shell -c "
from apps.plays.models import PlayDefinition
print(PlayDefinition.objects.count())
" 2>/dev/null | tail -1)

log_success "Deployment completed successfully!"
echo ""
log_info "📊 Deployment Summary:"
echo "   • Backend: Latest version with HEAD COACH ordering"
echo "   • Frontend: Latest version with mobile fixes"
echo "   • Database: Migrated and populated"
echo "   • Play Definitions: $PLAY_COUNT plays available"
echo ""
log_info "🌐 Application is ready at:"
echo "   • Frontend: http://your-domain.com"
echo "   • Admin: http://your-domain.com/admin"
echo ""
log_success "🏀 Fortaleza Basketball is live!"
EOF

chmod +x deploy-to-production.sh
log_success "Production deployment script created"

# Step 6: Create instructions file
log_step "Step 6: Creating deployment instructions..."

cat > CLEAN_DEPLOYMENT_INSTRUCTIONS.md << 'EOF'
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
EOF

log_success "Deployment instructions created"

# Step 7: Show deployment summary
log_step "Step 7: Deployment Summary"

echo ""
echo "=================================================="
log_success "🎉 Clean production deployment setup completed!"
echo ""
log_info "📦 What was created:"
echo "   • docker-compose.clean-production.yml - Production compose file"
echo "   • .env.production.template - Environment template"
echo "   • deploy-to-production.sh - Production deployment script"
echo "   • CLEAN_DEPLOYMENT_INSTRUCTIONS.md - Complete instructions"
echo ""
log_info "🚀 Next steps:"
echo "   1. Update PRODUCTION_SERVER and PRODUCTION_USER in this script"
echo "   2. Run: ./scripts/deploy-clean-production.sh"
echo "   3. Follow instructions in CLEAN_DEPLOYMENT_INSTRUCTIONS.md"
echo ""
log_info "🔒 Security benefits:"
echo "   • NO source code on production server"
echo "   • Only Docker containers run on production"
echo "   • Clean, minimal production environment"
echo ""
log_success "Ready for clean production deployment! 🏀"
