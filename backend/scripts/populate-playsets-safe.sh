#!/bin/bash

# Safe Playsets Population Script
# This script only populates play definitions (playsets) WITHOUT clearing existing data

set -e

echo "🏀 Fortaleza Basketball - Safe Playsets Population"
echo "================================================="

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

# Step 2: Create a safe playsets population script inside the container
log_info "Step 2: Creating safe playsets population script..."

# Create a Python script that only loads play definitions without clearing data
docker exec "$CONTAINER_NAME" python -c "
import os
import json
import django
from django.conf import settings

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'basketball_analytics.settings')
django.setup()

from apps.plays.models import PlayCategory, PlayDefinition
from apps.teams.models import Team
from apps.competitions.models import Competition
from django.contrib.auth import get_user_model

User = get_user_model()

print('Loading play definitions from JSON file...')

# Get or create default team for play templates
superuser = User.objects.filter(is_superuser=True).first()
if not superuser:
    print('ERROR: No superuser found. Please create one first.')
    exit(1)

# Get or create competition
competition, _ = Competition.objects.get_or_create(
    name='Novo Basquete Brasil',
    defaults={'season': '2025-2026', 'created_by': superuser}
)

# Get or create default team for play templates
default_team, _ = Team.objects.get_or_create(
    name='Default Play Templates',
    defaults={'competition': competition, 'created_by': superuser}
)

# Load play definitions from JSON
json_path = '/app/data/initial_play_definitions.json'
if not os.path.exists(json_path):
    print(f'ERROR: JSON file not found at {json_path}')
    exit(1)

with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f'Found {len(data)} play categories in JSON file')

# Track statistics
categories_created = 0
plays_created = 0
plays_skipped = 0

for category_data in data:
    category_name = category_data['category']
    category, created = PlayCategory.objects.get_or_create(name=category_name)
    if created:
        categories_created += 1
        print(f'Created new category: {category_name}')
    else:
        print(f'Category already exists: {category_name}')
    
    for play_data in category_data['plays']:
        play_name = play_data['name']
        play_def, created = PlayDefinition.objects.get_or_create(
            name=play_name,
            team=default_team,
            defaults={
                'category': category,
                'subcategory': play_data.get('subcategory'),
                'action_type': play_data.get('action_type', 'NORMAL'),
                'play_type': 'OFFENSIVE',  # Default play type
            }
        )
        if created:
            plays_created += 1
        else:
            plays_skipped += 1

print(f'\\nPlay definitions loading completed:')
print(f'  • Categories created: {categories_created}')
print(f'  • Plays created: {plays_created}')
print(f'  • Plays skipped (already exist): {plays_skipped}')
print(f'  • Total categories: {PlayCategory.objects.count()}')
print(f'  • Total plays: {PlayDefinition.objects.count()}')
"

if [ $? -eq 0 ]; then
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
log_success "🎉 Safe playsets population completed!"
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
echo ""
log_info "✅ This script safely populated playsets without clearing existing data"
log_info "✅ All existing teams, players, games, and possessions are preserved"
