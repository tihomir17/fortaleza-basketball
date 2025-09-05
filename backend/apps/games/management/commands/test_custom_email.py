"""
Management command to test the custom email backend.
"""

from django.core.management.base import BaseCommand
from django.core.mail import send_mail
from django.conf import settings


class Command(BaseCommand):
    help = "Test the custom email backend"

    def add_arguments(self, parser):
        parser.add_argument(
            "--email",
            type=str,
            help="Email address to send test notification to",
            required=True,
        )

    def handle(self, *args, **options):
        email = options.get("email")

        self.stdout.write(f"Testing custom email backend...")
        self.stdout.write(f"EMAIL_BACKEND: {settings.EMAIL_BACKEND}")
        self.stdout.write(f"EMAIL_HOST: {settings.EMAIL_HOST}")
        self.stdout.write(f"EMAIL_PORT: {settings.EMAIL_PORT}")
        self.stdout.write(f"EMAIL_USE_TLS: {settings.EMAIL_USE_TLS}")

        try:
            # Send a simple test email
            send_mail(
                subject="Test Email from Basketball Analytics",
                message="This is a test email to verify the custom email backend is working correctly.",
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                fail_silently=False,
            )

            self.stdout.write(
                self.style.SUCCESS(f"Test email sent successfully to {email}")
            )

        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Failed to send test email: {e}"))
