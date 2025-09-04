#!/bin/bash

echo "🚀 Setting up pre-commit hooks for Fortaleza Basketball project..."

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "❌ pre-commit not found. Installing..."
    pip install pre-commit
else
    echo "✅ pre-commit already installed"
fi

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend
pip install -r requirements.txt

# Install backend pre-commit hooks
echo "🔧 Installing backend pre-commit hooks..."
pre-commit install

cd ..

# Install frontend pre-commit hooks
echo "🔧 Installing frontend pre-commit hooks..."
cd frontend
pre-commit install

cd ..

# Install root-level pre-commit hooks
echo "🔧 Installing root-level pre-commit hooks..."
pre-commit install

echo "✅ Pre-commit setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Make a test commit to verify hooks are working"
echo "2. Run 'pre-commit run --all-files' to check existing code"
echo "3. Check SETUP_PRE_COMMIT.md for detailed usage instructions"
echo ""
echo "🔧 Available commands:"
echo "- pre-commit run --all-files    # Run all hooks on all files"
echo "- pre-commit run black          # Run specific hook"
echo "- pre-commit autoupdate         # Update hook versions"
