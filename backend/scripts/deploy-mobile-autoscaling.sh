#!/bin/bash

# Deploy Mobile Autoscaling Fix Script
# This script deploys the mobile autoscaling fixes to production

set -e

echo "🚀 Fortaleza Basketball - Deploy Mobile Autoscaling Fix"
echo "====================================================="

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
log_step "Step 1: Pulling latest frontend image with autoscaling fixes..."
log_info "Pulling frontend image with mobile autoscaling..."

if docker pull us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest; then
    log_success "Frontend image pulled successfully"
else
    log_error "Failed to pull frontend image"
fi

# Step 2: Restart frontend service
log_step "Step 2: Restarting frontend service..."
log_info "Restarting frontend container with new image..."

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
log_step "Step 4: Verifying mobile autoscaling deployment..."

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
echo "====================================================="
log_success "🎉 Mobile autoscaling fix deployed successfully!"
echo ""
log_info "📱 What's Fixed:"
echo "   • EXTREME mobile detection (≤1400px width or ≤800px height)"
echo "   • Ultra-lenient minimum dimensions (280x200px)"
echo "   • Automatic scaling for mobile devices"
echo "   • No more 'Window Size Too Small' warnings on mobile"
echo "   • Better landscape orientation support"
echo ""
log_info "🔧 Technical Changes:"
echo "   • JavaScript mobile detection: ≤1400px width or ≤800px height"
echo "   • Flutter mobile detection: ≤1400px width or ≤800px height"
echo "   • CSS media queries: @media (max-width: 1400px)"
echo "   • Autoscaling function: scale content to fit screen"
echo "   • Minimum scale: 30% (prevents content from being too small)"
echo ""
log_info "📱 Mobile Testing:"
echo "   • Test on various mobile devices and orientations"
echo "   • Verify no 'Window Size Too Small' warnings appear"
echo "   • Check that content scales appropriately"
echo "   • Test sidebar toggle functionality"
echo ""
log_info "🌐 Access Your Application:"
echo "   • Frontend: http://your-domain.com"
echo "   • Test on mobile: Use Chrome DevTools mobile simulation"
echo ""
log_success "Mobile autoscaling is now active! 🏀📱"
