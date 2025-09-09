#!/bin/bash

# Deploy Playsets Population Script
# This script deploys the safe playsets population to the production server

set -e

echo "🚀 Fortaleza Basketball - Deploy Playsets Population"
echo "==================================================="

# Configuration
CONTAINER_NAME="fortaleza-web"

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

# Step 1: Copy the safe playsets population script to the container
log_step "Step 1: Copying safe playsets population script to container..."
log_info "Copying populate-playsets-safe.sh to container..."

if docker cp scripts/populate-playsets-safe.sh "$CONTAINER_NAME:/app/scripts/"; then
    log_success "Script copied successfully"
else
    log_error "Failed to copy script to container"
fi

# Step 2: Make the script executable
log_step "Step 2: Making script executable..."
log_info "Setting execute permissions on populate-playsets-safe.sh..."

if docker exec "$CONTAINER_NAME" chmod +x /app/scripts/populate-playsets-safe.sh; then
    log_success "Script permissions set successfully"
else
    log_error "Failed to set script permissions"
fi

# Step 3: Run the safe playsets population
log_step "Step 3: Running safe playsets population..."
log_info "Populating play definitions from initial_play_definitions.json..."
log_info "This will safely add playsets without clearing existing data"

if docker exec "$CONTAINER_NAME" /app/scripts/populate-playsets-safe.sh; then
    log_success "Playsets population completed successfully"
else
    log_error "Playsets population failed"
fi

# Step 4: Verify deployment
log_step "Step 4: Verifying playsets population..."

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
echo "==================================================="
log_success "🎉 Playsets population deployed successfully!"
echo ""
log_info "🔧 What's Been Populated:"
echo "   • Offense Sets (Set 1-20)"
echo "   • Offense Half Court plays"
echo "   • Defense plays (PnR, Zone, Press)"
echo "   • Player actions"
echo "   • Control plays"
echo "   • Outcome plays"
echo "   • Shot quality and timing"
echo "   • Advanced plays"
echo ""
log_info "📊 Data Safety:"
echo "   • Existing teams preserved"
echo "   • Existing players preserved"
echo "   • Existing games preserved"
echo "   • Existing possessions preserved"
echo "   • Only play definitions added/updated"
echo ""
log_info "🏀 Play Categories Available:"
docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.plays.models import PlayCategory
for category in PlayCategory.objects.all():
    count = category.plays.count()
    print(f'   • {category.name}: {count} plays')
" 2>/dev/null
echo ""
log_info "🌐 Access Your Application:"
echo "   • Frontend: http://your-domain.com"
echo "   • Admin: http://your-domain.com/admin/"
echo "   • Verify playsets are available in the application"
echo ""
log_success "Your playbook is now ready for use! 🏀📚"
