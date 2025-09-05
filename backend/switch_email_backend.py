#!/usr/bin/env python3
"""
Script to switch between console and SMTP email backends.
"""

import os
import sys
from pathlib import Path

def switch_to_console():
    """Switch to console email backend for development."""
    settings_file = Path("basketball_analytics/settings.py")
    
    if not settings_file.exists():
        print("❌ Settings file not found!")
        return False
    
    # Read current settings
    with open(settings_file, 'r') as f:
        content = f.read()
    
    # Replace the email backend
    old_backend = "EMAIL_BACKEND = 'apps.games.email_backend.CustomSMTPEmailBackend'"
    new_backend = "EMAIL_BACKEND = 'apps.games.email_backend.ConsoleEmailBackend'"
    
    if old_backend in content:
        content = content.replace(old_backend, new_backend)
        print("✅ Switched to Console Email Backend")
        print("📧 Emails will be displayed in the terminal")
    elif new_backend in content:
        print("ℹ️  Already using Console Email Backend")
    else:
        print("❌ Could not find email backend setting")
        return False
    
    # Write back to file
    with open(settings_file, 'w') as f:
        f.write(content)
    
    return True

def switch_to_smtp():
    """Switch to SMTP email backend for real email sending."""
    settings_file = Path("basketball_analytics/settings.py")
    
    if not settings_file.exists():
        print("❌ Settings file not found!")
        return False
    
    # Read current settings
    with open(settings_file, 'r') as f:
        content = f.read()
    
    # Replace the email backend
    old_backend = "EMAIL_BACKEND = 'apps.games.email_backend.ConsoleEmailBackend'"
    new_backend = "EMAIL_BACKEND = 'apps.games.email_backend.CustomSMTPEmailBackend'"
    
    if old_backend in content:
        content = content.replace(old_backend, new_backend)
        print("✅ Switched to SMTP Email Backend")
        print("📧 Emails will be sent via Gmail")
    elif new_backend in content:
        print("ℹ️  Already using SMTP Email Backend")
    else:
        print("❌ Could not find email backend setting")
        return False
    
    # Write back to file
    with open(settings_file, 'w') as f:
        f.write(content)
    
    return True

def check_credentials():
    """Check if email credentials are set."""
    email_user = os.environ.get('EMAIL_HOST_USER')
    email_pass = os.environ.get('EMAIL_HOST_PASSWORD')
    
    print("📧 Email Credentials Status:")
    print(f"   EMAIL_HOST_USER: {'✅ Set' if email_user else '❌ Not set'}")
    print(f"   EMAIL_HOST_PASSWORD: {'✅ Set' if email_pass else '❌ Not set'}")
    
    if email_user and email_pass:
        print(f"   Using: {email_user}")
        return True
    else:
        print("\n💡 To set credentials, run:")
        print("   export EMAIL_HOST_USER='your-email@gmail.com'")
        print("   export EMAIL_HOST_PASSWORD='your-app-password'")
        return False

def main():
    if len(sys.argv) < 2:
        print("🏀 Basketball Analytics - Email Backend Switcher")
        print("=" * 50)
        print("Usage:")
        print("  python switch_email_backend.py console  # Use console backend")
        print("  python switch_email_backend.py smtp     # Use SMTP backend")
        print("  python switch_email_backend.py check    # Check credentials")
        return
    
    command = sys.argv[1].lower()
    
    if command == "console":
        switch_to_console()
    elif command == "smtp":
        if switch_to_smtp():
            check_credentials()
    elif command == "check":
        check_credentials()
    else:
        print("❌ Unknown command. Use: console, smtp, or check")

if __name__ == "__main__":
    main()
