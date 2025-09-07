#!/bin/bash

# Fix PostgreSQL connection issue
echo "🔧 Fixing PostgreSQL connection configuration..."

# Check if services are running
if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
    echo "✅ Services are running, restarting to apply database fix..."
    
    # Restart the web service to apply the new database configuration
    docker-compose -f docker-compose.production.yml restart web
    
    echo "✅ Web service restarted with simplified database configuration"
    echo "ℹ️  Removed problematic transaction isolation parameter (using default)"
    
    # Wait for service to be ready
    echo "⏳ Waiting for service to be ready..."
    sleep 10
    
    # Test database connection
    echo "🧪 Testing database connection..."
    if docker-compose -f docker-compose.production.yml exec web python manage.py check --database default > /dev/null 2>&1; then
        echo "✅ Database connection is working!"
        echo "🎉 You can now create a superuser:"
        echo "   docker-compose -f docker-compose.production.yml exec web python manage.py createsuperuser"
    else
        echo "⚠️  Database connection test failed. Checking logs..."
        docker-compose -f docker-compose.production.yml logs web | tail -10
    fi
    
else
    echo "❌ Services are not running. Please start them first:"
    echo "   docker-compose -f docker-compose.production.yml up -d"
fi

echo "🎉 Database connection fix complete!"
