#!/bin/bash

# Production Database Population Script
# This script populates the production database with realistic basketball data

set -e

echo "🏀 Fortaleza Basketball - Production Database Population"
echo "======================================================"

# Configuration
CONTAINER_NAME="fortaleza-web"
SCRIPT_NAME="populate_realistic_basketball"

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

# Step 2: Populate the database with realistic basketball data
log_info "Step 2: Populating database with realistic basketball data..."
log_info "This includes:"
log_info "  • Play definitions (Sets, Offense, Defense, etc.)"
log_info "  • Teams and competitions"
log_info "  • Users (coaches, players, staff)"
log_info "  • Realistic games with possessions"
log_info "  • Analytics data"

# Run the population script with clear-existing flag to ensure clean data
if docker exec "$CONTAINER_NAME" python manage.py "$SCRIPT_NAME" --clear-existing; then
    log_success "Database population completed successfully"
else
    log_error "Database population failed"
fi

# Step 3: Verify the data was populated correctly
log_info "Step 3: Verifying populated data..."

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

# Check teams
TEAM_COUNT=$(docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.teams.models import Team
print(Team.objects.count())
" 2>/dev/null | tail -1)

if [ "$TEAM_COUNT" -gt 0 ]; then
    log_success "Teams populated: $TEAM_COUNT teams"
else
    log_warning "No teams found"
fi

# Check games
GAME_COUNT=$(docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.games.models import Game
print(Game.objects.count())
" 2>/dev/null | tail -1)

if [ "$GAME_COUNT" -gt 0 ]; then
    log_success "Games populated: $GAME_COUNT games"
else
    log_warning "No games found"
fi

# Check possessions
POSSESSION_COUNT=$(docker exec "$CONTAINER_NAME" python manage.py shell -c "
from apps.possessions.models import Possession
print(Possession.objects.count())
" 2>/dev/null | tail -1)

if [ "$POSSESSION_COUNT" -gt 0 ]; then
    log_success "Possessions populated: $POSSESSION_COUNT possessions"
else
    log_warning "No possessions found"
fi

# Step 4: Create a superuser if needed
log_info "Step 4: Checking for superuser..."
SUPERUSER_COUNT=$(docker exec "$CONTAINER_NAME" python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
print(User.objects.filter(is_superuser=True).count())
" 2>/dev/null | tail -1)

if [ "$SUPERUSER_COUNT" -eq 0 ]; then
    log_warning "No superuser found. You may want to create one:"
    log_info "  docker exec -it $CONTAINER_NAME python manage.py createsuperuser"
else
    log_success "Superuser exists: $SUPERUSER_COUNT superuser(s)"
fi

echo ""
echo "======================================================"
log_success "🎉 Production database population completed!"
echo ""
log_info "📊 Database Summary:"
echo "   • Play Definitions: $PLAY_COUNT"
echo "   • Teams: $TEAM_COUNT"
echo "   • Games: $GAME_COUNT"
echo "   • Possessions: $POSSESSION_COUNT"
echo "   • Superusers: $SUPERUSER_COUNT"
echo ""
log_info "🚀 Your production database is now ready with:"
echo "   • Complete playbook (Sets 1-20, Offense, Defense, etc.)"
echo "   • Realistic basketball games and possessions"
echo "   • Team rosters and coaching staff"
echo "   • Analytics data for reports"
echo ""
log_info "🔧 Next steps:"
echo "   • Access the admin panel to review the data"
echo "   • Test the application functionality"
echo "   • Create additional users as needed"
echo ""
log_success "Ready for production use! 🏀"
