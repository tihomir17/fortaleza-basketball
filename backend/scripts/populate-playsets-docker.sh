#!/bin/bash

# Docker Playsets Population Script
# This script runs playsets population directly inside the Docker container
# No source code needed on the cloud machine

set -e

echo "🏀 Fortaleza Basketball - Docker Playsets Population"
echo "==================================================="

# Configuration
COMPOSE_FILE="docker-compose.production.yml"
SERVICE_NAME="web"

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

# Check if the service is running
if ! docker-compose -f "$COMPOSE_FILE" ps | grep -q "$SERVICE_NAME.*Up"; then
    log_error "Service '$SERVICE_NAME' is not running. Please start the application first with 'docker-compose -f $COMPOSE_FILE up -d'"
fi

log_info "Found running service: $SERVICE_NAME"

# Step 1: Run migrations to ensure database schema is up to date
log_info "Step 1: Running database migrations..."
if docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py migrate; then
    log_success "Database migrations completed successfully"
else
    log_error "Database migrations failed"
fi

# Step 2: Run the playsets population directly in the container
log_info "Step 2: Populating play definitions (playsets)..."
log_info "This will safely add playsets without clearing existing data"
log_info "Running Python script directly in the container..."

# Create and run the Python script directly in the container
docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python -c "
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

print('🏀 Loading play definitions from JSON file...')

# Get or create default team for play templates
superuser = User.objects.filter(is_superuser=True).first()
if not superuser:
    print('❌ ERROR: No superuser found. Please create one first.')
    exit(1)

print(f'✅ Found superuser: {superuser.username}')

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

print(f'✅ Using team: {default_team.name}')

# Load play definitions from JSON
json_path = '/app/data/initial_play_definitions.json'
if not os.path.exists(json_path):
    print(f'❌ ERROR: JSON file not found at {json_path}')
    exit(1)

with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f'📚 Found {len(data)} play categories in JSON file')

# Track statistics
categories_created = 0
plays_created = 0
plays_skipped = 0

for category_data in data:
    category_name = category_data['category']
    category, created = PlayCategory.objects.get_or_create(name=category_name)
    if created:
        categories_created += 1
        print(f'🆕 Created new category: {category_name}')
    else:
        print(f'♻️  Category already exists: {category_name}')
    
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

print(f'\\n📊 Play definitions loading completed:')
print(f'   • Categories created: {categories_created}')
print(f'   • Plays created: {plays_created}')
print(f'   • Plays skipped (already exist): {plays_skipped}')
print(f'   • Total categories: {PlayCategory.objects.count()}')
print(f'   • Total plays: {PlayDefinition.objects.count()}')

# Show play categories summary
print(f'\\n🏀 Play Categories Summary:')
for category in PlayCategory.objects.all():
    count = category.plays.count()
    print(f'   • {category.name}: {count} plays')

print(f'\\n✅ Playsets population completed successfully!')
"

if [ $? -eq 0 ]; then
    log_success "Play definitions population completed successfully"
else
    log_error "Play definitions population failed"
fi

# Step 3: Verify the play definitions were populated
log_info "Step 3: Verifying populated play definitions..."

# Check play categories
CATEGORY_COUNT=$(docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py shell -c "
from apps.plays.models import PlayCategory
print(PlayCategory.objects.count())
" 2>/dev/null | tail -1)

if [ "$CATEGORY_COUNT" -gt 0 ]; then
    log_success "Play categories populated: $CATEGORY_COUNT categories"
else
    log_warning "No play categories found"
fi

# Check play definitions
PLAY_COUNT=$(docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py shell -c "
from apps.plays.models import PlayDefinition
print(PlayDefinition.objects.count())
" 2>/dev/null | tail -1)

if [ "$PLAY_COUNT" -gt 0 ]; then
    log_success "Play definitions populated: $PLAY_COUNT plays"
else
    log_warning "No play definitions found"
fi

echo ""
echo "==================================================="
log_success "🎉 Docker playsets population completed!"
echo ""
log_info "📊 Final Summary:"
echo "   • Play Categories: $CATEGORY_COUNT"
echo "   • Play Definitions: $PLAY_COUNT"
echo ""
log_info "🏀 Available play categories:"
docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py shell -c "
from apps.plays.models import PlayCategory
for category in PlayCategory.objects.all():
    count = category.plays.count()
    print(f'   • {category.name}: {count} plays')
" 2>/dev/null
echo ""
log_success "Your playbook is now ready for use! 🏀📚"
echo ""
log_info "✅ This script ran directly in the Docker container"
log_info "✅ No source code needed on the cloud machine"
log_info "✅ All existing data preserved"
