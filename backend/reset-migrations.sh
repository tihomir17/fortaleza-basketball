#!/bin/bash

# Reset Django migrations completely
echo "🔄 Resetting Django migrations..."

# Check if services are running
if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
    echo "✅ Services are running"
    
    echo "⚠️  WARNING: This will reset all migrations. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ Operation cancelled"
        exit 1
    fi
    
    echo "🔧 Resetting migrations..."
    
    # Drop and recreate database
    echo "🗑️  Dropping and recreating database..."
    docker-compose -f docker-compose.production.yml exec db psql -U postgres -c "DROP DATABASE IF EXISTS basketball_analytics;"
    docker-compose -f docker-compose.production.yml exec db psql -U postgres -c "CREATE DATABASE basketball_analytics;"
    
    # Run migrations from scratch
    echo "📋 Running migrations from scratch..."
    docker-compose -f docker-compose.production.yml exec web python manage.py migrate
    
    # Create superuser
    echo "👤 Creating superuser..."
    docker-compose -f docker-compose.production.yml exec web python manage.py createsuperuser
    
    echo "✅ Migration reset complete!"
    echo "🎉 Database is now ready with fresh migrations"
    
else
    echo "❌ Services are not running. Please start them first:"
    echo "   docker-compose -f docker-compose.production.yml up -d"
    exit 1
fi
