# apps/plays/views.py
from rest_framework import viewsets, permissions
from .models import PlayDefinition
from rest_framework.exceptions import PermissionDenied
from .serializers import PlayDefinitionSerializer
from apps.users.models import User

class PlayDefinitionViewSet(viewsets.ModelViewSet):
    serializer_class = PlayDefinitionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        This queryset ensures that a user can only ever see, edit, or delete
        plays that belong to a team they are a member of.
        """
        user = self.request.user
        # Get IDs of all teams the user is a member of (as player or coach)
        member_of_teams_ids = user.player_on_teams.all().values_list('id', flat=True).union(
                              user.coach_on_teams.all().values_list('id', flat=True))
        
        # Filter plays to only those belonging to the user's teams
        return PlayDefinition.objects.filter(team_id__in=member_of_teams_ids)