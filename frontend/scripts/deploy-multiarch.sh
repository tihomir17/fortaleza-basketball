#!/bin/bash

# Deploy Multi-Architecture Frontend
# This script builds and pushes a multi-architecture Docker image that works on both AMD64 and ARM64

set -e

echo "🚀 Building multi-architecture frontend image..."

# Build and push multi-architecture image
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t us-central1-docker.pkg.dev/inat-drive/inatdrive/frontend:latest \
  --push .

echo "✅ Multi-architecture frontend image deployed successfully!"
echo ""
echo "📦 Image supports:"
echo "   • linux/amd64 (Intel/AMD servers)"
echo "   • linux/arm64 (Apple Silicon, ARM servers)"
echo ""
echo "🔄 To deploy on your server:"
echo "   docker-compose -f docker-compose.production.yml pull frontend"
echo "   docker-compose -f docker-compose.production.yml up -d frontend"
echo ""
echo "🔍 To verify architecture on server:"
echo "   docker inspect fortaleza-frontend | grep Architecture"
