"""
Management command to test email functionality for scouting reports.
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.games.models import ScoutingReport
from apps.games.email_service import ScoutingReportEmailService

User = get_user_model()


class Command(BaseCommand):
    help = "Test email notifications for scouting reports"

    def add_arguments(self, parser):
        parser.add_argument(
            "--email",
            type=str,
            help="Email address to send test notification to",
        )
        parser.add_argument(
            "--user-id",
            type=int,
            help="User ID to send test notification to",
        )

    def handle(self, *args, **options):
        email = options.get("email")
        user_id = options.get("user_id")

        if not email and not user_id:
            self.stdout.write(
                self.style.ERROR("Please provide either --email or --user-id")
            )
            return

        # Get user
        if user_id:
            try:
                user = User.objects.get(id=user_id)
            except User.DoesNotExist:
                self.stdout.write(self.style.ERROR(f"User with ID {user_id} not found"))
                return
        else:
            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(f"User with email {email} not found")
                )
                return

        # Create a test scouting report
        test_report = ScoutingReport(
            title="Test Scouting Report",
            description="This is a test scouting report for email notification testing.",
            report_type=ScoutingReport.ReportType.YOUTUBE_LINK,
            youtube_url="https://www.youtube.com/watch?v=test",
            created_by=user,  # Use the same user as creator for testing
        )

        self.stdout.write(f"Sending test email to {user.email}...")

        # Send test email
        success = ScoutingReportEmailService.send_scouting_report_notification(
            test_report, user
        )

        if success:
            self.stdout.write(
                self.style.SUCCESS(f"Test email sent successfully to {user.email}")
            )
        else:
            self.stdout.write(
                self.style.ERROR(f"Failed to send test email to {user.email}")
            )
