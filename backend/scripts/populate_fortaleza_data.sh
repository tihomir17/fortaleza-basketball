#!/bin/bash

# Fortaleza Data Population Script
# This script populates both the new play definitions and Fortaleza Members from Excel

set -e

echo "🏀 Fortaleza Basketball - Complete Data Population"
echo "================================================="

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

# Step 2: Populate new play definitions
log_info "Step 2: Populating new play definitions from initial_play_definitions.json..."
log_info "This will safely add/update playsets without clearing existing data"

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

print('🏀 Loading NEW play definitions from JSON file...')

# Get or create default team for play templates
superuser = User.objects.filter(is_superuser=True).first()
if not superuser:
    print('❌ ERROR: No superuser found. Please create one first.')
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
    print(f'❌ ERROR: JSON file not found at {json_path}')
    exit(1)

with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f'📚 Found {len(data)} play categories in NEW JSON file')

# Track statistics
categories_created = 0
categories_updated = 0
plays_created = 0
plays_updated = 0

for category_data in data:
    category_name = category_data['category']
    category, created = PlayCategory.objects.get_or_create(name=category_name)
    if created:
        categories_created += 1
        print(f'🆕 Created new category: {category_name}')
    else:
        categories_updated += 1
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
                'play_type': 'OFFENSIVE',
            }
        )
        if created:
            plays_created += 1
        else:
            plays_updated += 1

print(f'\\n📊 NEW Play definitions loading completed:')
print(f'   • Categories created: {categories_created}')
print(f'   • Categories updated: {categories_updated}')
print(f'   • Plays created: {plays_created}')
print(f'   • Plays updated: {plays_updated}')
print(f'   • Total categories: {PlayCategory.objects.count()}')
print(f'   • Total plays: {PlayDefinition.objects.count()}')

print(f'\\n🏀 Updated Play Categories Summary:')
for category in PlayCategory.objects.all():
    count = category.plays.count()
    print(f'   • {category.name}: {count} plays')

print(f'\\n✅ NEW Play definitions population completed successfully!')
"

if [ $? -eq 0 ]; then
    log_success "NEW play definitions population completed successfully"
else
    log_error "NEW play definitions population failed"
fi

# Step 3: Populate Fortaleza Members from Excel
log_info "Step 3: Populating Fortaleza Members from Excel file..."
log_info "This will create/update Fortaleza team members (coaches and players)"

docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python -c "
import os
import pandas as pd
import django
from django.conf import settings

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'basketball_analytics.settings')
django.setup()

from apps.teams.models import Team
from apps.competitions.models import Competition
from django.contrib.auth import get_user_model

User = get_user_model()

print('🏀 Loading Fortaleza Members from Excel file...')

# Get or create superuser
superuser = User.objects.filter(is_superuser=True).first()
if not superuser:
    print('❌ ERROR: No superuser found. Please create one first.')
    exit(1)

# Get or create competition
competition, _ = Competition.objects.get_or_create(
    name='Novo Basquete Brasil',
    defaults={'season': '2025-2026', 'created_by': superuser}
)

# Get or create Fortaleza team
fortaleza_team, _ = Team.objects.get_or_create(
    name='Fortaleza B.C.',
    defaults={'competition': competition, 'created_by': superuser}
)

print(f'✅ Using team: {fortaleza_team.name}')

# Load Excel file
excel_path = '/app/data/Infos - Fortaleza Members.xlsx'
if not os.path.exists(excel_path):
    print(f'❌ ERROR: Excel file not found at {excel_path}')
    exit(1)

try:
    # Read Excel file
    df = pd.read_excel(excel_path)
    print(f'📊 Found {len(df)} rows in Excel file')
    print(f'📋 Columns: {list(df.columns)}')
    
    # Track statistics
    coaches_created = 0
    coaches_updated = 0
    players_created = 0
    players_updated = 0
    
    # Process each row
    for index, row in df.iterrows():
        try:
            # Extract data from row (adjust column names as needed)
            first_name = str(row.get('First Name', '')).strip()
            last_name = str(row.get('Last Name', '')).strip()
            role = str(row.get('Role', '')).strip().upper()
            jersey_number = row.get('Jersey Number', None)
            coach_type = str(row.get('Coach Type', '')).strip().upper()
            
            # Skip empty rows
            if not first_name or not last_name:
                continue
                
            # Create username
            username = f'{first_name.lower()}.{last_name.lower()}'
            
            # Determine if it's a coach or player
            if role == 'COACH' or 'COACH' in role:
                # Create coach
                coach_type_enum = User.CoachType.HEAD_COACH if coach_type == 'HEAD_COACH' else User.CoachType.ASSISTANT_COACH
                
                user, created = User.objects.get_or_create(
                    username=username,
                    defaults={
                        'first_name': first_name,
                        'last_name': last_name,
                        'role': User.Role.COACH,
                        'coach_type': coach_type_enum,
                        'password': 'fortaleza2025',  # Default password
                    }
                )
                
                if created:
                    coaches_created += 1
                    print(f'🆕 Created coach: {first_name} {last_name} ({coach_type})')
                else:
                    coaches_updated += 1
                    print(f'♻️  Coach already exists: {first_name} {last_name}')
                
                # Add to Fortaleza team
                fortaleza_team.coaches.add(user)
                
            else:
                # Create player
                user, created = User.objects.get_or_create(
                    username=username,
                    defaults={
                        'first_name': first_name,
                        'last_name': last_name,
                        'role': User.Role.PLAYER,
                        'jersey_number': jersey_number if jersey_number else None,
                        'password': 'fortaleza2025',  # Default password
                    }
                )
                
                if created:
                    players_created += 1
                    print(f'🆕 Created player: {first_name} {last_name} (#{jersey_number})')
                else:
                    players_updated += 1
                    print(f'♻️  Player already exists: {first_name} {last_name}')
                
                # Add to Fortaleza team
                fortaleza_team.players.add(user)
                
        except Exception as e:
            print(f'⚠️  Error processing row {index}: {e}')
            continue
    
    print(f'\\n📊 Fortaleza Members loading completed:')
    print(f'   • Coaches created: {coaches_created}')
    print(f'   • Coaches updated: {coaches_updated}')
    print(f'   • Players created: {players_created}')
    print(f'   • Players updated: {players_updated}')
    print(f'   • Total Fortaleza coaches: {fortaleza_team.coaches.count()}')
    print(f'   • Total Fortaleza players: {fortaleza_team.players.count()}')
    
    print(f'\\n🏀 Fortaleza Team Summary:')
    print(f'   • Team: {fortaleza_team.name}')
    print(f'   • Coaches: {fortaleza_team.coaches.count()}')
    for coach in fortaleza_team.coaches.all():
        print(f'     - {coach.first_name} {coach.last_name} ({coach.coach_type})')
    
    print(f'   • Players: {fortaleza_team.players.count()}')
    for player in fortaleza_team.players.all()[:10]:  # Show first 10 players
        jersey = f'#{player.jersey_number}' if player.jersey_number else 'No number'
        print(f'     - {player.first_name} {player.last_name} {jersey}')
    if fortaleza_team.players.count() > 10:
        print(f'     ... and {fortaleza_team.players.count() - 10} more players')
    
    print(f'\\n✅ Fortaleza Members population completed successfully!')
    
except Exception as e:
    print(f'❌ ERROR reading Excel file: {e}')
    print('Please check the Excel file format and column names.')
    exit(1)
"

if [ $? -eq 0 ]; then
    log_success "Fortaleza Members population completed successfully"
else
    log_error "Fortaleza Members population failed"
fi

# Step 4: Final verification
log_info "Step 4: Final verification..."

# Check play categories
CATEGORY_COUNT=$(docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py shell -c "
from apps.plays.models import PlayCategory
print(PlayCategory.objects.count())
" 2>/dev/null | tail -1)

# Check play definitions
PLAY_COUNT=$(docker-compose -f "$COMPOSE_FILE" exec "$SERVICE_NAME" python manage.py shell -c "
from apps.plays.models import PlayDefinition
print(PlayDefinition.objects.count())
" 2>/dev/null | tail -1)

# Check Fortaleza team
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
echo "================================================="
log_success "🎉 Complete Fortaleza data population finished!"
echo ""
log_info "📊 Final Summary:"
echo "   • Play Categories: $CATEGORY_COUNT"
echo "   • Play Definitions: $PLAY_COUNT"
echo "   • Fortaleza Coaches: $FORTALEZA_COACHES"
echo "   • Fortaleza Players: $FORTALEZA_PLAYERS"
echo ""
log_success "Your Fortaleza team and playbook are now ready! 🏀📚"
echo ""
log_info "✅ NEW play definitions loaded from JSON"
log_info "✅ Fortaleza Members loaded from Excel"
log_info "✅ All existing data preserved"
