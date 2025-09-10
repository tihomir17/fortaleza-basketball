#!/bin/bash

# Production deployment script for Fortaleza Basketball Web App
set -e

# Configuration
APP_NAME="fortaleza-basketball-web"
BUILD_DIR="dist"
BACKUP_DIR="backups"
DEPLOY_DIR="/var/www/fortaleza-basketball"
NGINX_CONFIG="/etc/nginx/sites-available/fortaleza-basketball"
NGINX_ENABLED="/etc/nginx/sites-enabled/fortaleza-basketball"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
    fi
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed"
    fi
    
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        error "npm is not installed"
    fi
    
    # Check if nginx is installed
    if ! command -v nginx &> /dev/null; then
        error "nginx is not installed"
    fi
    
    log "Prerequisites check passed"
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."
    npm ci --production=false
    log "Dependencies installed"
}

# Run tests
run_tests() {
    log "Running tests..."
    npm run test
    npm run test:e2e
    log "All tests passed"
}

# Build application
build_application() {
    log "Building application for production..."
    npm run build:prod
    
    if [ ! -d "$BUILD_DIR" ]; then
        error "Build directory not found"
    fi
    
    log "Application built successfully"
}

# Create backup
create_backup() {
    if [ -d "$DEPLOY_DIR" ]; then
        log "Creating backup..."
        BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
        sudo mkdir -p "$BACKUP_DIR"
        sudo cp -r "$DEPLOY_DIR" "$BACKUP_DIR/$BACKUP_NAME"
        log "Backup created: $BACKUP_DIR/$BACKUP_NAME"
    fi
}

# Deploy application
deploy_application() {
    log "Deploying application..."
    
    # Create deploy directory if it doesn't exist
    sudo mkdir -p "$DEPLOY_DIR"
    
    # Copy build files
    sudo cp -r "$BUILD_DIR"/* "$DEPLOY_DIR/"
    
    # Set proper permissions
    sudo chown -R www-data:www-data "$DEPLOY_DIR"
    sudo chmod -R 755 "$DEPLOY_DIR"
    
    log "Application deployed successfully"
}

# Configure nginx
configure_nginx() {
    log "Configuring nginx..."
    
    # Create nginx configuration
    sudo tee "$NGINX_CONFIG" > /dev/null <<EOF
server {
    listen 80;
    server_name fortaleza-basketball.com www.fortaleza-basketball.com;
    root $DEPLOY_DIR;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Handle client-side routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # API proxy (if needed)
    location /api/ {
        proxy_pass http://localhost:8000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Enable site
    sudo ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
    
    # Test nginx configuration
    sudo nginx -t
    
    # Reload nginx
    sudo systemctl reload nginx
    
    log "Nginx configured successfully"
}

# Setup SSL (Let's Encrypt)
setup_ssl() {
    if command -v certbot &> /dev/null; then
        log "Setting up SSL certificate..."
        sudo certbot --nginx -d fortaleza-basketball.com -d www.fortaleza-basketball.com --non-interactive --agree-tos --email admin@fortaleza-basketball.com
        log "SSL certificate configured"
    else
        warning "certbot not found, skipping SSL setup"
    fi
}

# Health check
health_check() {
    log "Performing health check..."
    
    # Wait for nginx to reload
    sleep 2
    
    # Check if the site is accessible
    if curl -f -s http://localhost > /dev/null; then
        log "Health check passed"
    else
        error "Health check failed"
    fi
}

# Cleanup
cleanup() {
    log "Cleaning up..."
    rm -rf "$BUILD_DIR"
    log "Cleanup completed"
}

# Main deployment function
main() {
    log "Starting deployment of $APP_NAME"
    
    check_root
    check_prerequisites
    install_dependencies
    run_tests
    build_application
    create_backup
    deploy_application
    configure_nginx
    setup_ssl
    health_check
    cleanup
    
    log "Deployment completed successfully!"
    log "Application is now available at: http://fortaleza-basketball.com"
}

# Run main function
main "$@"
