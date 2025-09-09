#!/bin/bash

# Simple one-liner script to populate playbook
# Usage: ./scripts/populate_playbook.sh

echo "🏀 Populating playbook from initial_play_definitions.json..."

docker-compose -f docker-compose.production.yml exec web python -c "
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
                'play_type': 'OFFENSIVE',
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

print(f'\\n🏀 Play Categories Summary:')
for category in PlayCategory.objects.all():
    count = category.plays.count()
    print(f'   • {category.name}: {count} plays')

print(f'\\n✅ Playbook population completed successfully!')
"

echo "🎉 Done! Your playbook is now populated."
