#!/usr/bin/env python3
"""
Database setup script for Basketball Analytics application.
This script helps set up PostgreSQL database for production deployment.
"""

import os
import sys
import subprocess
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def create_database():
    """Create the PostgreSQL database if it doesn't exist"""
    
    # Database configuration
    db_config = {
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': os.getenv('DB_PORT', '5432'),
        'user': os.getenv('DB_USER', 'postgres'),
        'password': os.getenv('DB_PASSWORD', 'postgres'),
        'database': os.getenv('DB_NAME', 'basketball_analytics')
    }
    
    print("Setting up PostgreSQL database...")
    
    try:
        # Connect to PostgreSQL server (not to specific database)
        conn = psycopg2.connect(
            host=db_config['host'],
            port=db_config['port'],
            user=db_config['user'],
            password=db_config['password']
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Check if database exists
        cursor.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s",
            (db_config['database'],)
        )
        
        if cursor.fetchone():
            print(f"Database '{db_config['database']}' already exists.")
        else:
            # Create database
            cursor.execute(f'CREATE DATABASE "{db_config["database"]}"')
            print(f"Database '{db_config['database']}' created successfully.")
        
        cursor.close()
        conn.close()
        
        return True
        
    except psycopg2.Error as e:
        print(f"Error setting up database: {e}")
        return False

def run_migrations():
    """Run Django migrations"""
    print("Running Django migrations...")
    
    try:
        # Make migrations
        subprocess.run([sys.executable, 'manage.py', 'makemigrations'], check=True)
        print("Migrations created successfully.")
        
        # Apply migrations
        subprocess.run([sys.executable, 'manage.py', 'migrate'], check=True)
        print("Migrations applied successfully.")
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Error running migrations: {e}")
        return False

def create_superuser():
    """Create a superuser account"""
    print("Creating superuser account...")
    
    try:
        subprocess.run([sys.executable, 'manage.py', 'createsuperuser'], check=True)
        print("Superuser created successfully.")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Error creating superuser: {e}")
        return False

def load_initial_data():
    """Load initial data if needed"""
    print("Loading initial data...")
    
    try:
        # Load play definitions
        if os.path.exists('data/initial_play_definitions.json'):
            subprocess.run([
                sys.executable, 'manage.py', 'loaddata', 
                'data/initial_play_definitions.json'
            ], check=True)
            print("Initial play definitions loaded.")
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Error loading initial data: {e}")
        return False

def main():
    """Main setup function"""
    print("Basketball Analytics Database Setup")
    print("=" * 40)
    
    # Check if we're in the right directory
    if not os.path.exists('manage.py'):
        print("Error: manage.py not found. Please run this script from the backend directory.")
        sys.exit(1)
    
    # Setup steps
    steps = [
        ("Creating database", create_database),
        ("Running migrations", run_migrations),
        ("Loading initial data", load_initial_data),
    ]
    
    for step_name, step_func in steps:
        print(f"\n{step_name}...")
        if not step_func():
            print(f"Failed: {step_name}")
            sys.exit(1)
    
    print("\n" + "=" * 40)
    print("Database setup completed successfully!")
    print("\nNext steps:")
    print("1. Create a superuser: python manage.py createsuperuser")
    print("2. Start the development server: python manage.py runserver")
    print("3. Access the admin interface at: http://localhost:8000/admin/")

if __name__ == "__main__":
    main()
