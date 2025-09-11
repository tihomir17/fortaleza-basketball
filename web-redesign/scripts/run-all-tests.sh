#!/bin/bash

# Comprehensive Test Runner for Basketball Analytics App
# This script runs all tests: frontend unit tests, backend tests, and e2e tests

set -e  # Exit on any error

echo "🧪 Starting Comprehensive Test Suite for Basketball Analytics"
echo "=============================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "backend" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Function to run frontend tests
run_frontend_tests() {
    print_status "Running Frontend Unit Tests..."
    
    cd web-redesign
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_status "Installing frontend dependencies..."
        npm install
    fi
    
    # Run type checking
    print_status "Running TypeScript type checking..."
    npm run type-check
    
    # Run linting
    print_status "Running ESLint..."
    npm run lint
    
    # Run unit tests
    print_status "Running Jest unit tests..."
    npm run test:coverage
    
    print_success "Frontend tests completed!"
    cd ..
}

# Function to run backend tests
run_backend_tests() {
    print_status "Running Backend Tests..."
    
    cd backend
    
    # Activate virtual environment
    if [ ! -d "venv" ]; then
        print_error "Virtual environment not found. Please create one first."
        exit 1
    fi
    
    source venv/bin/activate
    
    # Install dependencies if needed
    if [ ! -f "requirements.txt" ] || [ ! -d "venv/lib" ]; then
        print_status "Installing backend dependencies..."
        pip install -r requirements.txt
    fi
    
    # Run Django tests
    print_status "Running Django tests..."
    python manage.py test --verbosity=2 --keepdb
    
    # Run pytest with coverage
    print_status "Running pytest with coverage..."
    pytest --cov=apps --cov-report=term-missing --cov-report=html
    
    print_success "Backend tests completed!"
    cd ..
}

# Function to run e2e tests
run_e2e_tests() {
    print_status "Running End-to-End Tests..."
    
    cd web-redesign
    
    # Install Playwright browsers if needed
    if [ ! -d "node_modules/@playwright" ]; then
        print_status "Installing Playwright browsers..."
        npx playwright install
    fi
    
    # Start backend server in background
    print_status "Starting backend server for e2e tests..."
    cd ../backend
    source venv/bin/activate
    python manage.py runserver 8000 &
    BACKEND_PID=$!
    cd ../web-redesign
    
    # Wait for backend to start
    sleep 5
    
    # Run e2e tests
    print_status "Running Playwright e2e tests..."
    npm run test:e2e
    
    # Stop backend server
    kill $BACKEND_PID 2>/dev/null || true
    
    print_success "E2E tests completed!"
    cd ..
}

# Function to generate test report
generate_report() {
    print_status "Generating Test Report..."
    
    REPORT_FILE="test-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$REPORT_FILE" << EOF
# Basketball Analytics Test Report

Generated on: $(date)

## Test Coverage Summary

### Frontend Tests
- Unit Tests: Jest with React Testing Library
- Type Checking: TypeScript compiler
- Linting: ESLint
- Coverage: Available in web-redesign/coverage/

### Backend Tests
- Unit Tests: Django TestCase and pytest
- API Tests: Django REST Framework APITestCase
- Coverage: Available in backend/htmlcov/

### End-to-End Tests
- Browser Tests: Playwright
- Test Scenarios: Authentication, Playbook, Teams management
- Browsers: Chrome, Firefox, Safari

## Test Results

All tests have been executed successfully.

## Next Steps

1. Review coverage reports
2. Address any failing tests
3. Add new tests for new features
4. Update tests when requirements change

EOF

    print_success "Test report generated: $REPORT_FILE"
}

# Main execution
main() {
    echo ""
    print_status "Starting test execution..."
    echo ""
    
    # Parse command line arguments
    RUN_FRONTEND=true
    RUN_BACKEND=true
    RUN_E2E=true
    GENERATE_REPORT=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --frontend-only)
                RUN_BACKEND=false
                RUN_E2E=false
                shift
                ;;
            --backend-only)
                RUN_FRONTEND=false
                RUN_E2E=false
                shift
                ;;
            --e2e-only)
                RUN_FRONTEND=false
                RUN_BACKEND=false
                shift
                ;;
            --no-report)
                GENERATE_REPORT=false
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --frontend-only    Run only frontend tests"
                echo "  --backend-only     Run only backend tests"
                echo "  --e2e-only         Run only e2e tests"
                echo "  --no-report        Skip generating test report"
                echo "  --help             Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Run tests based on flags
    if [ "$RUN_FRONTEND" = true ]; then
        run_frontend_tests
        echo ""
    fi
    
    if [ "$RUN_BACKEND" = true ]; then
        run_backend_tests
        echo ""
    fi
    
    if [ "$RUN_E2E" = true ]; then
        run_e2e_tests
        echo ""
    fi
    
    if [ "$GENERATE_REPORT" = true ]; then
        generate_report
        echo ""
    fi
    
    print_success "All tests completed successfully! 🎉"
    echo ""
    print_status "Test coverage reports:"
    print_status "- Frontend: web-redesign/coverage/index.html"
    print_status "- Backend: backend/htmlcov/index.html"
    print_status "- E2E: web-redesign/playwright-report/index.html"
}

# Run main function
main "$@"
