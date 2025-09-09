#!/bin/bash

# Rebuild and Populate Script
# This script rebuilds the backend container with new files and populates the data

set -e

echo "🏀 Fortaleza Basketball - Rebuild and Populate"
echo "============================================="

# Configuration
COMPOSE_FILE="docker-compose.production.yml"
SERVICE_NAME="web"
IMAGE_NAME="us-central1-docker.pkg.dev/inat-drive/inatdrive/backend:latest"

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

# Check if gcloud is authenticated
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" | grep -q "@"; then
    log_error "Google Cloud is not authenticated. Please run 'gcloud auth login' first."
fi

log_success "Prerequisites check passed"

# Step 1: Stop the current service
log_step "Step 1: Stopping current backend service..."
log_info "Stopping web service to prepare for rebuild..."

if docker-compose -f "$COMPOSE_FILE" stop web; then
    log_success "Web service stopped successfully"
else
    log_warning "Web service was not running or failed to stop"
fi

# Step 2: Build new backend image with updated files
log_step "Step 2: Building new backend image with updated files..."
log_info "Building backend image with new initial_play_definitions.json and Fortaleza Members.xlsx..."

if docker buildx build --platform linux/amd64,linux/arm64 -t "$IMAGE_NAME" --push .; then
    log_success "Backend image built and pushed successfully"
else
    log_error "Failed to build and push backend image"
fi

# Step 3: Pull the new image
log_step "Step 3: Pulling new backend image..."
log_info "Pulling the updated backend image..."

if docker pull "$IMAGE_NAME"; then
    log_success "Backend image pulled successfully"
else
    log_error "Failed to pull backend image"
fi

# Step 4: Start the service with new image
log_step "Step 4: Starting service with new image..."
log_info "Starting web service with updated backend image..."

if docker-compose -f "$COMPOSE_FILE" up -d web; then
    log_success "Web service started successfully"
else
    log_error "Failed to start web service"
fi

# Step 5: Wait for service to be ready
log_step "Step 5: Waiting for service to be ready..."
log_info "Waiting for web service to be healthy..."

for i in {1..30}; do
    if docker-compose -f "$COMPOSE_FILE" exec web python manage.py check > /dev/null 2>&1; then
        log_success "Web service is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Web service failed to become healthy after 30 seconds"
    fi
    sleep 2
done

# Step 6: Run migrations
log_step "Step 6: Running database migrations..."
log_info "Running migrations to ensure database schema is up to date..."

if docker-compose -f "$COMPOSE_FILE" exec web python manage.py migrate; then
    log_success "Database migrations completed successfully"
else
    log_error "Database migrations failed"
fi

# Step 7: Populate play definitions
log_step "Step 7: Populating play definitions..."
log_info "Loading play definitions from initial_play_definitions.json..."

docker-compose -f "$COMPOSE_FILE" exec web python -c "
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

# Step 8: Populate Fortaleza Members
log_step "Step 8: Populating Fortaleza Members..."
log_info "Loading Fortaleza Members from Excel file..."

docker-compose -f "$COMPOSE_FILE" exec web python -c "
import os
import pandas as pd
import django
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'basketball_analytics.settings')
django.setup()

from apps.teams.models import Team
from apps.competitions.models import Competition
from django.contrib.auth import get_user_model

User = get_user_model()

print('🏀 Loading Fortaleza Members from Excel...')

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

try:
    df = pd.read_excel('/app/data/Infos - Fortaleza Members.xlsx')
    print(f'📊 Found {len(df)} rows in Excel file')
    
    coaches_created = 0
    players_created = 0
    
    for index, row in df.iterrows():
        try:
            first_name = str(row.get('First Name', '')).strip()
            last_name = str(row.get('Last Name', '')).strip()
            role = str(row.get('Role', '')).strip().upper()
            jersey_number = row.get('Jersey Number', None)
            coach_type = str(row.get('Coach Type', '')).strip().upper()
            
            if not first_name or not last_name:
                continue
                
            username = f'{first_name.lower()}.{last_name.lower()}'
            
            if role == 'COACH' or 'COACH' in role:
                coach_type_enum = User.CoachType.HEAD_COACH if coach_type == 'HEAD_COACH' else User.CoachType.ASSISTANT_COACH
                
                user, created = User.objects.get_or_create(
                    username=username,
                    defaults={
                        'first_name': first_name,
                        'last_name': last_name,
                        'role': User.Role.COACH,
                        'coach_type': coach_type_enum,
                        'password': 'fortaleza2025',
                    }
                )
                
                if created:
                    coaches_created += 1
                
                fortaleza_team.coaches.add(user)
                
            else:
                user, created = User.objects.get_or_create(
                    username=username,
                    defaults={
                        'first_name': first_name,
                        'last_name': last_name,
                        'role': User.Role.PLAYER,
                        'jersey_number': jersey_number if jersey_number else None,
                        'password': 'fortaleza2025',
                    }
                )
                
                if created:
                    players_created += 1
                
                fortaleza_team.players.add(user)
                
        except Exception as e:
            print(f'⚠️  Error processing row {index}: {e}')
            continue
    
    print(f'✅ Fortaleza Members: {coaches_created} coaches, {players_created} players created')
    print(f'📊 Total Fortaleza team: {fortaleza_team.coaches.count()} coaches, {fortaleza_team.players.count()} players')
    
except Exception as e:
    print(f'❌ ERROR reading Excel file: {e}')
    exit(1)
"

if [ $? -eq 0 ]; then
    log_success "Fortaleza Members population completed successfully"
else
    log_error "Fortaleza Members population failed"
fi

# Step 9: Final verification
log_step "Step 9: Final verification..."

# Check play categories
CATEGORY_COUNT=$(docker-compose -f "$COMPOSE_FILE" exec web python manage.py shell -c "
from apps.plays.models import PlayCategory
print(PlayCategory.objects.count())
" 2>/dev/null | tail -1)

# Check play definitions
PLAY_COUNT=$(docker-compose -f "$COMPOSE_FILE" exec web python manage.py shell -c "
from apps.plays.models import PlayDefinition
print(PlayDefinition.objects.count())
" 2>/dev/null | tail -1)

# Check Fortaleza team
FORTALEZA_COACHES=$(docker-compose -f "$COMPOSE_FILE" exec web python manage.py shell -c "
from apps.teams.models import Team
fortaleza = Team.objects.filter(name__icontains='Fortaleza').first()
if fortaleza:
    print(fortaleza.coaches.count())
else:
    print(0)
" 2>/dev/null | tail -1)

FORTALEZA_PLAYERS=$(docker-compose -f "$COMPOSE_FILE" exec web python manage.py shell -c "
from apps.teams.models import Team
fortaleza = Team.objects.filter(name__icontains='Fortaleza').first()
if fortaleza:
    print(fortaleza.players.count())
else:
    print(0)
" 2>/dev/null | tail -1)

# Show container status
log_info "Container status:"
docker-compose -f "$COMPOSE_FILE" ps

echo ""
echo "============================================="
log_success "🎉 Rebuild and populate completed successfully!"
echo ""
log_info "📊 Final Summary:"
echo "   • Play Categories: $CATEGORY_COUNT"
echo "   • Play Definitions: $PLAY_COUNT"
echo "   • Fortaleza Coaches: $FORTALEZA_COACHES"
echo "   • Fortaleza Players: $FORTALEZA_PLAYERS"
echo ""
log_info "🔧 What was done:"
echo "   • Backend container rebuilt with new files"
echo "   • New play definitions loaded from JSON"
echo "   • Fortaleza Members loaded from Excel"
echo "   • All existing data preserved"
echo ""
log_success "Your Fortaleza team and playbook are now ready! 🏀📚"
