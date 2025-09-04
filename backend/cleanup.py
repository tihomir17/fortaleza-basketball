#!/usr/bin/env python3
"""
Backend cleanup script for the basketball analytics project.
This script removes temporary files, cache files, and other generated content.
"""

import os
import shutil
import glob
from pathlib import Path


def cleanup_python_cache():
    """Remove Python cache files and directories."""
    print("🧹 Cleaning Python cache files...")

    # Remove __pycache__ directories
    for root, dirs, files in os.walk("."):
        for dir_name in dirs:
            if dir_name == "__pycache__":
                cache_path = os.path.join(root, dir_name)
                try:
                    shutil.rmtree(cache_path)
                    print(f"  Removed: {cache_path}")
                except Exception as e:
                    print(f"  Error removing {cache_path}: {e}")

    # Remove .pyc files
    for pyc_file in glob.glob("**/*.pyc", recursive=True):
        try:
            os.remove(pyc_file)
            print(f"  Removed: {pyc_file}")
        except Exception as e:
            print(f"  Error removing {pyc_file}: {e}")


def cleanup_django_files():
    """Remove Django-specific temporary files."""
    print("🧹 Cleaning Django files...")

    # Remove database files
    db_files = ["db.sqlite3", "db.sqlite3-journal"]
    for db_file in db_files:
        if os.path.exists(db_file):
            try:
                os.remove(db_file)
                print(f"  Removed: {db_file}")
            except Exception as e:
                print(f"  Error removing {db_file}: {e}")

    # Remove log files
    if os.path.exists("logs"):
        try:
            shutil.rmtree("logs")
            print("  Removed: logs/ directory")
        except Exception as e:
            print(f"  Error removing logs/: {e}")

    # Remove migration files (except __init__.py)
    print("  Removing migration files...")
    for root, dirs, files in os.walk("."):
        if "migrations" in root and "__pycache__" not in root:
            for file in files:
                if file.endswith(".py") and file != "__init__.py":
                    migration_file = os.path.join(root, file)
                    try:
                        os.remove(migration_file)
                        print(f"    Removed: {migration_file}")
                    except Exception as e:
                        print(f"    Error removing {migration_file}: {e}")


def cleanup_test_files():
    """Remove test-related files."""
    print("🧹 Cleaning test files...")

    # Remove pytest cache
    if os.path.exists(".pytest_cache"):
        try:
            shutil.rmtree(".pytest_cache")
            print("  Removed: .pytest_cache/")
        except Exception as e:
            print(f"  Error removing .pytest_cache/: {e}")

    # Remove coverage files
    coverage_files = ["coverage.xml", ".coverage", "htmlcov/"]
    for coverage_file in coverage_files:
        if os.path.exists(coverage_file):
            try:
                if os.path.isdir(coverage_file):
                    shutil.rmtree(coverage_file)
                else:
                    os.remove(coverage_file)
                print(f"  Removed: {coverage_file}")
            except Exception as e:
                print(f"  Error removing {coverage_file}: {e}")


def cleanup_ide_files():
    """Remove IDE-specific files."""
    print("🧹 Cleaning IDE files...")

    ide_dirs = [".vscode", ".idea"]
    for ide_dir in ide_dirs:
        if os.path.exists(ide_dir):
            try:
                shutil.rmtree(ide_dir)
                print(f"  Removed: {ide_dir}/")
            except Exception as e:
                print(f"  Error removing {ide_dir}/: {e}")


def cleanup_os_files():
    """Remove OS-specific files."""
    print("🧹 Cleaning OS files...")

    os_files = [
        ".DS_Store",  # macOS
        "Thumbs.db",  # Windows
        "*.tmp",  # Temporary files
        "*.temp",  # Temporary files
    ]

    for pattern in os_files:
        for file_path in glob.glob(pattern, recursive=True):
            try:
                os.remove(file_path)
                print(f"  Removed: {file_path}")
            except Exception as e:
                print(f"  Error removing {file_path}: {e}")


def main():
    """Main cleanup function."""
    print("🚀 Starting backend cleanup...")
    print("=" * 50)

    # Change to the script's directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    cleanup_python_cache()
    cleanup_django_files()
    cleanup_test_files()
    cleanup_ide_files()
    cleanup_os_files()

    print("=" * 50)
    print("✅ Backend cleanup completed!")
    print("\n📝 Next steps:")
    print("  1. Run 'python manage.py makemigrations' to create migrations")
    print("  2. Run 'python manage.py migrate' to apply migrations")
    print("  3. Run 'python manage.py populate_db' to populate the database")
    print("  4. Run 'python manage.py runserver' to start the development server")


if __name__ == "__main__":
    main()
