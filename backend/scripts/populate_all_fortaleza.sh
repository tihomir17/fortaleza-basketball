#!/bin/bash

# Simple one-liner script to populate all Fortaleza data
# Usage: ./scripts/populate_all_fortaleza.sh

echo "🏀 Populating all Fortaleza data (play definitions + members)..."

# Step 1: Populate play definitions
echo "📚 Step 1: Loading play definitions..."
docker-compose -f docker-compose.production.yml exec web python -c "
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

# Step 2: Populate Fortaleza Members
echo "👥 Step 2: Loading Fortaleza Members..."
docker-compose -f docker-compose.production.yml exec web python -c "
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

echo "🎉 Done! All Fortaleza data has been populated."
