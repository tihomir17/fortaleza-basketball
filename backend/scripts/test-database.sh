#!/bin/bash

# Test database connection and migrations
echo "🧪 Testing database connection and setup..."

# Check if services are running
if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
    echo "✅ Services are running"
    
    # Test database connection
    echo "🔍 Testing database connection..."
    if docker-compose -f docker-compose.production.yml exec web python manage.py check --database default > /dev/null 2>&1; then
        echo "✅ Database connection successful!"
    else
        echo "❌ Database connection failed"
        echo "📋 Checking database logs..."
        docker-compose -f docker-compose.production.yml logs db | tail -5
        exit 1
    fi
    
    # Check if migrations are needed
    echo "🔍 Checking for pending migrations..."
    if docker-compose -f docker-compose.production.yml exec web python manage.py showmigrations --plan | grep -q "\[ \]"; then
        echo "⚠️  Pending migrations found. Running migrations..."
        docker-compose -f docker-compose.production.yml exec web python manage.py migrate
        echo "✅ Migrations completed"
    else
        echo "✅ No pending migrations"
    fi
    
    # Test superuser creation
    echo "🔍 Testing superuser creation capability..."
    if docker-compose -f docker-compose.production.yml exec web python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); print('✅ User model accessible')" > /dev/null 2>&1; then
        echo "✅ Database is ready for superuser creation"
        echo "🎉 You can now run:"
        echo "   docker-compose -f docker-compose.production.yml exec web python manage.py createsuperuser"
    else
        echo "❌ Database not ready for superuser creation"
        exit 1
    fi
    
else
    echo "❌ Services are not running. Please start them first:"
    echo "   docker-compose -f docker-compose.production.yml up -d"
    exit 1
fi

echo "🎉 Database test complete!"
