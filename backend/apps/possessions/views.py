# backend/apps/possessions/views.py

from django.db.models import Q
from rest_framework import viewsets, permissions
from .models import Possession
from apps.teams.models import Team
from .serializers import PossessionSerializer

class PossessionViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and creating Possession instances.
    """
    permission_classes = [permissions.IsAuthenticated]
    queryset = Possession.objects.all()
    serializer_class = PossessionSerializer # Use our single, unified serializer

    def get_queryset(self):
        """
        Primary security filter: ensures a user can only see possessions
        that involve a team they are a member of.
        """
        user = self.request.user
        base_queryset = super().get_queryset() # Use the queryset defined on the class

        if user.is_superuser:
            return base_queryset

        member_of_teams_ids = user.player_on_teams.all().values_list('id', flat=True).union(
                              user.coach_on_teams.all().values_list('id', flat=True))
        
        return base_queryset.filter(
            Q(team_id__in=member_of_teams_ids) |
            Q(opponent_id__in=member_of_teams_ids)
        ).distinct()

    def perform_create(self, serializer):
        """
        Hook to automatically set the 'logged_by' field to the current user on creation.
        """
        serializer.save(logged_by=self.request.user)