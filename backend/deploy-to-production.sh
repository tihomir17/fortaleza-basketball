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
