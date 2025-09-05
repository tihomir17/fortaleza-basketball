"""
Management command to check scouting reports in the database.
"""

from django.core.management.base import BaseCommand
from apps.games.models import ScoutingReport
from apps.users.models import User


class Command(BaseCommand):
    help = "Check scouting reports in the database"

    def handle(self, *args, **options):
        self.stdout.write("Checking scouting reports...")

        # Get all reports
        reports = ScoutingReport.objects.all().order_by("-created_at")

        if not reports:
            self.stdout.write(
                self.style.WARNING("No scouting reports found in database")
            )
            return

        self.stdout.write(f"Found {reports.count()} scouting reports:")
        self.stdout.write("-" * 80)

        for report in reports:
            self.stdout.write(f"ID: {report.id}")
            self.stdout.write(f"Title: {report.title}")
            self.stdout.write(f"Type: {report.report_type}")
            self.stdout.write(f"Created by: {report.created_by.username}")
            self.stdout.write(f"File size: {report.file_size} bytes")
            self.stdout.write(f"Created at: {report.created_at}")
            self.stdout.write(f"PDF file: {report.pdf_file}")
            self.stdout.write(f"YouTube URL: {report.youtube_url}")
            self.stdout.write("-" * 80)

        # Check for potential issues
        self.stdout.write("\nChecking for potential issues:")

        # Check for reports with 0 file size
        zero_size_reports = reports.filter(file_size=0)
        if zero_size_reports:
            self.stdout.write(
                f"⚠️  Found {zero_size_reports.count()} reports with 0 file size"
            )
            for report in zero_size_reports:
                self.stdout.write(f"   - {report.title} (ID: {report.id})")

        # Check for reports with null file size
        null_size_reports = reports.filter(file_size__isnull=True)
        if null_size_reports:
            self.stdout.write(
                f"ℹ️  Found {null_size_reports.count()} reports with null file size"
            )
            for report in null_size_reports:
                self.stdout.write(
                    f"   - {report.title} (ID: {report.id}, Type: {report.report_type})"
                )

        # Check for YouTube reports
        youtube_reports = reports.filter(
            report_type=ScoutingReport.ReportType.YOUTUBE_LINK
        )
        if youtube_reports:
            self.stdout.write(f"🎥 Found {youtube_reports.count()} YouTube reports")

        # Check for PDF reports
        pdf_reports = reports.filter(report_type=ScoutingReport.ReportType.UPLOADED_PDF)
        if pdf_reports:
            self.stdout.write(f"📄 Found {pdf_reports.count()} PDF reports")
