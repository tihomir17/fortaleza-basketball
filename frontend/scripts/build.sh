#!/bin/bash

# Fortaleza Basketball Analytics - Frontend Build Script
# This script builds the Flutter web app for production deployment

set -e

echo "🏀 Building Fortaleza Basketball Analytics Frontend..."

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

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    print_status "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
print_status "Using $FLUTTER_VERSION"

# Navigate to Flutter app directory
cd flutter_app

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Check for any issues
print_status "Running Flutter doctor..."
flutter doctor

# Build for web
print_status "Building Flutter web app for production..."
flutter build web --release --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false

# Check if build was successful
if [ $? -eq 0 ]; then
    print_success "Flutter web build completed successfully!"
    print_status "Build output: flutter_app/build/web/"
    
    # Show build size
    BUILD_SIZE=$(du -sh build/web | cut -f1)
    print_status "Build size: $BUILD_SIZE"
    
    # List main files
    print_status "Main build files:"
    ls -la build/web/ | head -10
    
else
    print_error "Flutter build failed!"
    exit 1
fi

# Go back to frontend directory
cd ..

print_success "Frontend build completed! Ready for deployment."
print_status "To build Docker image, run: docker build -t fortaleza-frontend ."
print_status "To run with docker-compose: docker-compose up -d"
