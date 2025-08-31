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
from django.db.models import Q  # Import Q
from apps.users.permissions import IsTeamScopedObject  # New import


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
        - 'retrieve': Use GameReadSerializer for full details
        """
        if self.action == "list":
            return GameListSerializer
        elif self.action in ["create", "update", "partial_update"]:
            return GameWriteSerializer
        return GameReadSerializer

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
