#!/usr/bin/env python3
"""
Email setup script for Basketball Analytics.
This script helps you configure email credentials for Gmail SMTP.
"""

import os
import getpass
from pathlib import Path


def setup_email_credentials():
    """Interactive setup for email credentials."""
    print("🏀 Basketball Analytics - Email Setup")
    print("=" * 50)
    print()

    print("To send email notifications, you need to configure Gmail SMTP.")
    print("Follow these steps:")
    print()
    print("1. Enable 2-Factor Authentication on your Gmail account")
    print("2. Generate an App Password:")
    print("   - Go to: https://myaccount.google.com/security")
    print("   - Click '2-Step Verification'")
    print("   - Scroll down to 'App passwords'")
    print("   - Generate a password for 'Mail'")
    print("   - Copy the 16-character password")
    print()

    email = input("Enter your Gmail address: ").strip()
    if not email or "@gmail.com" not in email:
        print("❌ Please enter a valid Gmail address")
        return False

    print()
    print("Enter your Gmail App Password (16 characters, no spaces):")
    app_password = getpass.getpass("App Password: ").strip()

    if len(app_password) != 16 or not app_password.isalnum():
        print("❌ App password should be 16 alphanumeric characters")
        return False

    # Create .env file
    env_file = Path(".env")
    env_content = f"""# Basketball Analytics Email Configuration
EMAIL_HOST_USER={email}
EMAIL_HOST_PASSWORD={app_password}
"""

    try:
        with open(env_file, "w") as f:
            f.write(env_content)

        print()
        print("✅ Email credentials saved to .env file")
        print()
        print("To use these credentials, you need to:")
        print("1. Install python-dotenv: pip install python-dotenv")
        print("2. Load environment variables in settings.py")
        print()
        print("Or set environment variables manually:")
        print(f"export EMAIL_HOST_USER='{email}'")
        print(f"export EMAIL_HOST_PASSWORD='{app_password}'")
        print()

        return True

    except Exception as e:
        print(f"❌ Error saving credentials: {e}")
        return False


def test_email_connection():
    """Test the email connection."""
    print("Testing email connection...")

    try:
        from django.core.mail import send_mail
        from django.conf import settings

        # Test email
        send_mail(
            subject="Test Email from Basketball Analytics",
            message="This is a test email to verify your configuration is working.",
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[settings.EMAIL_HOST_USER],
            fail_silently=False,
        )

        print("✅ Email sent successfully!")
        return True

    except Exception as e:
        print(f"❌ Email test failed: {e}")
        return False


if __name__ == "__main__":
    if setup_email_credentials():
        print("Would you like to test the email connection? (y/n): ", end="")
        if input().lower().startswith("y"):
            test_email_connection()
