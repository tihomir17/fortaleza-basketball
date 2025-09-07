#!/bin/bash

# Deploy Mobile-Friendly Frontend
# This script builds and pushes the mobile-compatible frontend image

set -e

echo "🚀 Building mobile-friendly frontend..."

# Build the Docker image
docker build -t us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest .

echo "📦 Pushing to Google Cloud Artifact Registry..."

# Push the image
docker push us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest

echo "✅ Mobile-friendly frontend deployed successfully!"
echo ""
echo "📱 Changes made:"
echo "   • Mobile devices (320px+) now work without size warnings"
echo "   • Tablets (768px+) have appropriate minimum requirements"
echo "   • Desktop (1024px+) maintains original requirements"
echo "   • Added proper viewport meta tag for mobile"
echo "   • Responsive design with device detection"
echo ""
echo "🔄 To deploy on your server:"
echo "   docker-compose pull frontend"
echo "   docker-compose up -d frontend"
