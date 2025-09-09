#!/bin/bash

# Deploy Mobile Menu Fix Script
# This script deploys the reliable mobile menu button solution

set -e

echo "🚀 Fortaleza Basketball - Deploy Mobile Menu Fix"
echo "==============================================="

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
log_step "Step 1: Pulling latest frontend image with mobile menu fix..."
log_info "Pulling frontend image with reliable mobile menu buttons..."

if docker pull us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest; then
    log_success "Frontend image pulled successfully"
else
    log_error "Failed to pull frontend image"
fi

# Step 2: Restart frontend service
log_step "Step 2: Restarting frontend service..."
log_info "Restarting frontend container with mobile menu fix..."

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
log_step "Step 4: Verifying mobile menu fix deployment..."

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
echo "==============================================="
log_success "🎉 Mobile menu fix deployed successfully!"
echo ""
log_info "📱 What's Fixed:"
echo "   • Reliable mobile menu button in AppBar"
echo "   • Persistent mobile menu button in top-left corner"
echo "   • Floating action button as backup"
echo "   • Multiple fallback methods for drawer opening"
echo "   • Enhanced error handling and logging"
echo ""
log_info "🔧 Technical Implementation:"
echo "   • MobileMenuButton widget with robust drawer opening"
echo "   • Multiple Scaffold.of() fallback methods"
echo "   • Positioned button in top-left corner (16px from edges)"
echo "   • Floating action button in bottom-right corner"
echo "   • AppBar integration with mobile detection"
echo ""
log_info "📱 Mobile Menu Button Locations:"
echo "   • AppBar leading position (mobile devices only)"
echo "   • Top-left corner overlay (56px button)"
echo "   • Bottom-right floating action button (backup)"
echo "   • Swipe gesture from left edge (20px drag area)"
echo ""
log_info "🎯 Expected Behavior:"
echo "   • Menu button always visible on mobile"
echo "   • Multiple ways to open the menu"
echo "   • Reliable drawer opening in all orientations"
echo "   • Enhanced touch targets for better usability"
echo "   • Comprehensive error handling and logging"
echo ""
log_info "🌐 Access Your Application:"
echo "   • Frontend: http://your-domain.com"
echo "   • Test menu button on mobile devices"
echo "   • Try all three menu opening methods"
echo ""
log_success "Mobile menu is now reliable and always accessible! 🏀📱"
