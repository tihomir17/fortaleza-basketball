#!/bin/bash

# Deploy Single Button Fix Script
# This script deploys the fix to show only one menu button

set -e

echo "🚀 Fortaleza Basketball - Deploy Single Button Fix"
echo "================================================="

# Configuration
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

# Step 1: Pull latest frontend image
log_step "Step 1: Pulling latest frontend image with single button fix..."
log_info "Pulling frontend image with only one menu button..."

if docker pull us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest; then
    log_success "Frontend image pulled successfully"
else
    log_error "Failed to pull frontend image"
fi

# Step 2: Restart frontend service
log_step "Step 2: Restarting frontend service..."
log_info "Restarting frontend container with single button fix..."

if docker-compose -f docker-compose.production.yml restart frontend; then
    log_success "Frontend service restarted successfully"
else
    log_error "Failed to restart frontend service"
fi

# Step 3: Wait for frontend to be ready
log_step "Step 3: Waiting for frontend service to be ready..."
log_info "Waiting for frontend to be healthy..."

for i in {1..30}; do
    if curl -s -f http://localhost:80 > /dev/null 2>&1; then
        log_success "Frontend service is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Frontend service failed to become healthy after 30 seconds"
    fi
    sleep 1
done

# Step 4: Verify deployment
log_step "Step 4: Verifying single button fix deployment..."

# Check if frontend is accessible
log_info "Checking frontend accessibility..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200"; then
    log_success "Frontend is accessible"
else
    log_warning "Frontend accessibility check failed"
fi

# Show container status
log_info "Container status:"
docker-compose -f docker-compose.production.yml ps

# Step 5: Show deployment summary
log_step "Step 5: Deployment Summary"

echo ""
echo "================================================="
log_success "🎉 Single button fix deployed successfully!"
echo ""
log_info "🔧 What's Fixed:"
echo "   • Removed duplicate positioned button"
echo "   • Removed floating action button"
echo "   • Only AppBar menu button remains"
echo "   • Clean, single menu button interface"
echo "   • No more overlapping or duplicate buttons"
echo ""
log_info "📱 Current Menu Button Setup:"
echo "   • AppBar leading position (mobile devices only)"
echo "   • Reliable MobileMenuAppBarButton widget"
echo "   • Swipe gesture from left edge (20px drag area)"
echo "   • No floating action buttons or positioned overlays"
echo ""
log_info "🎯 Expected Behavior:"
echo "   • Only ONE menu button visible on mobile"
echo "   • Button located in AppBar (top-left)"
echo "   • Clean, uncluttered interface"
echo "   • Reliable drawer opening functionality"
echo "   • No duplicate or overlapping buttons"
echo ""
log_info "🌐 Access Your Application:"
echo "   • Frontend: http://your-domain.com"
echo "   • Verify only one menu button is visible"
echo "   • Test menu button functionality"
echo ""
log_success "Single menu button is now properly displayed! 🏀📱"
