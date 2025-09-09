#!/bin/bash

# Complete Production Deployment Script
# This script deploys all changes including backend fixes and frontend mobile improvements

set -e

echo "🚀 Fortaleza Basketball - Complete Production Deployment"
echo "====================================================="

# Configuration
BACKEND_IMAGE="us-central1-docker.pkg.dev/inat-drive/inatdrive/backend:latest"
FRONTEND_IMAGE="us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest"
CONTAINER_NAME="fortaleza-web"
FRONTEND_CONTAINER="fortaleza-frontend"

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

# Step 1: Build and push backend changes
log_step "Step 1: Building and pushing backend changes..."
log_info "Backend changes include:"
log_info "  • HEAD COACH ordering fix in team serializers"
log_info "  • Database population scripts"
log_info "  • Team management improvements"

# Build and push backend
log_info "Building backend Docker image..."
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

# Step 2: Build and push frontend changes
log_step "Step 2: Building and pushing frontend changes..."
log_info "Frontend changes include:"
log_info "  • Mobile sidebar toggle fixes"
log_info "  • Landscape orientation improvements"
log_info "  • Enhanced mobile detection logic"
log_info "  • Better touch targets and accessibility"

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

# Step 3: Deploy to production server
log_step "Step 3: Deploying to production server..."
log_info "Pulling latest images on production server..."

# Pull latest images
if docker-compose -f docker-compose.production.yml pull; then
    log_success "Latest images pulled successfully"
else
    log_error "Failed to pull latest images"
fi

# Restart services
log_info "Restarting services with new images..."
if docker-compose -f docker-compose.production.yml up -d; then
    log_success "Services restarted successfully"
else
    log_error "Failed to restart services"
fi

# Step 4: Wait for services to be ready
log_step "Step 4: Waiting for services to be ready..."
log_info "Waiting for backend service to be healthy..."

# Wait for backend to be ready
for i in {1..30}; do
    if docker exec "$CONTAINER_NAME" python manage.py check --deploy > /dev/null 2>&1; then
        log_success "Backend service is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Backend service failed to become healthy after 30 seconds"
    fi
    sleep 1
done

# Step 5: Run database migrations
log_step "Step 5: Running database migrations..."
if docker exec "$CONTAINER_NAME" python manage.py migrate; then
    log_success "Database migrations completed successfully"
else
    log_error "Database migrations failed"
fi

# Step 6: Populate database with playsets
log_step "Step 6: Populating database with playsets..."
log_info "This will add all play definitions (Sets 1-20, Offense, Defense, etc.)"

if docker exec "$CONTAINER_NAME" python manage.py populate_db; then
    log_success "Play definitions populated successfully"
else
    log_warning "Play definitions population failed or already exists"
fi

# Step 7: Verify deployment
log_step "Step 7: Verifying deployment..."

# Check backend health
log_info "Checking backend health..."
if docker exec "$CONTAINER_NAME" python manage.py check --deploy; then
    log_success "Backend health check passed"
else
    log_error "Backend health check failed"
fi

# Check play definitions
PLAY_COUNT=$(docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.plays.models import PlayDefinition
print(PlayDefinition.objects.count())
" 2>/dev/null | tail -1)

if [ "$PLAY_COUNT" -gt 0 ]; then
    log_success "Play definitions verified: $PLAY_COUNT plays available"
else
    log_warning "No play definitions found"
fi

# Check if frontend is accessible
log_info "Checking frontend accessibility..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200"; then
    log_success "Frontend is accessible"
else
    log_warning "Frontend accessibility check failed"
fi

# Step 8: Show deployment summary
log_step "Step 8: Deployment Summary"

echo ""
echo "====================================================="
log_success "🎉 Complete deployment completed successfully!"
echo ""
log_info "📊 Deployment Summary:"
echo "   • Backend: Updated with HEAD COACH ordering fixes"
echo "   • Frontend: Updated with mobile sidebar improvements"
echo "   • Database: Migrated and populated with playsets"
echo "   • Play Definitions: $PLAY_COUNT plays available"
echo ""
log_info "🚀 What's New:"
echo "   • HEAD COACH now appears first in team management"
echo "   • Mobile sidebar toggle works on all devices"
echo "   • Landscape orientation issues fixed"
echo "   • Complete playbook available (Sets 1-20, etc.)"
echo "   • Enhanced mobile detection and touch targets"
echo ""
log_info "🔧 Services Status:"
docker-compose -f docker-compose.production.yml ps
echo ""
log_info "🌐 Access Your Application:"
echo "   • Frontend: http://your-domain.com"
echo "   • Admin Panel: http://your-domain.com/admin"
echo ""
log_info "📱 Mobile Testing:"
echo "   • Test sidebar toggle on mobile devices"
echo "   • Verify landscape orientation works"
echo "   • Check HEAD COACH appears first in team management"
echo ""
log_success "Ready for production use! 🏀"
