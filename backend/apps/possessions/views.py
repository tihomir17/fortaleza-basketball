# backend/apps/possessions/views.py

from django.db.models import Q
from rest_framework import viewsets, permissions
from .models import Possession
from apps.teams.models import Team
from .serializers import PossessionSerializer

class PossessionViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    queryset = Possession.objects.all().order_by('-id')
    serializer_class = PossessionSerializer

    def get_queryset(self):
        """
        This ensures a user can only see possessions from games in which
        one of their teams participated.
        """
        user = self.request.user
        base_queryset = super().get_queryset()

        if user.is_superuser:
            return base_queryset

        # Get all teams the user is a member of (as a player or coach)
        member_of_teams = Team.objects.filter(
            Q(players=user) | Q(coaches=user)
        ).distinct()
        
        # Filter the base queryset to include only possessions that belong to
        # games where one of the user's teams was either the home or away team.
        return base_queryset.filter(
            Q(game__home_team__in=member_of_teams) |
            Q(game__away_team__in=member_of_teams)
        ).distinct()

    def perform_create(self, serializer):
        """
        Hook to automatically set the 'logged_by' field to the current user on creation.
        """
        serializer.save(logged_by=self.request.user)