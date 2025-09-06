#!/bin/bash

# Fortaleza Basketball Analytics - Production Deployment Script
# This script deploys the production version using Google Container Registry

set -e

echo "🏀 Fortaleza Basketball Analytics - Production Deployment"
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

# Check if .env file exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from template..."
    if [ -f production.env ]; then
        cp production.env .env
        print_warning "Please edit .env file with your actual values before continuing."
        print_warning "Required variables: SECRET_KEY, DB_PASSWORD, EMAIL_HOST_USER, EMAIL_HOST_PASSWORD"
        exit 1
    else
        print_error "No environment file found. Please create .env file with required variables."
        exit 1
    fi
fi

# Authenticate with Google Container Registry
print_status "Authenticating with Google Container Registry..."
gcloud auth configure-docker us-central1-docker.pkg.dev

# Pull latest images
print_status "Pulling latest images from Google Container Registry..."
docker pull us-central1-docker.pkg.dev/inat-drive/inatdrive/backend:latest

# Stop existing containers
print_status "Stopping existing containers..."
$COMPOSE_CMD -f docker-compose.production.yml down 2>/dev/null || true

# Start services
print_status "Starting production services..."
$COMPOSE_CMD -f docker-compose.production.yml up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 15

# Check if services are running
if $COMPOSE_CMD -f docker-compose.production.yml ps | grep -q "Up"; then
    print_success "Production services are running!"
    
    # Show service status
    print_status "Service status:"
    $COMPOSE_CMD -f docker-compose.production.yml ps
    
    # Test health endpoints
    print_status "Testing health endpoints..."
    
    # Test backend health
    if curl -f http://localhost:8080/api/health/ > /dev/null 2>&1; then
        print_success "Backend health check passed!"
    else
        print_warning "Backend health check failed, but service might still be starting..."
    fi
    
    print_success "Production deployment completed successfully!"
    print_status "Backend API is available at: http://localhost:8080"
    print_status "Caddy should proxy this to: https://admin.inatdrive.com"
    print_status "Health check: http://localhost:8080/api/health/"
    
else
    print_error "Services failed to start!"
    print_status "Checking logs..."
    $COMPOSE_CMD -f docker-compose.production.yml logs
    exit 1
fi

# Show useful commands
echo ""
print_status "Useful commands:"
echo "  View logs: $COMPOSE_CMD -f docker-compose.production.yml logs -f"
echo "  Stop services: $COMPOSE_CMD -f docker-compose.production.yml down"
echo "  Restart services: $COMPOSE_CMD -f docker-compose.production.yml restart"
echo "  Create admin user: $COMPOSE_CMD -f docker-compose.production.yml exec web python manage.py createsuperuser"
echo "  View specific service logs: $COMPOSE_CMD -f docker-compose.production.yml logs -f [service_name]"
echo ""
print_status "Service names: web, db, redis, frontend"
