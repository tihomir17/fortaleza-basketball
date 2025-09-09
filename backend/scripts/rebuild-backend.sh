#!/bin/bash

# Rebuild Backend Script
# This script rebuilds the backend container with new files

set -e

echo "🏀 Fortaleza Basketball - Rebuild Backend"
echo "========================================"

# Configuration
COMPOSE_FILE="docker-compose.production.yml"
SERVICE_NAME="web"
IMAGE_NAME="us-central1-docker.pkg.dev/inat-drive/inatdrive/backend:latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker and try again."
fi

# Check if gcloud is authenticated
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" | grep -q "@"; then
    log_error "Google Cloud is not authenticated. Please run 'gcloud auth login' first."
fi

log_success "Prerequisites check passed"

# Step 1: Stop the current service
log_info "Stopping current backend service..."
if docker-compose -f "$COMPOSE_FILE" stop web; then
    log_success "Web service stopped successfully"
else
    log_warning "Web service was not running"
fi

# Step 2: Build new backend image
log_info "Building new backend image with updated files..."
log_info "Including: initial_play_definitions.json and Fortaleza Members.xlsx"

if docker buildx build --platform linux/amd64,linux/arm64 -t "$IMAGE_NAME" --push .; then
    log_success "Backend image built and pushed successfully"
else
    log_error "Failed to build and push backend image"
fi

# Step 3: Pull the new image
log_info "Pulling new backend image..."
if docker pull "$IMAGE_NAME"; then
    log_success "Backend image pulled successfully"
else
    log_error "Failed to pull backend image"
fi

# Step 4: Start the service
log_info "Starting service with new image..."
if docker-compose -f "$COMPOSE_FILE" up -d web; then
    log_success "Web service started successfully"
else
    log_error "Failed to start web service"
fi

# Step 5: Wait for service to be ready
log_info "Waiting for service to be ready..."
for i in {1..30}; do
    if docker-compose -f "$COMPOSE_FILE" exec web python manage.py check > /dev/null 2>&1; then
        log_success "Web service is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Web service failed to become healthy after 30 seconds"
    fi
    sleep 2
done

echo ""
echo "========================================"
log_success "🎉 Backend rebuild completed successfully!"
echo ""
log_info "📁 New files included in container:"
echo "   • /app/data/initial_play_definitions.json"
echo "   • /app/data/Infos - Fortaleza Members.xlsx"
echo ""
log_info "🚀 Next steps:"
echo "   • Run migrations: docker-compose -f $COMPOSE_FILE exec web python manage.py migrate"
echo "   • Populate data: ./scripts/populate_all_fortaleza.sh"
echo "   • Or use the rebuild-and-populate.sh script for everything"
echo ""
log_success "Backend is ready with new files! 🏀"
