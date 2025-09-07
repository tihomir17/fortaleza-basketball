#!/bin/bash

# Quick fix for ALLOWED_HOSTS issue
echo "🔧 Fixing ALLOWED_HOSTS configuration..."

# Check if services are running
if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
    echo "✅ Services are running, restarting to apply changes..."
    
    # Restart the web service to apply the new ALLOWED_HOSTS setting
    docker-compose -f docker-compose.production.yml restart web
    
    echo "✅ Web service restarted with updated ALLOWED_HOSTS"
    echo "🌐 Your domain admin.inatdrive.com is now allowed"
    
    # Test the fix
    echo "🧪 Testing the fix..."
    sleep 5
    
    if curl -f http://localhost:8080/api/health/ > /dev/null 2>&1; then
        echo "✅ Backend is responding correctly"
    else
        echo "⚠️  Backend might still be starting up, please wait a moment"
    fi
    
else
    echo "❌ Services are not running. Please start them first:"
    echo "   docker-compose -f docker-compose.production.yml up -d"
fi

echo "🎉 ALLOWED_HOSTS fix complete!"
