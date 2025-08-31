from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.decorators import action
from django_filters.rest_framework import DjangoFilterBackend
from .models import Game
from apps.teams.models import Team
from .serializers import GameReadSerializer, GameWriteSerializer, GameListSerializer
from .filters import GameFilter
from .services import GameAnalyticsService
from .pdf_export import AnalyticsPDFExporter
from .models import ScoutingReport
from .serializers import ScoutingReportSerializer
from django.db.models import Q  # Import Q
from apps.users.permissions import IsTeamScopedObject  # New import
from .serializers import GameReadLightweightSerializer # New import


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

    def get_serializer_class(self):
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
            include_possessions = self.request.query_params.get('include_possessions', 'false').lower() == 'true'
            if include_possessions:
                return GameReadSerializer
            else:
                return GameReadLightweightSerializer
        return GameReadLightweightSerializer

    def get_queryset(self):
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
            # Get all teams the user is a member of
            member_of_teams = Team.objects.filter(
                Q(players=user) | Q(coaches=user)
            ).distinct()

            # Filter games where one of the user's teams was either home or away
            base_queryset = (
                self.queryset.filter(
                    Q(home_team__in=member_of_teams) | Q(away_team__in=member_of_teams)
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

    @action(detail=True, methods=['get'], url_path='post-game-report')
    def post_game_report(self, request, pk=None):
        """
        Get comprehensive post-game analytics report for a specific game and team.
        """
        try:
            game_id = int(pk)
            team_id = request.query_params.get('team_id')
            
            if not team_id:
                return Response(
                    {'error': 'team_id parameter is required'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            team_id = int(team_id)
            
            # Verify the team is involved in this game
            game = self.get_object()
            if game.home_team.id != team_id and game.away_team.id != team_id:
                return Response(
                    {'error': 'Team is not involved in this game'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Generate the post-game report
            report = GameAnalyticsService.get_post_game_report(game_id, team_id)
            
            if report is None:
                return Response(
                    {'error': 'Game not found'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            return Response(report, status=status.HTTP_200_OK)
            
        except ValueError:
            return Response(
                {'error': 'Invalid game_id or team_id'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            return Response(
                {'error': f'Error generating report: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=["get"])
    def possessions(self, request, pk=None):
        """
        Get paginated possessions for a specific game.
        This allows for faster initial game loading with on-demand possession loading.
        """
        try:
            game = self.get_object()
            page = int(request.query_params.get('page', 1))
            page_size = min(int(request.query_params.get('page_size', 20)), 50)  # Max 50 per page
            
            # Calculate offset
            offset = (page - 1) * page_size
            
            # Get possessions with pagination
            possessions = game.possessions.select_related('team', 'opponent').order_by('quarter', 'start_time_in_game')
            total_count = possessions.count()
            
            # Apply pagination
            paginated_possessions = possessions[offset:offset + page_size]
            
            # Serialize
            from apps.possessions.nested_serializers import PossessionInGameSerializer
            serializer = PossessionInGameSerializer(paginated_possessions, many=True)
            
            return Response({
                'count': total_count,
                'next': f'/api/games/{pk}/possessions/?page={page + 1}&page_size={page_size}' if offset + page_size < total_count else None,
                'previous': f'/api/games/{pk}/possessions/?page={page - 1}&page_size={page_size}' if page > 1 else None,
                'results': serializer.data,
                'page': page,
                'page_size': page_size,
            })
            
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=["get"])
    def comprehensive_analytics(self, request):
        """
        Get comprehensive analytics with extensive filtering options.
        Supports filtering by team, quarters, time ranges, outcomes, etc.
        """
        try:
            # Get filter parameters
            team_id = request.query_params.get('team_id')
            quarter_filter = request.query_params.get('quarter')
            last_games = request.query_params.get('last_games')
            outcome_filter = request.query_params.get('outcome')
            home_away_filter = request.query_params.get('home_away')
            min_possessions = int(request.query_params.get('min_possessions', 10))
            
            # Convert team_id to int if provided
            if team_id:
                team_id = int(team_id)
            
            # Convert quarter_filter to int if provided
            if quarter_filter:
                quarter_filter = int(quarter_filter)
            
            # Convert last_games to int if provided
            if last_games:
                last_games = int(last_games)
            
            # Get comprehensive analytics
            analytics_data = GameAnalyticsService.get_comprehensive_analytics(
                team_id=team_id,
                quarter_filter=quarter_filter,
                last_games=last_games,
                outcome_filter=outcome_filter,
                home_away_filter=home_away_filter,
                min_possessions=min_possessions
            )
            
            return Response(analytics_data)
            
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=["get"])
    def export_analytics_pdf(self, request):
        """
        Export comprehensive analytics to PDF format and save as scouting report.
        Supports the same filtering options as comprehensive_analytics.
        """
        try:
            # Get filter parameters (same as comprehensive_analytics)
            team_id = request.query_params.get('team_id')
            quarter_filter = request.query_params.get('quarter')
            last_games = request.query_params.get('last_games')
            outcome_filter = request.query_params.get('outcome')
            home_away_filter = request.query_params.get('home_away')
            min_possessions = int(request.query_params.get('min_possessions', 10))
            
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
                min_possessions=min_possessions
            )
            
            # Generate PDF
            pdf_exporter = AnalyticsPDFExporter()
            
            # Validate analytics data before generating PDF
            if not analytics_data or len(analytics_data) == 0:
                return Response(
                    {'error': 'No analytics data available for the selected filters'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                pdf_content = pdf_exporter.export_analytics_to_pdf(
                    analytics_data, 
                    analytics_data.get('filters_applied', {})
                )
                
                # Validate PDF content
                if not pdf_content or len(pdf_content) == 0:
                    return Response(
                        {'error': 'Failed to generate PDF content'},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )
                    
            except Exception as pdf_error:
                return Response(
                    {'error': f'PDF generation failed: {str(pdf_error)}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
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
                created_by=request.user
            )
            
            # Save the PDF file
            scouting_report.pdf_file.save(filename, ContentFile(pdf_content), save=True)
            
            # Return the scouting report data
            serializer = ScoutingReportSerializer(scouting_report)
            return Response(serializer.data)
            
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=["get"])
    def scouting_reports(self, request):
        """
        List all scouting reports for the authenticated user.
        """
        try:
            reports = ScoutingReport.objects.filter(created_by=request.user)
            serializer = ScoutingReportSerializer(reports, many=True)
            return Response(serializer.data)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=["get"])
    def download_report(self, request, pk=None):
        """
        Download a specific scouting report PDF.
        """
        try:
            report = ScoutingReport.objects.get(id=pk, created_by=request.user)
            
            if not report.pdf_file:
                return Response(
                    {'error': 'PDF file not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Check if file exists and has content
            if not report.pdf_file.storage.exists(report.pdf_file.name):
                return Response(
                    {'error': 'PDF file does not exist on storage'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Check file size
            if report.file_size == 0:
                return Response(
                    {'error': 'PDF file is empty (0 bytes)'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Read file content
            try:
                file_content = report.pdf_file.read()
                if not file_content or len(file_content) == 0:
                    return Response(
                        {'error': 'PDF file content is empty'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            except Exception as read_error:
                return Response(
                    {'error': f'Failed to read PDF file: {str(read_error)}'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
            
            # Return the PDF file as response
            from django.http import HttpResponse
            response = HttpResponse(file_content, content_type='application/pdf')
            response['Content-Disposition'] = f'attachment; filename="{report.title}.pdf"'
            return response
            
        except ScoutingReport.DoesNotExist:
            return Response(
                {'error': 'Report not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
