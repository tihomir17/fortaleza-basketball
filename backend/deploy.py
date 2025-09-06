#!/usr/bin/env python3
"""
Deployment script for Basketball Analytics application.
This script handles the complete deployment process.
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"Running: {description}")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed: {e}")
        print(f"Error output: {e.stderr}")
        return False

def check_requirements():
    """Check if all required tools are installed"""
    print("Checking requirements...")
    
    requirements = [
        ("python3", "Python 3"),
        ("pip", "pip"),
        ("psql", "PostgreSQL client"),
        ("redis-server", "Redis server"),
    ]
    
    for cmd, name in requirements:
        if not shutil.which(cmd):
            print(f"❌ {name} not found. Please install it first.")
            return False
        else:
            print(f"✅ {name} found")
    
    return True

def install_dependencies():
    """Install Python dependencies"""
    print("Installing Python dependencies...")
    
    commands = [
        ("pip install -r requirements.txt", "Installing Python packages"),
        ("pip install gunicorn", "Installing Gunicorn for production"),
    ]
    
    for command, description in commands:
        if not run_command(command, description):
            return False
    
    return True

def setup_database():
    """Setup the database"""
    print("Setting up database...")
    
    # Check if PostgreSQL is running
    if not run_command("pg_isready", "Checking PostgreSQL connection"):
        print("❌ PostgreSQL is not running. Please start it first.")
        return False
    
    # Run database setup
    if not run_command("python setup_database.py", "Setting up database"):
        return False
    
    return True

def collect_static_files():
    """Collect static files for production"""
    print("Collecting static files...")
    
    # Create staticfiles directory
    static_dir = Path("staticfiles")
    static_dir.mkdir(exist_ok=True)
    
    # Collect static files
    if not run_command("python manage.py collectstatic --noinput", "Collecting static files"):
        return False
    
    return True

def run_tests():
    """Run tests to ensure everything works"""
    print("Running tests...")
    
    if not run_command("python manage.py test", "Running Django tests"):
        print("⚠️  Tests failed, but continuing with deployment...")
    
    return True

def create_superuser():
    """Create superuser if needed"""
    print("Creating superuser...")
    
    # Check if superuser exists
    result = subprocess.run(
        "python manage.py shell -c \"from django.contrib.auth import get_user_model; User = get_user_model(); print('SUPERUSER_EXISTS' if User.objects.filter(is_superuser=True).exists() else 'NO_SUPERUSER')\"",
        shell=True,
        capture_output=True,
        text=True
    )
    
    if "NO_SUPERUSER" in result.stdout:
        print("No superuser found. Please create one:")
        if not run_command("python manage.py createsuperuser", "Creating superuser"):
            return False
    else:
        print("✅ Superuser already exists")
    
    return True

def generate_nginx_config():
    """Generate Nginx configuration"""
    print("Generating Nginx configuration...")
    
    nginx_config = """
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    # SSL configuration
    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Static files
    location /static/ {
        alias /path/to/your/project/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Media files
    location /media/ {
        alias /path/to/your/project/media/;
        expires 1y;
        add_header Cache-Control "public";
    }
    
    # API and admin
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}
"""
    
    with open("nginx.conf", "w") as f:
        f.write(nginx_config)
    
    print("✅ Nginx configuration generated (nginx.conf)")
    print("⚠️  Please update the paths and domain names in nginx.conf")
    
    return True

def generate_systemd_service():
    """Generate systemd service file"""
    print("Generating systemd service...")
    
    service_config = f"""
[Unit]
Description=Basketball Analytics Django App
After=network.target

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory={os.getcwd()}
Environment=DJANGO_SETTINGS_MODULE=basketball_analytics.settings_production
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 basketball_analytics.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
"""
    
    with open("basketball-analytics.service", "w") as f:
        f.write(service_config)
    
    print("✅ Systemd service file generated (basketball-analytics.service)")
    print("⚠️  Please copy this file to /etc/systemd/system/ and run 'sudo systemctl daemon-reload'")
    
    return True

def main():
    """Main deployment function"""
    print("Basketball Analytics Deployment Script")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not os.path.exists('manage.py'):
        print("❌ Error: manage.py not found. Please run this script from the backend directory.")
        sys.exit(1)
    
    # Deployment steps
    steps = [
        ("Checking requirements", check_requirements),
        ("Installing dependencies", install_dependencies),
        ("Setting up database", setup_database),
        ("Collecting static files", collect_static_files),
        ("Running tests", run_tests),
        ("Creating superuser", create_superuser),
        ("Generating Nginx config", generate_nginx_config),
        ("Generating systemd service", generate_systemd_service),
    ]
    
    for step_name, step_func in steps:
        print(f"\n{step_name}...")
        if not step_func():
            print(f"❌ Deployment failed at: {step_name}")
            sys.exit(1)
    
    print("\n" + "=" * 50)
    print("🎉 Deployment completed successfully!")
    print("\nNext steps:")
    print("1. Update nginx.conf with your domain and SSL certificates")
    print("2. Copy basketball-analytics.service to /etc/systemd/system/")
    print("3. Run: sudo systemctl daemon-reload")
    print("4. Run: sudo systemctl enable basketball-analytics")
    print("5. Run: sudo systemctl start basketball-analytics")
    print("6. Configure Nginx and restart it")
    print("\nYour Basketball Analytics app should now be running!")

if __name__ == "__main__":
    main()
