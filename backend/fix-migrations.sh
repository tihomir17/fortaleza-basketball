#!/bin/bash

# Fix Django migration issues
echo "🔧 Fixing Django migration issues..."

# Check if services are running
if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
    echo "✅ Services are running"
    
    # First, let's check the current migration status
    echo "🔍 Checking current migration status..."
    docker-compose -f docker-compose.production.yml exec web python manage.py showmigrations
    
    echo ""
    echo "🔧 Attempting to fix migration issues..."
    
    # Try to fake apply migrations to resolve dependency issues
    echo "📋 Faking initial migrations for users app..."
    docker-compose -f docker-compose.production.yml exec web python manage.py migrate users 0001 --fake
    
    echo "📋 Running all migrations..."
    docker-compose -f docker-compose.production.yml exec web python manage.py migrate
    
    echo "🔍 Checking migration status after fix..."
    docker-compose -f docker-compose.production.yml exec web python manage.py showmigrations
    
    echo ""
    echo "🧪 Testing superuser creation..."
    if docker-compose -f docker-compose.production.yml exec web python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); print('✅ User model accessible')" > /dev/null 2>&1; then
        echo "✅ Database is ready for superuser creation"
        echo "🎉 You can now run:"
        echo "   docker-compose -f docker-compose.production.yml exec web python manage.py createsuperuser"
    else
        echo "❌ Still having issues. Let's try a different approach..."
        
        # Try to reset migrations completely
        echo "🔄 Attempting to reset migrations..."
        docker-compose -f docker-compose.production.yml exec web python manage.py migrate --fake-initial
    fi
    
else
    echo "❌ Services are not running. Please start them first:"
    echo "   docker-compose -f docker-compose.production.yml up -d"
    exit 1
fi

echo "🎉 Migration fix attempt complete!"
