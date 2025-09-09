#!/bin/bash

# Simple Fortaleza Population Script (No pandas required)
# This script populates data without requiring pandas

set -e

echo "🏀 Fortaleza Basketball - Simple Data Population"
echo "==============================================="

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
    log_error "Service '$SERVICE_NAME' is not running. Please start the application first."
fi

log_info "Found running service: $SERVICE_NAME"

# Step 1: Run migrations
log_info "Step 1: Running database migrations..."
if docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py migrate; then
    log_success "Database migrations completed successfully"
else
    log_error "Database migrations failed"
fi

# Step 2: Populate play definitions
log_info "Step 2: Populating play definitions..."
docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python -c "
import os
import json
import django
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'basketball_analytics.settings')
django.setup()

from apps.plays.models import PlayCategory, PlayDefinition
from apps.teams.models import Team
from apps.competitions.models import Competition
from django.contrib.auth import get_user_model

User = get_user_model()

print('🏀 Loading play definitions from JSON...')

superuser = User.objects.filter(is_superuser=True).first()
if not superuser:
    print('❌ ERROR: No superuser found.')
    exit(1)

competition, _ = Competition.objects.get_or_create(
    name='Novo Basquete Brasil',
    defaults={'season': '2025-2026', 'created_by': superuser}
)

default_team, _ = Team.objects.get_or_create(
    name='Default Play Templates',
    defaults={'competition': competition, 'created_by': superuser}
)

with open('/app/data/initial_play_definitions.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

categories_created = 0
plays_created = 0

for category_data in data:
    category, created = PlayCategory.objects.get_or_create(name=category_data['category'])
    if created:
        categories_created += 1
    
    for play_data in category_data['plays']:
        play_def, created = PlayDefinition.objects.get_or_create(
            name=play_data['name'],
            team=default_team,
            defaults={
                'category': category,
                'subcategory': play_data.get('subcategory'),
                'action_type': play_data.get('action_type', 'NORMAL'),
                'play_type': 'OFFENSIVE',
            }
        )
        if created:
            plays_created += 1

print(f'✅ Play definitions: {categories_created} categories, {plays_created} plays created')
"

if [ $? -eq 0 ]; then
    log_success "Play definitions population completed successfully"
else
    log_error "Play definitions population failed"
fi

# Step 3: Create basic Fortaleza team members (without Excel)
log_info "Step 3: Creating basic Fortaleza team members..."
docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python -c "
import django
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'basketball_analytics.settings')
django.setup()

from apps.teams.models import Team
from apps.competitions.models import Competition
from django.contrib.auth import get_user_model

User = get_user_model()

print('🏀 Creating basic Fortaleza team members...')

superuser = User.objects.filter(is_superuser=True).first()
if not superuser:
    print('❌ ERROR: No superuser found.')
    exit(1)

competition, _ = Competition.objects.get_or_create(
    name='Novo Basquete Brasil',
    defaults={'season': '2025-2026', 'created_by': superuser}
)

fortaleza_team, _ = Team.objects.get_or_create(
    name='Fortaleza B.C.',
    defaults={'competition': competition, 'created_by': superuser}
)

# Create basic Fortaleza coaches
coaches_data = [
    {'first_name': 'Jelena', 'last_name': 'Todorovic', 'coach_type': 'HEAD_COACH'},
    {'first_name': 'Vladimir', 'last_name': 'Dosenovic', 'coach_type': 'ASSISTANT_COACH'},
]

coaches_created = 0
for coach_data in coaches_data:
    username = f'{coach_data[\"first_name\"].lower()}.{coach_data[\"last_name\"].lower()}'
    coach_type_enum = User.CoachType.HEAD_COACH if coach_data['coach_type'] == 'HEAD_COACH' else User.CoachType.ASSISTANT_COACH
    
    user, created = User.objects.get_or_create(
        username=username,
        defaults={
            'first_name': coach_data['first_name'],
            'last_name': coach_data['last_name'],
            'role': User.Role.COACH,
            'coach_type': coach_type_enum,
            'password': 'fortaleza2025',
        }
    )
    
    if created:
        coaches_created += 1
        print(f'🆕 Created coach: {coach_data[\"first_name\"]} {coach_data[\"last_name\"]} ({coach_data[\"coach_type\"]})')
    
    fortaleza_team.coaches.add(user)

# Create basic Fortaleza players
players_data = [
    {'first_name': 'Nikola', 'last_name': 'Jokic', 'jersey_number': 15},
    {'first_name': 'LeBron', 'last_name': 'James', 'jersey_number': 23},
    {'first_name': 'Stephen', 'last_name': 'Curry', 'jersey_number': 30},
    {'first_name': 'Kevin', 'last_name': 'Durant', 'jersey_number': 7},
    {'first_name': 'Giannis', 'last_name': 'Antetokounmpo', 'jersey_number': 34},
]

players_created = 0
for player_data in players_data:
    username = f'{player_data[\"first_name\"].lower()}.{player_data[\"last_name\"].lower()}'
    
    user, created = User.objects.get_or_create(
        username=username,
        defaults={
            'first_name': player_data['first_name'],
            'last_name': player_data['last_name'],
            'role': User.Role.PLAYER,
            'jersey_number': player_data['jersey_number'],
            'password': 'fortaleza2025',
        }
    )
    
    if created:
        players_created += 1
        print(f'🆕 Created player: {player_data[\"first_name\"]} {player_data[\"last_name\"]} (#{player_data[\"jersey_number\"]})')
    
    fortaleza_team.players.add(user)

print(f'✅ Fortaleza Members: {coaches_created} coaches, {players_created} players created')
print(f'📊 Total Fortaleza team: {fortaleza_team.coaches.count()} coaches, {fortaleza_team.players.count()} players')
"

if [ $? -eq 0 ]; then
    log_success "Fortaleza Members population completed successfully"
else
    log_error "Fortaleza Members population failed"
fi

# Step 4: Final verification
log_info "Step 4: Final verification..."

CATEGORY_COUNT=$(docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py shell -c "
from apps.plays.models import PlayCategory
print(PlayCategory.objects.count())
" 2>/dev/null | tail -1)

PLAY_COUNT=$(docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py shell -c "
from apps.plays.models import PlayDefinition
print(PlayDefinition.objects.count())
" 2>/dev/null | tail -1)

FORTALEZA_COACHES=$(docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py shell -c "
from apps.teams.models import Team
fortaleza = Team.objects.filter(name__icontains='Fortaleza').first()
if fortaleza:
    print(fortaleza.coaches.count())
else:
    print(0)
" 2>/dev/null | tail -1)

FORTALEZA_PLAYERS=$(docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py shell -c "
from apps.teams.models import Team
fortaleza = Team.objects.filter(name__icontains='Fortaleza').first()
if fortaleza:
    print(fortaleza.players.count())
else:
    print(0)
" 2>/dev/null | tail -1)

echo ""
echo "==============================================="
log_success "🎉 Simple data population completed!"
echo ""
log_info "📊 Final Summary:"
echo "   • Play Categories: $CATEGORY_COUNT"
echo "   • Play Definitions: $PLAY_COUNT"
echo "   • Fortaleza Coaches: $FORTALEZA_COACHES"
echo "   • Fortaleza Players: $FORTALEZA_PLAYERS"
echo ""
log_success "Your basic Fortaleza team and playbook are ready! 🏀📚"
echo ""
log_info "💡 To add more team members from Excel, rebuild the backend with pandas support:"
log_info "   ./scripts/rebuild-and-populate.sh"
