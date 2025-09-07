#!/bin/bash

# Build and Push Frontend Docker Image
# This script handles authentication, multi-architecture building, and pushing to Google Cloud Artifact Registry

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGISTRY="us-central1-docker.pkg.dev"
PROJECT="inat-drive"
REPOSITORY="inatdrive"
IMAGE_NAME="frontend"
FULL_IMAGE_NAME="${REGISTRY}/${PROJECT}/${REPOSITORY}/${IMAGE_NAME}:latest"

echo -e "${BLUE}🚀 Fortaleza Basketball Frontend - Build & Push Script${NC}"
echo "=================================================="

# Function to print status messages
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command_exists docker; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! command_exists gcloud; then
    print_error "Google Cloud CLI is not installed or not in PATH"
    exit 1
fi

print_success "Prerequisites check passed"

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    print_error "Dockerfile not found. Please run this script from the frontend directory."
    exit 1
fi

# Authenticate with Google Cloud
print_status "Authenticating with Google Cloud..."

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    print_warning "No active Google Cloud authentication found. Starting login..."
    gcloud auth login
else
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    print_success "Already authenticated as: $ACTIVE_ACCOUNT"
fi

# Configure Docker for Artifact Registry
print_status "Configuring Docker for Artifact Registry..."
gcloud auth configure-docker ${REGISTRY} --quiet

# Get fresh authentication token for Docker
print_status "Getting fresh authentication token..."
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin ${REGISTRY}

print_success "Authentication completed"

# Check if buildx is available
print_status "Checking Docker buildx support..."
if ! docker buildx ls >/dev/null 2>&1; then
    print_error "Docker buildx is not available. Please update Docker to a newer version."
    exit 1
fi

# Create and use buildx builder if needed
BUILDER_NAME="fortaleza-builder"
if ! docker buildx inspect ${BUILDER_NAME} >/dev/null 2>&1; then
    print_status "Creating buildx builder: ${BUILDER_NAME}"
    docker buildx create --name ${BUILDER_NAME} --use
else
    print_status "Using existing buildx builder: ${BUILDER_NAME}"
    docker buildx use ${BUILDER_NAME}
fi

# Build and push multi-architecture image
print_status "Building and pushing multi-architecture image..."
print_status "Image: ${FULL_IMAGE_NAME}"
print_status "Platforms: linux/amd64, linux/arm64"

docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t ${FULL_IMAGE_NAME} \
    --push \
    .

print_success "Multi-architecture image built and pushed successfully!"

# Verify the push
print_status "Verifying the push..."
if docker manifest inspect ${FULL_IMAGE_NAME} >/dev/null 2>&1; then
    print_success "Image manifest verified successfully"
    
    # Show manifest details
    echo ""
    print_status "Image manifest details:"
    docker manifest inspect ${FULL_IMAGE_NAME} | grep -E '"architecture"|"os"' | head -4
else
    print_warning "Could not verify image manifest (this might be normal)"
fi

# Show deployment instructions
echo ""
echo "=================================================="
print_success "🎉 Build and push completed successfully!"
echo ""
print_status "📦 Image Details:"
echo "   Repository: ${FULL_IMAGE_NAME}"
echo "   Platforms: linux/amd64, linux/arm64"
echo "   Status: Ready for deployment"
echo ""
print_status "🚀 To deploy on your server:"
echo "   docker-compose -f docker-compose.production.yml pull frontend"
echo "   docker-compose -f docker-compose.production.yml up -d frontend"
echo ""
print_status "🔍 To verify deployment:"
echo "   docker-compose -f docker-compose.production.yml images frontend"
echo "   docker inspect fortaleza-frontend | grep Architecture"
echo ""
print_status "📱 What's included in this build:"
echo "   • Fixed sidebar toggle buttons (single, mobile-friendly)"
echo "   • Mobile compatibility improvements"
echo "   • Better touch targets (44px button size)"
echo "   • Enhanced accessibility (tooltips, proper feedback)"
echo "   • Multi-architecture support (AMD64 + ARM64)"
echo ""
print_success "Ready for production deployment! 🚀"
