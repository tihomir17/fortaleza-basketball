#!/bin/bash

# Fortaleza Basketball Analytics - Complete Deployment Script
# This script handles the complete deployment process

set -e

echo "🏀 Fortaleza Basketball Analytics - Deployment Script"
echo "=================================================="

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
    docker rmi fortaleza-frontend 2>/dev/null || true
fi

# Build the Docker image
print_status "Building Docker image..."
docker build -t fortaleza-frontend .

if [ $? -eq 0 ]; then
    print_success "Docker image built successfully!"
else
    print_error "Docker build failed!"
    exit 1
fi

# Start the services
print_status "Starting services..."
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_success "Services are running!"
    
    # Show service status
    print_status "Service status:"
    docker-compose ps
    
    # Test health endpoint
    print_status "Testing health endpoint..."
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        print_success "Health check passed!"
    else
        print_warning "Health check failed, but service might still be starting..."
    fi
    
    print_success "Deployment completed successfully!"
    print_status "Frontend is available at: http://localhost:8080"
    print_status "Health check: http://localhost:8080/health"
    
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
echo "  Update and redeploy: ./deploy.sh --clean"
