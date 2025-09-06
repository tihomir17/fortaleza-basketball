#!/bin/bash

# Fortaleza Basketball Analytics - Unified Deployment Script
# This script deploys both backend and frontend together

set -e

echo "🏀 Fortaleza Basketball Analytics - Unified Deployment"
echo "====================================================="

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

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_status "Docker and Docker Compose are available"

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Remove old images (optional)
if [ "$1" = "--clean" ]; then
    print_status "Cleaning old images..."
    docker rmi fortaleza-basketball-analytics_web fortaleza-basketball-analytics_frontend 2>/dev/null || true
fi

# Build the Docker images
print_status "Building Docker images..."
docker-compose build

if [ $? -eq 0 ]; then
    print_success "Docker images built successfully!"
else
    print_error "Docker build failed!"
    exit 1
fi

# Start the services
print_status "Starting services..."
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 15

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_success "Services are running!"
    
    # Show service status
    print_status "Service status:"
    docker-compose ps
    
    # Test health endpoints
    print_status "Testing health endpoints..."
    
    # Test backend health
    if curl -f http://localhost/api/health/ > /dev/null 2>&1; then
        print_success "Backend health check passed!"
    else
        print_warning "Backend health check failed, but service might still be starting..."
    fi
    
    # Test frontend health
    if curl -f http://localhost/health > /dev/null 2>&1; then
        print_success "Frontend health check passed!"
    else
        print_warning "Frontend health check failed, but service might still be starting..."
    fi
    
    print_success "Unified deployment completed successfully!"
    print_status "Application is available at: http://localhost"
    print_status "API endpoints: http://localhost/api/"
    print_status "Admin panel: http://localhost/admin/"
    print_status "Health checks:"
    print_status "  - Backend: http://localhost/api/health/"
    print_status "  - Frontend: http://localhost/health"
    
else
    print_error "Services failed to start!"
    print_status "Checking logs..."
    docker-compose logs
    exit 1
fi

# Show useful commands
echo ""
print_status "Useful commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop services: docker-compose down"
echo "  Restart services: docker-compose restart"
echo "  Update and redeploy: ./deploy-unified.sh --clean"
echo "  View specific service logs: docker-compose logs -f [service_name]"
echo ""
print_status "Service names: db, redis, web, frontend, nginx"
