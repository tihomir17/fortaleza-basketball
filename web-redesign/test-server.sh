#!/bin/bash

echo "🚀 Testing Fortaleza Basketball Analytics Web App"
echo "=================================================="
echo ""

# Check if server is running
if lsof -i :5174 > /dev/null 2>&1; then
    echo "✅ Server is running on port 5174"
else
    echo "❌ Server is not running. Starting it now..."
    npm run dev &
    sleep 3
fi

echo ""
echo "🌐 Open your browser and go to:"
echo "   http://localhost:5174"
echo ""
echo "📱 If you see a blank screen:"
echo "   1. Press Ctrl+Shift+R (or Cmd+Shift+R on Mac) to hard refresh"
echo "   2. Open browser developer tools (F12)"
echo "   3. Check the Console tab for any errors"
echo ""
echo "🎯 You should see:"
echo "   - A centered card with 'Fortaleza Basketball Analytics'"
echo "   - Three colored status boxes (green, blue, purple)"
echo "   - Server info at the bottom"
echo ""

# Test the server
echo "🔍 Testing server response..."
if curl -s http://localhost:5174 | grep -q "Fortaleza"; then
    echo "✅ Server is responding with Fortaleza content"
else
    echo "⚠️  Server is responding but content might not be loading"
    echo "   Try hard refresh (Ctrl+Shift+R) in your browser"
fi

echo ""
echo "📞 If still having issues:"
echo "   1. Check browser console for JavaScript errors"
echo "   2. Try incognito/private browsing mode"
echo "   3. Make sure you're on http://localhost:5174 (not 5173)"
