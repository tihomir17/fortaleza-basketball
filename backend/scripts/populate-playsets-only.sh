#!/bin/bash

# Production Playsets Population Script
# This script only populates play definitions (playsets) without clearing existing data

set -e

echo "🏀 Fortaleza Basketball - Production Playsets Population"
echo "====================================================="

# Configuration
CONTAINER_NAME="fortaleza-web"

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker and try again."
fi

# Check if the container exists and is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    log_error "Container '$CONTAINER_NAME' is not running. Please start the application first."
fi

log_info "Found running container: $CONTAINER_NAME"

# Step 1: Run migrations to ensure database schema is up to date
log_info "Step 1: Running database migrations..."
if docker exec "$CONTAINER_NAME" python manage.py migrate; then
    log_success "Database migrations completed successfully"
else
    log_error "Database migrations failed"
fi

# Step 2: Populate only play definitions using populate_db command
log_info "Step 2: Populating play definitions (playsets)..."
log_info "This includes:"
log_info "  • Offense Sets (Set 1-20)"
log_info "  • Offense Half Court plays"
log_info "  • Defense plays (PnR, Zone, Press)"
log_info "  • Player actions"
log_info "  • Control plays"
log_info "  • Outcome plays"
log_info "  • Shot quality and timing"
log_info "  • Advanced plays"

# Run the populate_db command which loads play definitions from JSON
if docker exec "$CONTAINER_NAME" python manage.py populate_db; then
    log_success "Play definitions population completed successfully"
else
    log_error "Play definitions population failed"
fi

# Step 3: Verify the play definitions were populated
log_info "Step 3: Verifying populated play definitions..."

# Check play categories
CATEGORY_COUNT=$(docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.plays.models import PlayCategory
print(PlayCategory.objects.count())
" 2>/dev/null | tail -1)

if [ "$CATEGORY_COUNT" -gt 0 ]; then
    log_success "Play categories populated: $CATEGORY_COUNT categories"
else
    log_warning "No play categories found"
fi

# Check play definitions
PLAY_COUNT=$(docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.plays.models import PlayDefinition
print(PlayDefinition.objects.count())
" 2>/dev/null | tail -1)

if [ "$PLAY_COUNT" -gt 0 ]; then
    log_success "Play definitions populated: $PLAY_COUNT plays"
else
    log_warning "No play definitions found"
fi

# Show some example plays
log_info "Sample play definitions:"
docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.plays.models import PlayDefinition
plays = PlayDefinition.objects.all()[:10]
for play in plays:
    print(f'  • {play.name} ({play.category.name})')
" 2>/dev/null

echo ""
echo "====================================================="
log_success "🎉 Production playsets population completed!"
echo ""
log_info "📊 Playsets Summary:"
echo "   • Play Categories: $CATEGORY_COUNT"
echo "   • Play Definitions: $PLAY_COUNT"
echo ""
log_info "🏀 Available play categories:"
docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.plays.models import PlayCategory
for category in PlayCategory.objects.all():
    count = category.plays.count()
    print(f'   • {category.name}: {count} plays')
" 2>/dev/null
echo ""
log_success "Your playbook is now ready for use! 🏀"
