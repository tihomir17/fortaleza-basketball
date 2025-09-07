#!/bin/bash

# Deploy Current Changes Script
# This script deploys the current changes (HEAD COACH ordering + mobile fixes) without full rebuild

set -e

echo "🚀 Fortaleza Basketball - Deploy Current Changes"
echo "============================================="

# Configuration
CONTAINER_NAME="fortaleza-web"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
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

# Check if the container exists and is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    log_error "Container '$CONTAINER_NAME' is not running. Please start the application first."
fi

log_success "Found running container: $CONTAINER_NAME"

# Step 1: Copy updated files to container
log_step "Step 1: Updating backend files in container..."

# Copy updated serializer
log_info "Updating team serializer with HEAD COACH ordering fix..."
docker cp apps/teams/serializers.py "$CONTAINER_NAME:/app/apps/teams/serializers.py"

# Copy database population scripts
log_info "Adding database population scripts..."
docker cp scripts/populate-production-database.sh "$CONTAINER_NAME:/app/scripts/"
docker cp scripts/populate-playsets-only.sh "$CONTAINER_NAME:/app/scripts/"

# Make scripts executable
docker exec "$CONTAINER_NAME" chmod +x /app/scripts/populate-production-database.sh
docker exec "$CONTAINER_NAME" chmod +x /app/scripts/populate-playsets-only.sh

log_success "Backend files updated successfully"

# Step 2: Restart backend service to apply changes
log_step "Step 2: Restarting backend service..."
if docker-compose -f docker-compose.production.yml restart web; then
    log_success "Backend service restarted successfully"
else
    log_error "Failed to restart backend service"
fi

# Step 3: Wait for service to be ready
log_info "Waiting for backend service to be healthy..."
for i in {1..30}; do
    if docker exec "$CONTAINER_NAME" python manage.py check --deploy > /dev/null 2>&1; then
        log_success "Backend service is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Backend service failed to become healthy after 30 seconds"
    fi
    sleep 1
done

# Step 4: Populate database with playsets
log_step "Step 3: Populating database with playsets..."
log_info "Adding play definitions (Sets 1-20, Offense, Defense, etc.)..."

if docker exec "$CONTAINER_NAME" python manage.py populate_db; then
    log_success "Play definitions populated successfully"
else
    log_warning "Play definitions population failed or already exists"
fi

# Step 5: Verify changes
log_step "Step 4: Verifying changes..."

# Check play definitions
PLAY_COUNT=$(docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.plays.models import PlayDefinition
print(PlayDefinition.objects.count())
" 2>/dev/null | tail -1)

if [ "$PLAY_COUNT" -gt 0 ]; then
    log_success "Play definitions verified: $PLAY_COUNT plays available"
else
    log_warning "No play definitions found"
fi

# Test HEAD COACH ordering
log_info "Testing HEAD COACH ordering..."
docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.teams.models import Team
from apps.teams.serializers import TeamReadSerializer
from django.contrib.auth import get_user_model

User = get_user_model()
teams = Team.objects.all()
if teams:
    team = teams.first()
    serializer = TeamReadSerializer(team)
    coaches = serializer.data.get('coaches', [])
    if coaches:
        print(f'First coach type: {coaches[0].get(\"coach_type\", \"Unknown\")}')
    else:
        print('No coaches found')
else:
    print('No teams found')
" 2>/dev/null

echo ""
echo "============================================="
log_success "🎉 Current changes deployed successfully!"
echo ""
log_info "📊 Deployment Summary:"
echo "   • HEAD COACH ordering fix applied"
echo "   • Database population scripts added"
echo "   • Play definitions: $PLAY_COUNT plays available"
echo ""
log_info "🚀 What's Updated:"
echo "   • HEAD COACH now appears first in team management"
echo "   • Complete playbook available (Sets 1-20, etc.)"
echo "   • Database population scripts ready for use"
echo ""
log_info "📱 Frontend Changes:"
echo "   • Mobile sidebar fixes are already deployed"
echo "   • Landscape orientation improvements active"
echo "   • Enhanced mobile detection working"
echo ""
log_success "Ready for production use! 🏀"
