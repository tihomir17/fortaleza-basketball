#!/bin/bash

# Fortaleza Basketball Analytics - Complete Build Script
# This script builds all Docker images for the unified deployment

set -e

echo "🏀 Fortaleza Basketball Analytics - Building All Services"
echo "========================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is available
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

print_status "Using Docker Compose command: $COMPOSE_CMD"

# Clean up any existing containers
print_status "Cleaning up existing containers..."
$COMPOSE_CMD down 2>/dev/null || true

# Remove old images (optional)
if [ "$1" = "--clean" ]; then
    print_status "Cleaning old images..."
    docker rmi fortaleza-basketball-analytics_web fortaleza-basketball-analytics_frontend fortaleza-basketball-analytics_nginx 2>/dev/null || true
fi

# Build all services
print_status "Building all Docker images..."
print_status "This may take several minutes for the first build..."

# Build with progress output
$COMPOSE_CMD build --progress=plain

if [ $? -eq 0 ]; then
    print_success "All Docker images built successfully!"
    
    # Show built images
    print_status "Built images:"
    docker images | grep fortaleza-basketball-analytics || docker images | grep fortaleza
    
    # Show image sizes
    print_status "Image sizes:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(fortaleza|postgres|redis|nginx)"
    
else
    print_error "Docker build failed!"
    exit 1
fi

# Show next steps
echo ""
print_success "Build completed successfully!"
print_status "Next steps:"
echo "  1. Start services: $COMPOSE_CMD up -d"
echo "  2. View logs: $COMPOSE_CMD logs -f"
echo "  3. Check status: $COMPOSE_CMD ps"
echo "  4. Create admin user: $COMPOSE_CMD exec web python manage.py createsuperuser"
echo ""
print_status "Or use the unified deployment script: ./deploy-unified.sh"
