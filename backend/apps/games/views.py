from typing import Any, Dict, List, Optional, Type
from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.decorators import action
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from datetime import timedelta
from django.db.models import Count, Q, Avg, Sum, QuerySet
from django.db.models.functions import TruncDate
from django.http import HttpRequest

from .models import Game, ScoutingReport, GameRoster
from apps.teams.models import Team
from .serializers import GameReadSerializer, GameWriteSerializer, GameListSerializer
from .roster_serializers import GameRosterSerializer
from .filters import GameFilter
from .services import GameAnalyticsService
from .pdf_export import AnalyticsPDFExporter
from .models import ScoutingReport
from .serializers import ScoutingReportSerializer
from django.db.models import Q  # Import Q
from apps.users.permissions import IsTeamScopedObject  # New import
from rest_framework.permissions import BasePermission
from .serializers import GameReadLightweightSerializer  # New import
from apps.possessions.models import Possession
from apps.events.models import CalendarEvent
from apps.core.cache_utils import cache_analytics_data, cache_dashboard_data, CacheManager


class IsGameRosterPermission(BasePermission):
    """
    Custom permission for game roster management.
    Allows coaches to create rosters for both teams in a game they're involved in.
    """
    message = "You do not have permission to manage rosters for this game."

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        
        # Only coaches can manage rosters
        if user.role != 'COACH':
            return False
            
        return True

    def has_object_permission(self, request, view, obj):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
            
        # For Game objects, check if user coaches either team in the game
        if isinstance(obj, Game):
            # Check if user coaches the home team or away team
            home_team_coached = obj.home_team.coaches.filter(id=user.id).exists()
            away_team_coached = obj.away_team.coaches.filter(id=user.id).exists()
            return home_team_coached or away_team_coached
            
        return False


class GamePagination(PageNumberPagination):
    page_size = 50  # Increased page size for better performance
    page_size_query_param = "page_size"
    max_page_size = 200


class GameViewSet(viewsets.ModelViewSet):
    queryset = Game.objects.all().order_by("-game_date")
    permission_classes = [permissions.IsAuthenticated, IsTeamScopedObject]
    filter_backends = [DjangoFilterBackend]
    filterset_class = GameFilter
    pagination_class = GamePagination

    def list(self, request, *args, **kwargs):
        """Rate limited list view - 100 requests per hour per IP"""
        return super().list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        """Rate limited retrieve view - 200 requests per hour per IP"""
        return super().retrieve(request, *args, **kwargs)

    def create(self, request, *args, **kwargs):
        """Rate limited create view - 10 requests per hour per user"""
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        """Rate limited update view - 20 requests per hour per user"""
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        """Rate limited delete view - 5 requests per hour per user"""
        return super().destroy(request, *args, **kwargs)

    def get_serializer_class(self) -> Type[Any]:
        """
        Use the appropriate serializer based on the action:
        - 'list': Use lightweight GameListSerializer for performance
        - 'create', 'update', 'partial_update': Use GameWriteSerializer
        - 'retrieve': Use GameReadLightweightSerializer by default, GameReadSerializer if include_possessions=true
        """
        if self.action == "list":
            return GameListSerializer
        elif self.action in ["create", "update", "partial_update"]:
            return GameWriteSerializer
        elif self.action == "retrieve":
            # Check if possessions should be included
            include_possessions = (
                self.request.query_params.get("include_possessions", "false").lower()
                == "true"
            )
            if include_possessions:
                return GameReadSerializer
            else:
                return GameReadLightweightSerializer
        return GameReadLightweightSerializer

    def get_queryset(self) -> QuerySet[Game]:
        """
        Filters games to only show those involving teams the user is a member of.
        Superusers can see all games.
        Optimizes queries based on the action.
        """
        user = self.request.user

        # Superusers see everything
        if user.is_superuser:
            base_queryset = self.queryset.select_related(
                "competition", "home_team", "away_team"
            )
        else:
            # Optimized single query: Filter games where the user is a member of either team
            base_queryset = (
                self.queryset.filter(
                    Q(home_team__players=user) | Q(home_team__coaches=user) |
                    Q(away_team__players=user) | Q(away_team__coaches=user)
                )
                .distinct()
                .select_related("competition", "home_team", "away_team")
            )

        # For list action, don't prefetch possessions - we'll use aggregate queries
        if self.action == "list":
            return base_queryset
        else:
            # For retrieve action, prefetch possessions for full details
            return base_queryset.prefetch_related("possessions")

    def create(self, request, *args, **kwargs):
        """
        Custom create action to ensure the response uses the ReadSerializer.
        """
        # Use the 'Write' serializer to validate the incoming data
        write_serializer = self.get_serializer(data=request.data)
        write_serializer.is_valid(raise_exception=True)

        # self.perform_create saves the object and returns the model instance
        instance = self.perform_create(write_serializer)

        # Now, create a 'Read' serializer using the new instance to generate the response
        read_serializer = GameReadSerializer(
            instance, context=self.get_serializer_context()
        )

        headers = self.get_success_headers(read_serializer.data)
        # Return the data from the 'Read' serializer, which contains the full nested objects
        return Response(
            read_serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )

    def perform_create(self, serializer):
        """
        This hook is called by 'create' and just saves the instance.
        """
        return serializer.save()

    @action(detail=True, methods=["get"], url_path="post-game-report")
    def post_game_report(self, request, pk=None):
        """
        Get comprehensive post-game analytics report for a specific game and team.
        """
        try:
            game_id = int(pk)
            team_id = request.query_params.get("team_id")

            if not team_id:
                return Response(
                    {"error": "team_id parameter is required"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            team_id = int(team_id)

            # Verify the team is involved in this game
            game = self.get_object()
            if game.home_team.id != team_id and game.away_team.id != team_id:
                return Response(
                    {"error": "Team is not involved in this game"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # Generate the post-game report
            report = GameAnalyticsService.get_post_game_report(game_id, team_id)

            if report is None:
                return Response(
                    {"error": "Game not found"}, status=status.HTTP_404_NOT_FOUND
                )

            return Response(report, status=status.HTTP_200_OK)

        except ValueError:
            return Response(
                {"error": "Invalid game_id or team_id"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        except Exception as e:
            return Response(
                {"error": f"Error generating report: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    @action(detail=True, methods=["get"])
    def possessions(self, request, pk=None):
        """
        Get paginated possessions for a specific game.
        This allows for faster initial game loading with on-demand possession loading.
        """
        try:
            game = self.get_object()
            page = int(request.query_params.get("page", 1))
            page_size = min(
                int(request.query_params.get("page_size", 20)), 50
            )  # Max 50 per page

            # Calculate offset
            offset = (page - 1) * page_size

            # Get possessions with pagination
            possessions = game.possessions.select_related("team", "opponent").order_by(
                "quarter", "start_time_in_game"
            )
            total_count = possessions.count()

            # Apply pagination
            paginated_possessions = possessions[offset : offset + page_size]

            # Serialize
            from apps.possessions.nested_serializers import PossessionInGameSerializer

            serializer = PossessionInGameSerializer(paginated_possessions, many=True)

            return Response(
                {
                    "count": total_count,
                    "next": (
                        f"/api/games/{pk}/possessions/?page={page + 1}&page_size={page_size}"
                        if offset + page_size < total_count
                        else None
                    ),
                    "previous": (
                        f"/api/games/{pk}/possessions/?page={page - 1}&page_size={page_size}"
                        if page > 1
                        else None
                    ),
                    "results": serializer.data,
                    "page": page,
                    "page_size": page_size,
                }
            )

        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=["get"])
    @cache_analytics_data(timeout=1800)  # Cache for 30 minutes
    def comprehensive_analytics(self, request):
        """
        Get comprehensive analytics with extensive filtering options.
        Supports filtering by team, quarters, time ranges, outcomes, etc.
        Cached for 30 minutes to improve performance
        """
        try:
            # Get filter parameters
            team_id = request.query_params.get("team_id")
            quarter_filter = request.query_params.get("quarter")
            last_games = request.query_params.get("last_games")
            outcome_filter = request.query_params.get("outcome")
            home_away_filter = request.query_params.get("home_away")
            opponent_filter = request.query_params.get("opponent")
            min_possessions = int(request.query_params.get("min_possessions", 10))

            # Convert team_id to int if provided
            if team_id:
                team_id = int(team_id)

            # Convert quarter_filter to int if provided
            if quarter_filter:
                quarter_filter = int(quarter_filter)

            # Convert last_games to int if provided
            if last_games:
                last_games = int(last_games)

            # Convert opponent_filter to int if provided
            if opponent_filter:
                opponent_filter = int(opponent_filter)

            # Get comprehensive analytics
            analytics_data = GameAnalyticsService.get_comprehensive_analytics(
                team_id=team_id,
                quarter_filter=quarter_filter,
                last_games=last_games,
                outcome_filter=outcome_filter,
                home_away_filter=home_away_filter,
                opponent_filter=opponent_filter,
                min_possessions=min_possessions,
            )

            return Response(analytics_data)

        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=["get"])
    def export_analytics_pdf(self, request):
        """
        Export comprehensive analytics to PDF format and save as scouting report.
        Supports the same filtering options as comprehensive_analytics.
        """
        try:
            # Get filter parameters (same as comprehensive_analytics)
            team_id = request.query_params.get("team_id")
            quarter_filter = request.query_params.get("quarter")
            last_games = request.query_params.get("last_games")
            outcome_filter = request.query_params.get("outcome")
            home_away_filter = request.query_params.get("home_away")
            min_possessions = int(request.query_params.get("min_possessions", 10))

            # Convert parameters to appropriate types
            if team_id:
                team_id = int(team_id)
            if quarter_filter:
                quarter_filter = int(quarter_filter)
            if last_games:
                last_games = int(last_games)

            # Get comprehensive analytics data
            analytics_data = GameAnalyticsService.get_comprehensive_analytics(
                team_id=team_id,
                quarter_filter=quarter_filter,
                last_games=last_games,
                outcome_filter=outcome_filter,
                home_away_filter=home_away_filter,
                min_possessions=min_possessions,
            )

            # Generate PDF
            pdf_exporter = AnalyticsPDFExporter()

            # Validate analytics data before generating PDF
            if not analytics_data or len(analytics_data) == 0:
                return Response(
                    {"error": "No analytics data available for the selected filters"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            try:
                pdf_content = pdf_exporter.export_analytics_to_pdf(
                    analytics_data, analytics_data.get("filters_applied", {})
                )

                # Validate PDF content
                if not pdf_content or len(pdf_content) == 0:
                    return Response(
                        {"error": "Failed to generate PDF content"},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    )

            except Exception as pdf_error:
                return Response(
                    {"error": f"PDF generation failed: {str(pdf_error)}"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

            # Create scouting report title
            title_parts = []
            if team_id:
                from apps.teams.models import Team

                team = Team.objects.get(id=team_id)
                title_parts.append(team.name)

            if last_games:
                title_parts.append(f"Last {last_games} Games")
            elif quarter_filter:
                title_parts.append(f"Q{quarter_filter}")
            else:
                title_parts.append("All Games")

            if outcome_filter:
                title_parts.append(f"{'Wins' if outcome_filter == 'W' else 'Losses'}")

            if home_away_filter:
                title_parts.append(f"{home_away_filter} Games")

            title = " - ".join(title_parts) + " Analytics Report"

            # Save PDF to file and create ScoutingReport record
            import os
            from django.core.files.base import ContentFile
            from datetime import datetime

            # Create filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"scouting_report_{timestamp}.pdf"

            # Create ScoutingReport instance
            scouting_report = ScoutingReport(
                title=title,
                description=f"Analytics report generated on {datetime.now().strftime('%Y-%m-%d %H:%M')}",
                file_size=len(pdf_content),
                team_id=team_id,
                quarter_filter=quarter_filter,
                last_games=last_games,
                outcome_filter=outcome_filter,
                home_away_filter=home_away_filter,
                min_possessions=min_possessions,
                created_by=request.user,
            )

            # Save the PDF file
            scouting_report.pdf_file.save(filename, ContentFile(pdf_content), save=True)

            # Return the scouting report data
            serializer = ScoutingReportSerializer(scouting_report)
            return Response(serializer.data)

        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=["get"])
    def scouting_reports(self, request):
        """
        List all scouting reports for the authenticated user.
        Automatically filters out corrupted reports (0 bytes).
        """
        try:
            # Get all reports for the user
            reports = ScoutingReport.objects.filter(created_by=request.user)

            # Filter out corrupted reports (0 bytes) and delete them
            corrupted_reports = []
            valid_reports = []

            for report in reports:
                # Only consider PDF reports with 0 file size as corrupted
                # YouTube links and generated reports don't have file_size
                if (
                    report.report_type == ScoutingReport.ReportType.UPLOADED_PDF
                    and report.file_size == 0
                ):
                    corrupted_reports.append(report)
                else:
                    valid_reports.append(report)

            # Delete corrupted reports
            if corrupted_reports:
                for report in corrupted_reports:
                    try:
                        # Delete the file from storage if it exists
                        if report.pdf_file and report.pdf_file.storage.exists(
                            report.pdf_file.name
                        ):
                            report.pdf_file.storage.delete(report.pdf_file.name)
                        # Delete the database record
                        report.delete()
                    except Exception as delete_error:
                        print(
                            f"Failed to delete corrupted report {report.id}: {delete_error}"
                        )

            # Serialize only valid reports
            serializer = ScoutingReportSerializer(valid_reports, many=True)
            return Response(serializer.data)
        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=["post"])
    def upload_scouting_report(self, request):
        """
        Upload a new scouting report (PDF or YouTube link).
        """
        try:
            from .serializers import ScoutingReportCreateSerializer

            serializer = ScoutingReportCreateSerializer(data=request.data)
            if serializer.is_valid():
                # Set the creator
                report = serializer.save(created_by=request.user)

                # Send notifications to tagged users
                self._send_scouting_notifications(report)

                # Return the created report
                response_serializer = ScoutingReportSerializer(report)
                return Response(
                    response_serializer.data, status=status.HTTP_201_CREATED
                )
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def _send_scouting_notifications(self, report):
        """
        Send email and app notifications to tagged users about new scouting report.
        """
        try:
            tagged_users = report.tagged_users.all()
            if not tagged_users:
                return

            # Log the notification
            print(
                f"New scouting report '{report.title}' uploaded by {report.created_by.username}"
            )
            print(f"Tagged users: {[user.username for user in tagged_users]}")

            # Send email notifications to users with email addresses
            self._send_email_notifications(report, tagged_users)

            # TODO: Implement app notifications (push notifications, in-app notifications, etc.)

        except Exception as e:
            print(f"Error sending scouting notifications: {e}")

    def _send_email_notifications(self, report, tagged_users):
        """
        Send email notifications to tagged users about new scouting report.
        """
        from django.core.mail import EmailMultiAlternatives
        from django.template.loader import render_to_string
        from django.conf import settings

        try:
            # Get the app URL (you might want to make this configurable)
            app_url = getattr(settings, "FRONTEND_URL", "http://localhost:8080")

            for user in tagged_users:
                # Only send email if user has an email address
                if user.email:
                    try:
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
                        print(
                            f"Email notification sent to {user.email} for report '{report.title}'"
                        )

                    except Exception as e:
                        print(f"Error sending email to {user.email}: {e}")
                else:
                    print(
                        f"User {user.username} has no email address, skipping email notification"
                    )

        except Exception as e:
            print(f"Error in email notification system: {e}")

    @action(detail=True, methods=["get"])
    def download_report(self, request, pk=None):
        """
        Download a specific scouting report PDF.
        """
        try:
            report = ScoutingReport.objects.get(id=pk, created_by=request.user)

            if not report.pdf_file:
                return Response(
                    {"error": "PDF file not found"}, status=status.HTTP_404_NOT_FOUND
                )

            # Check if file exists and has content
            if not report.pdf_file.storage.exists(report.pdf_file.name):
                return Response(
                    {"error": "PDF file does not exist on storage"},
                    status=status.HTTP_404_NOT_FOUND,
                )

            # Check file size
            if report.file_size == 0:
                return Response(
                    {"error": "PDF file is empty (0 bytes)"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # Read file content
            try:
                file_content = report.pdf_file.read()
                if not file_content or len(file_content) == 0:
                    return Response(
                        {"error": "PDF file content is empty"},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
            except Exception as read_error:
                return Response(
                    {"error": f"Failed to read PDF file: {str(read_error)}"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

            # Return the PDF file as response
            from django.http import HttpResponse

            response = HttpResponse(file_content, content_type="application/pdf")
            response["Content-Disposition"] = (
                f'attachment; filename="{report.title}.pdf"'
            )
            return response

        except ScoutingReport.DoesNotExist:
            return Response(
                {"error": "Report not found"}, status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=["patch"])
    def rename_report(self, request, pk=None):
        """
        Rename a scouting report.
        """
        try:
            report = ScoutingReport.objects.get(id=pk, created_by=request.user)

            new_title = request.data.get("title")
            if not new_title or not new_title.strip():
                return Response(
                    {"error": "Title is required"}, status=status.HTTP_400_BAD_REQUEST
                )

            report.title = new_title.strip()
            report.save()

            serializer = ScoutingReportSerializer(report)
            return Response(serializer.data)

        except ScoutingReport.DoesNotExist:
            return Response(
                {"error": "Report not found"}, status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=["post"])
    def cleanup_corrupted_reports(self, request):
        """
        Manually cleanup corrupted reports (0 bytes) for the authenticated user.
        """
        try:
            # Find all corrupted reports for the user
            corrupted_reports = ScoutingReport.objects.filter(
                created_by=request.user, file_size=0
            )

            deleted_count = 0
            for report in corrupted_reports:
                try:
                    # Delete the file from storage if it exists
                    if report.pdf_file and report.pdf_file.storage.exists(
                        report.pdf_file.name
                    ):
                        report.pdf_file.storage.delete(report.pdf_file.name)
                    # Delete the database record
                    report.delete()
                    deleted_count += 1
                except Exception as delete_error:
                    print(
                        f"Failed to delete corrupted report {report.id}: {delete_error}"
                    )

            return Response(
                {
                    "message": f"Successfully deleted {deleted_count} corrupted reports",
                    "deleted_count": deleted_count,
                }
            )

        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=["get"])
    def dashboard_data(self, request):
        """
        Get dashboard data including quick stats, recent activity, and upcoming games
        Cached for 1 minute to improve performance while maintaining real-time updates
        """
        # Check if force refresh is requested
        force_refresh = request.query_params.get('force_refresh')
        
        if force_refresh:
            # Bypass cache and get fresh data
            return self._get_dashboard_data(request)
        else:
            # Use cached data
            return self._get_dashboard_data_cached(request)
    
    @cache_dashboard_data(timeout=60)  # Cache for 1 minute for more real-time updates
    def _get_dashboard_data_cached(self, request):
        """Cached version of dashboard data"""
        return self._get_dashboard_data(request)
    
    def _get_dashboard_data(self, request):
        """Get fresh dashboard data without cache"""
        try:
            user = request.user
            today = timezone.now().date()

            # Get user's teams
            user_teams = []
            # Get teams where user is a player or coach
            player_teams = user.player_on_teams.all()
            coach_teams = user.coach_on_teams.all()
            user_teams = list(player_teams) + list(coach_teams)

            # Quick Stats
            quick_stats = {}
            team_ids = [team.id for team in user_teams]

            if user_teams:
                # Total games
                total_games = Game.objects.filter(
                    Q(home_team_id__in=team_ids) | Q(away_team_id__in=team_ids)
                ).count()

                # Total possessions - need to filter by GameRoster that contains these teams
                total_possessions = Possession.objects.filter(
                    Q(team__team_id__in=team_ids) | Q(opponent__team_id__in=team_ids)
                ).count()

                # Recent possessions (last 7 days)
                recent_possessions = Possession.objects.filter(
                    Q(team__team_id__in=team_ids) | Q(opponent__team_id__in=team_ids),
                    game__game_date__gte=today - timedelta(days=7),
                ).count()

                # Average possessions per game
                if total_games > 0:
                    avg_possessions_per_game = total_possessions / total_games
                else:
                    avg_possessions_per_game = 0

                quick_stats = {
                    "total_games": total_games,
                    "total_possessions": total_possessions,
                    "recent_possessions": recent_possessions,
                    "avg_possessions_per_game": round(avg_possessions_per_game, 1),
                }
            else:
                # If user has no teams, show zeros
                quick_stats = {
                    "total_games": 0,
                    "total_possessions": 0,
                    "recent_possessions": 0,
                    "avg_possessions_per_game": 0.0,
                }

            # Upcoming Games (next 7 days)
            upcoming_games = []
            if user_teams and team_ids:
                upcoming_games = (
                    Game.objects.filter(
                        Q(home_team_id__in=team_ids) | Q(away_team_id__in=team_ids),
                        game_date__gte=today,
                        game_date__lte=today + timedelta(days=7),
                    )
                    .select_related("home_team", "away_team", "competition")
                    .order_by("game_date")[:5]
                )

                upcoming_games = [
                    {
                        "id": game.id,
                        "home_team": game.home_team.name,
                        "away_team": game.away_team.name,
                        "competition": game.competition.name,
                        "game_date": game.game_date,
                        "home_team_score": game.home_team_score,
                        "away_team_score": game.away_team_score,
                        "quarter": game.quarter,
                    }
                    for game in upcoming_games
                ]

            # Recent Games (last 5 games)
            recent_games = []
            if user_teams and team_ids:
                recent_games = (
                    Game.objects.filter(
                        Q(home_team_id__in=team_ids) | Q(away_team_id__in=team_ids),
                        game_date__lt=today,
                    )
                    .select_related("home_team", "away_team", "competition")
                    .order_by("-game_date")[:5]
                )

                recent_games = [
                    {
                        "id": game.id,
                        "home_team": game.home_team.name,
                        "away_team": game.away_team.name,
                        "competition": game.competition.name,
                        "game_date": game.game_date,
                        "home_team_score": game.home_team_score,
                        "away_team_score": game.away_team_score,
                        "quarter": game.quarter,
                    }
                    for game in recent_games
                ]

            # Recent Scouting Reports
            recent_reports = []
            if user_teams and team_ids:
                recent_reports = (
                    ScoutingReport.objects.filter(team_id__in=team_ids)
                    .select_related("team", "created_by")
                    .order_by("-created_at")[:3]
                )

                recent_reports = [
                    {
                        "id": report.id,
                        "title": report.title,
                        "team": report.team.name,
                        "created_by": report.created_by.username,
                        "created_at": report.created_at,
                        "file_size_mb": report.get_file_size_mb(),
                    }
                    for report in recent_reports
                ]

            # Quick Actions (based on user role)
            quick_actions = []
            if user.role == "ADMIN":
                quick_actions = [
                    {
                        "title": "Add Game",
                        "icon": "sports_basketball",
                        "route": "/games/add",
                    },
                    {
                        "title": "Create Competition",
                        "icon": "emoji_events",
                        "route": "/competitions/add",
                    },
                    {"title": "Manage Teams", "icon": "group_work", "route": "/teams"},
                    {"title": "User Management", "icon": "people", "route": "/users"},
                ]
            elif user.role == "COACH":
                quick_actions = [
                    {
                        "title": "Add Game",
                        "icon": "sports_basketball",
                        "route": "/games/add",
                    },
                    {"title": "Team Management", "icon": "group", "route": "/teams"},
                    {
                        "title": "Playbook Editor",
                        "icon": "menu_book",
                        "route": "/playbook",
                    },
                    {
                        "title": "Schedule Event",
                        "icon": "event",
                        "route": "/events/add",
                    },
                ]
            else:  # PLAYER
                quick_actions = [
                    {
                        "title": "View Games",
                        "icon": "sports_basketball",
                        "route": "/games",
                    },
                    {"title": "My Teams", "icon": "group", "route": "/teams"},
                    {
                        "title": "Scouting Reports",
                        "icon": "assessment",
                        "route": "/scouting-reports",
                    },
                    {"title": "Calendar", "icon": "event", "route": "/calendar"},
                ]

            # Upcoming Events (today only)
            upcoming_events = []
            if user_teams and team_ids:
                # Get events for today for the user's teams
                today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
                today_end = today_start + timedelta(days=1)
                
                upcoming_events = (
                    CalendarEvent.objects.filter(
                        team_id__in=team_ids,
                        start_time__gte=today_start,
                        start_time__lt=today_end,
                    )
                    .select_related("team")
                    .order_by("start_time")
                )

                upcoming_events = [
                    {
                        "id": event.id,
                        "title": event.title,
                        "event_type": event.event_type,
                        "start_time": event.start_time,
                        "end_time": event.end_time,
                        "description": event.description,
                    }
                    for event in upcoming_events
                ]

            return Response(
                {
                    "quick_stats": quick_stats,
                    "upcoming_games": upcoming_games,
                    "recent_games": recent_games,
                    "recent_reports": recent_reports,
                    "quick_actions": quick_actions,
                    "upcoming_events": upcoming_events,
                }
            )

        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    # Roster Management Endpoints
    @action(detail=True, methods=["post"], url_path="roster", permission_classes=[IsGameRosterPermission])
    def create_roster(self, request, pk=None):
        """
        Create or update a game roster for a team.
        """
        try:
            game = self.get_object()
            team_id = request.data.get('team_id')
            player_ids = request.data.get('player_ids', [])
            
            if not team_id:
                return Response(
                    {"error": "team_id is required"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if len(player_ids) < 10 or len(player_ids) > 12:
                return Response(
                    {"error": "Roster must have between 10 and 12 players"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if team is part of this game
            if game.home_team.id != team_id and game.away_team.id != team_id:
                return Response(
                    {"error": "Team is not part of this game"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            team = Team.objects.get(id=team_id)
            
            # Get or create roster
            roster, created = GameRoster.objects.get_or_create(
                game=game,
                team=team,
                defaults={}
            )
            
            # Set players
            from apps.users.models import User
            players = User.objects.filter(id__in=player_ids, role='PLAYER')
            roster.players.set(players)
            
            serializer = GameRosterSerializer(roster)
            return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
            
        except Team.DoesNotExist:
            return Response(
                {"error": "Team not found"}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {"error": str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=["patch"], url_path="roster/starting-five", permission_classes=[IsGameRosterPermission])
    def update_starting_five(self, request, pk=None):
        """
        Update the starting five for a team's roster.
        """
        try:
            game = self.get_object()
            team_id = request.data.get('team_id')
            starting_five_ids = request.data.get('starting_five_ids', [])
            
            if not team_id:
                return Response(
                    {"error": "team_id is required"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if len(starting_five_ids) != 5:
                return Response(
                    {"error": "Starting five must have exactly 5 players"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if team is part of this game
            if game.home_team.id != team_id and game.away_team.id != team_id:
                return Response(
                    {"error": "Team is not part of this game"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            team = Team.objects.get(id=team_id)
            
            try:
                roster = GameRoster.objects.get(game=game, team=team)
            except GameRoster.DoesNotExist:
                return Response(
                    {"error": "Roster not found. Create roster first."}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Validate that starting five players are in the roster
            roster_player_ids = set(roster.players.values_list('id', flat=True))
            if not set(starting_five_ids).issubset(roster_player_ids):
                return Response(
                    {"error": "Starting five players must be in the roster"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Set starting five
            from apps.users.models import User
            starting_five = User.objects.filter(id__in=starting_five_ids)
            roster.starting_five.set(starting_five)
            
            serializer = GameRosterSerializer(roster)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Team.DoesNotExist:
            return Response(
                {"error": "Team not found"}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {"error": str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=["get"], url_path="roster", permission_classes=[IsGameRosterPermission])
    def get_roster(self, request, pk=None):
        """
        Get roster information for a game.
        """
        try:
            game = self.get_object()
            team_id = request.query_params.get('team_id')
            
            if team_id:
                # Get specific team roster
                try:
                    team = Team.objects.get(id=team_id)
                    roster = GameRoster.objects.get(game=game, team=team)
                    serializer = GameRosterSerializer(roster)
                    return Response(serializer.data)
                except (Team.DoesNotExist, GameRoster.DoesNotExist):
                    return Response(
                        {"error": "Roster not found"}, 
                        status=status.HTTP_404_NOT_FOUND
                    )
            else:
                # Get all rosters for the game
                rosters = GameRoster.objects.filter(game=game)
                serializer = GameRosterSerializer(rosters, many=True)
                return Response(serializer.data)
                
        except Exception as e:
            return Response(
                {"error": str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=["delete"], url_path="roster", permission_classes=[IsGameRosterPermission])
    def delete_roster(self, request, pk=None):
        """
        Delete a roster for a team.
        """
        try:
            game = self.get_object()
            team_id = request.data.get('team_id')
            
            if not team_id:
                return Response(
                    {"error": "team_id is required"}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            team = Team.objects.get(id=team_id)
            roster = GameRoster.objects.get(game=game, team=team)
            roster.delete()
            
            return Response(status=status.HTTP_204_NO_CONTENT)
            
        except (Team.DoesNotExist, GameRoster.DoesNotExist):
            return Response(
                {"error": "Roster not found"}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {"error": str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=["delete"])
    def delete_report(self, request, pk=None):
        """
        Delete a scouting report.
        Only the creator or admin can delete the report.
        """
        try:
            report = ScoutingReport.objects.get(id=pk)

            # Check permissions - only creator or admin can delete
            if report.created_by != request.user and not request.user.is_staff:
                return Response(
                    {"error": "You don't have permission to delete this report."},
                    status=status.HTTP_403_FORBIDDEN,
                )

            # Store report info for logging
            report_title = report.title
            report_type = report.report_type

            # Delete the report (this will also delete the associated file)
            report.delete()

            print(
                f"Scouting report '{report_title}' ({report_type}) deleted by {request.user.username}"
            )

            return Response(
                {"message": f"Scouting report '{report_title}' deleted successfully."},
                status=status.HTTP_200_OK,
            )

        except ScoutingReport.DoesNotExist:
            return Response(
                {"error": "Scouting report not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    @action(detail=True, methods=["get"], url_path="player-stats")
    def get_game_player_stats(self, request, pk=None):
        """Get player statistics for a specific game"""
        try:
            game = self.get_object()
            
            # Get all possessions for this game
            from apps.possessions.models import Possession
            from django.db.models import Count, Sum, Case, When, Value, IntegerField
            
            possessions = Possession.objects.filter(game=game).select_related('scorer', 'team__team')
            
            # Get player stats for each team
            home_team_stats = {}
            away_team_stats = {}
            
            # Process home team possessions
            home_possessions = possessions.filter(team__team=game.home_team)
            for possession in home_possessions:
                if possession.scorer:
                    player_id = possession.scorer.id
                    if player_id not in home_team_stats:
                        home_team_stats[player_id] = {
                            'player': {
                                'id': possession.scorer.id,
                                'first_name': possession.scorer.first_name,
                                'last_name': possession.scorer.last_name,
                                'jersey_number': possession.scorer.jersey_number,
                            },
                            'stats': {
                                'total_points': 0,
                                'field_goals_made': 0,
                                'field_goals_attempted': 0,
                                'three_pointers_made': 0,
                                'three_pointers_attempted': 0,
                                'free_throws_made': 0,
                                'free_throws_attempted': 0,
                            }
                        }
                    
                    # Update stats based on outcome
                    stats = home_team_stats[player_id]['stats']
                    if possession.outcome == 'MADE_2PTS':
                        stats['total_points'] += 2
                        stats['field_goals_made'] += 1
                        stats['field_goals_attempted'] += 1
                    elif possession.outcome == 'MISSED_2PTS':
                        stats['field_goals_attempted'] += 1
                    elif possession.outcome == 'MADE_3PTS':
                        stats['total_points'] += 3
                        stats['field_goals_made'] += 1
                        stats['field_goals_attempted'] += 1
                        stats['three_pointers_made'] += 1
                        stats['three_pointers_attempted'] += 1
                    elif possession.outcome == 'MISSED_3PTS':
                        stats['field_goals_attempted'] += 1
                        stats['three_pointers_attempted'] += 1
                    elif possession.outcome == 'MADE_FTS':
                        stats['total_points'] += 1
                        stats['free_throws_made'] += 1
                        stats['free_throws_attempted'] += 1
                    elif possession.outcome == 'MISSED_FTS':
                        stats['free_throws_attempted'] += 1
            
            # Process away team possessions
            away_possessions = possessions.filter(team__team=game.away_team)
            for possession in away_possessions:
                if possession.scorer:
                    player_id = possession.scorer.id
                    if player_id not in away_team_stats:
                        away_team_stats[player_id] = {
                            'player': {
                                'id': possession.scorer.id,
                                'first_name': possession.scorer.first_name,
                                'last_name': possession.scorer.last_name,
                                'jersey_number': possession.scorer.jersey_number,
                            },
                            'stats': {
                                'total_points': 0,
                                'field_goals_made': 0,
                                'field_goals_attempted': 0,
                                'three_pointers_made': 0,
                                'three_pointers_attempted': 0,
                                'free_throws_made': 0,
                                'free_throws_attempted': 0,
                            }
                        }
                    
                    # Update stats based on outcome
                    stats = away_team_stats[player_id]['stats']
                    if possession.outcome == 'MADE_2PTS':
                        stats['total_points'] += 2
                        stats['field_goals_made'] += 1
                        stats['field_goals_attempted'] += 1
                    elif possession.outcome == 'MISSED_2PTS':
                        stats['field_goals_attempted'] += 1
                    elif possession.outcome == 'MADE_3PTS':
                        stats['total_points'] += 3
                        stats['field_goals_made'] += 1
                        stats['field_goals_attempted'] += 1
                        stats['three_pointers_made'] += 1
                        stats['three_pointers_attempted'] += 1
                    elif possession.outcome == 'MISSED_3PTS':
                        stats['field_goals_attempted'] += 1
                        stats['three_pointers_attempted'] += 1
                    elif possession.outcome == 'MADE_FTS':
                        stats['total_points'] += 1
                        stats['free_throws_made'] += 1
                        stats['free_throws_attempted'] += 1
                    elif possession.outcome == 'MISSED_FTS':
                        stats['free_throws_attempted'] += 1
            
            # Calculate shooting percentages
            for player_data in home_team_stats.values():
                stats = player_data['stats']
                if stats['field_goals_attempted'] > 0:
                    stats['field_goal_percentage'] = round((stats['field_goals_made'] / stats['field_goals_attempted']) * 100, 1)
                else:
                    stats['field_goal_percentage'] = 0.0
                
                if stats['three_pointers_attempted'] > 0:
                    stats['three_point_percentage'] = round((stats['three_pointers_made'] / stats['three_pointers_attempted']) * 100, 1)
                else:
                    stats['three_point_percentage'] = 0.0
                
                if stats['free_throws_attempted'] > 0:
                    stats['free_throw_percentage'] = round((stats['free_throws_made'] / stats['free_throws_attempted']) * 100, 1)
                else:
                    stats['free_throw_percentage'] = 0.0
            
            for player_data in away_team_stats.values():
                stats = player_data['stats']
                if stats['field_goals_attempted'] > 0:
                    stats['field_goal_percentage'] = round((stats['field_goals_made'] / stats['field_goals_attempted']) * 100, 1)
                else:
                    stats['field_goal_percentage'] = 0.0
                
                if stats['three_pointers_attempted'] > 0:
                    stats['three_point_percentage'] = round((stats['three_pointers_made'] / stats['three_pointers_attempted']) * 100, 1)
                else:
                    stats['three_point_percentage'] = 0.0
                
                if stats['free_throws_attempted'] > 0:
                    stats['free_throw_percentage'] = round((stats['free_throws_made'] / stats['free_throws_attempted']) * 100, 1)
                else:
                    stats['free_throw_percentage'] = 0.0
            
            return Response({
                'game': {
                    'id': game.id,
                    'home_team': game.home_team.name,
                    'away_team': game.away_team.name,
                    'home_team_score': game.home_team_score,
                    'away_team_score': game.away_team_score,
                },
                'home_team_player_stats': list(home_team_stats.values()),
                'away_team_player_stats': list(away_team_stats.values()),
            })
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    @action(detail=False, methods=["post"], url_path="invalidate-cache")
    def invalidate_cache(self, request):
        """
        Manually invalidate dashboard cache for immediate updates
        """
        try:
            # Invalidate dashboard cache
            CacheManager.invalidate_dashboard_cache()
            
            return Response({
                "message": "Dashboard cache invalidated successfully",
                "timestamp": timezone.now().isoformat(),
            })
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    @action(detail=False, methods=["get"], url_path="calendar-data")
    def get_calendar_data(self, request):
        """
        Get all games for calendar display (no team scoping restrictions)
        This endpoint allows authenticated users to see all games for calendar purposes
        """
        try:
            user = request.user
            if not user.is_authenticated:
                return Response(
                    {"error": "Authentication required"},
                    status=status.HTTP_401_UNAUTHORIZED,
                )

            # Get all games without team scoping for calendar display
            games = Game.objects.all().select_related(
                "home_team", "away_team", "competition"
            ).order_by("game_date")

            # Serialize games for calendar
            games_data = []
            for game in games:
                games_data.append({
                    "id": game.id,
                    "home_team": {
                        "id": game.home_team.id,
                        "name": game.home_team.name,
                    },
                    "away_team": {
                        "id": game.away_team.id,
                        "name": game.away_team.name,
                    },
                    "competition": {
                        "id": game.competition.id,
                        "name": game.competition.name,
                    },
                    "game_date": game.game_date,
                    "home_team_score": game.home_team_score,
                    "away_team_score": game.away_team_score,
                    "quarter": game.quarter,
                    "created_by": game.created_by.id if game.created_by else None,
                    "created_at": game.created_at,
                    "updated_at": game.updated_at,
                })

            return Response({
                "games": games_data,
                "count": len(games_data),
            })
            
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

