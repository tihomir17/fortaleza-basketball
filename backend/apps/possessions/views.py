# backend/apps/possessions/views.py

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q

from .models import Possession
from .serializers import PossessionSerializer
from .filters import PossessionFilter
from .services import StatsService, PlayerStatsService
from apps.users.permissions import IsTeamScopedObject


class PossessionViewSet(viewsets.ModelViewSet):
    queryset = Possession.objects.all()
    serializer_class = PossessionSerializer
    permission_classes = [IsAuthenticated, IsTeamScopedObject]
    filter_backends = [DjangoFilterBackend]
    filterset_class = PossessionFilter

    def get_queryset(self):
        user = self.request.user
        queryset = Possession.objects.select_related(
            "game", "team", "opponent", "created_by"
        ).prefetch_related("players_on_court", "offensive_rebound_players")

        # Filter by team membership
        if hasattr(user, "teams"):
            user_teams = user.teams.all()
            queryset = queryset.filter(
                Q(team__in=user_teams) | Q(opponent__in=user_teams)
            )

        return queryset

    @action(detail=False, methods=["get"])
    def quarter_stats(self, request):
        """Get stats broken down by quarter"""
        team_id = request.query_params.get("team_id")
        offensive = request.query_params.get("offensive", "true").lower() == "true"

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_quarter_stats(offensive=offensive)

        return Response(stats)

    @action(detail=False, methods=["get"])
    def offensive_set_stats(self, request):
        """Get stats by offensive sets"""
        team_id = request.query_params.get("team_id")

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_offensive_set_stats()

        return Response(stats)

    @action(detail=False, methods=["get"])
    def defensive_set_stats(self, request):
        """Get stats by defensive sets"""
        team_id = request.query_params.get("team_id")

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_defensive_set_stats()

        return Response(stats)

    @action(detail=False, methods=["get"])
    def pnr_stats(self, request):
        """Get pick and roll statistics"""
        team_id = request.query_params.get("team_id")
        offensive = request.query_params.get("offensive", "true").lower() == "true"

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_pnr_stats(offensive=offensive)

        return Response(stats)

    @action(detail=False, methods=["get"])
    def sequence_stats(self, request):
        """Get sequence action statistics (paint touch, kick out, extra pass)"""
        team_id = request.query_params.get("team_id")

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_sequence_stats()

        return Response(stats)

    @action(detail=False, methods=["get"])
    def offensive_rebound_stats(self, request):
        """Get offensive rebound statistics"""
        team_id = request.query_params.get("team_id")

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_offensive_rebound_stats()

        return Response(stats)

    @action(detail=False, methods=["get"])
    def box_out_stats(self, request):
        """Get box out and defensive rebound statistics"""
        team_id = request.query_params.get("team_id")

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_box_out_stats()

        return Response(stats)

    @action(detail=False, methods=["get"])
    def shooting_stats(self, request):
        """Get shooting quality and timing statistics"""
        team_id = request.query_params.get("team_id")

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_shooting_stats()

        return Response(stats)

    @action(detail=False, methods=["get"])
    def timeout_stats(self, request):
        """Get after timeout statistics"""
        team_id = request.query_params.get("team_id")

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_timeout_stats()

        return Response(stats)

    @action(detail=False, methods=["get"])
    def lineup_stats(self, request):
        """Get lineup statistics with minimum possession threshold"""
        team_id = request.query_params.get("team_id")
        min_possessions = int(request.query_params.get("min_possessions", 10))

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_lineup_stats(min_possessions=min_possessions)

        return Response(stats)

    @action(detail=False, methods=["get"])
    def game_range_stats(self, request):
        """Get stats for specific number of recent games"""
        team_id = request.query_params.get("team_id")
        game_count = int(request.query_params.get("game_count", 5))

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_game_range_stats(game_count)

        return Response(stats)

    @action(detail=False, methods=["get"])
    def comprehensive_report(self, request):
        """Get comprehensive stats report"""
        team_id = request.query_params.get("team_id")
        game_range = request.query_params.get("game_range")

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)

        if game_range:
            stats = stats_service.get_comprehensive_report(game_range=int(game_range))
        else:
            stats = stats_service.get_comprehensive_report()

        return Response(stats)

    @action(detail=False, methods=["get"])
    def player_stats(self, request):
        """Get player-specific statistics"""
        team_id = request.query_params.get("team_id")
        player_id = request.query_params.get("player_id")

        if not team_id or not player_id:
            return Response(
                {"error": "team_id and player_id parameters are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
            player = team.players.get(id=player_id)
        except:
            return Response(
                {"error": "Team or player not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        player_stats_service = PlayerStatsService(player, team)

        offensive_stats = player_stats_service.get_player_offensive_stats()
        defensive_stats = player_stats_service.get_player_defensive_stats()

        return Response(
            {
                "player": {
                    "id": player.id,
                    "username": player.username,
                    "first_name": player.first_name,
                    "last_name": player.last_name,
                    "role": player.role,
                },
                "offensive_stats": offensive_stats,
                "defensive_stats": defensive_stats,
            }
        )

    @action(detail=False, methods=["get"])
    def outcome_stats(self, request):
        """Get statistics by outcomes"""
        team_id = request.query_params.get("team_id")
        offensive = request.query_params.get("offensive", "true").lower() == "true"

        if not team_id:
            return Response(
                {"error": "team_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            team = request.user.teams.get(id=team_id)
        except:
            return Response(
                {"error": "Team not found or access denied"},
                status=status.HTTP_404_NOT_FOUND,
            )

        stats_service = StatsService(team)
        stats = stats_service.get_outcome_stats(offensive=offensive)

        return Response(stats)
