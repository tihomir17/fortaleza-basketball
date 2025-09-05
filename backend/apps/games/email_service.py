"""
Email service for sending notifications about scouting reports.
"""

from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


class ScoutingReportEmailService:
    """Service for sending scouting report email notifications."""

    @staticmethod
    def send_scouting_report_notification(report, user):
        """
        Send email notification to a user about a new scouting report.

        Args:
            report: ScoutingReport instance
            user: User instance to send notification to

        Returns:
            bool: True if email was sent successfully, False otherwise
        """
        if not user.email:
            logger.warning(
                f"User {user.username} has no email address, skipping notification"
            )
            return False

        try:
            # Get the app URL
            app_url = getattr(settings, "FRONTEND_URL", "http://localhost:8080")

            # Render email templates
            html_content = render_to_string(
                "emails/scouting_report_notification.html",
                {
                    "user": user,
                    "report": report,
                    "app_url": app_url,
                },
            )

            text_content = render_to_string(
                "emails/scouting_report_notification.txt",
                {
                    "user": user,
                    "report": report,
                    "app_url": app_url,
                },
            )

            # Create email
            subject = f"New Scouting Report: {report.title}"
            from_email = settings.DEFAULT_FROM_EMAIL
            to_email = [user.email]

            # Create multipart email
            email = EmailMultiAlternatives(
                subject=subject,
                body=text_content,
                from_email=from_email,
                to=to_email,
            )
            email.attach_alternative(html_content, "text/html")

            # Send email
            email.send()
            logger.info(
                f"Email notification sent to {user.email} for report '{report.title}'"
            )
            return True

        except Exception as e:
            logger.error(f"Error sending email to {user.email}: {e}")
            return False

    @staticmethod
    def send_bulk_notifications(report, users):
        """
        Send email notifications to multiple users about a new scouting report.

        Args:
            report: ScoutingReport instance
            users: QuerySet or list of User instances

        Returns:
            dict: Results with success/failure counts
        """
        results = {
            "total": len(users),
            "sent": 0,
            "failed": 0,
            "skipped": 0,
        }

        for user in users:
            if not user.email:
                results["skipped"] += 1
                continue

            if ScoutingReportEmailService.send_scouting_report_notification(
                report, user
            ):
                results["sent"] += 1
            else:
                results["failed"] += 1

        logger.info(f"Bulk email notification results: {results}")
        return results
