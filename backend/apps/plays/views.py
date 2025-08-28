# apps/plays/views.py
from rest_framework import viewsets, permissions
from .models import PlayDefinition
from rest_framework.exceptions import PermissionDenied
from .serializers import PlayDefinitionSerializer, PlayCategory, PlayCategorySerializer
from apps.users.models import User


class PlayCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    A simple ViewSet for listing all PlayCategories, ordered by their ID.
    """

    queryset = PlayCategory.objects.all().order_by("id")
    serializer_class = PlayCategorySerializer
    permission_classes = [permissions.IsAuthenticated]


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
        member_of_teams_ids = (
            user.player_on_teams.all()
            .values_list("id", flat=True)
            .union(user.coach_on_teams.all().values_list("id", flat=True))
        )

        # Filter plays to only those belonging to the user's teams
        return PlayDefinition.objects.filter(team_id__in=member_of_teams_ids)
