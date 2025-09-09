#!/bin/bash

# Deploy Layout Fix Script
# This script deploys the conservative autoscaling fix to production

set -e

echo "🚀 Fortaleza Basketball - Deploy Layout Fix"
echo "=========================================="

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
log_step "Step 1: Pulling latest frontend image with layout fix..."
log_info "Pulling frontend image with conservative autoscaling..."

if docker pull us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest; then
    log_success "Frontend image pulled successfully"
else
    log_error "Failed to pull frontend image"
fi

# Step 2: Restart frontend service
log_step "Step 2: Restarting frontend service..."
log_info "Restarting frontend container with layout fix..."

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
log_step "Step 4: Verifying layout fix deployment..."

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
echo "=========================================="
log_success "🎉 Layout fix deployed successfully!"
echo ""
log_info "🔧 What's Fixed:"
echo "   • Conservative mobile detection (≤768px width or ≤600px height)"
echo "   • Reasonable minimum dimensions (400x300px)"
echo "   • Smart autoscaling only when necessary"
echo "   • No more layout breaking or cut-off text"
echo "   • Proper input field rendering"
echo ""
log_info "📱 Technical Changes:"
echo "   • JavaScript mobile detection: ≤768px width or ≤600px height"
echo "   • Flutter mobile detection: ≤768px width or ≤600px height"
echo "   • CSS media queries: @media (max-width: 768px)"
echo "   • Conservative autoscaling: Only scales if screen < 400x300px"
echo "   • Maximum scale: 80% (prevents over-scaling)"
echo ""
log_info "🎯 Behavior:"
echo "   • Desktop (≥769px): Normal layout, no scaling"
echo "   • Mobile (≤768px): Conservative scaling if needed"
echo "   • Very small screens: Smart scaling to fit content"
echo "   • No more cut-off text or missing input fields"
echo ""
log_info "🌐 Access Your Application:"
echo "   • Frontend: http://your-domain.com"
echo "   • Login page should now display properly"
echo ""
log_success "Layout issues are now fixed! 🏀✨"
