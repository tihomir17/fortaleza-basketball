# apps/plays/views.py
from .models import PlayDefinition
from rest_framework.exceptions import PermissionDenied
from .serializers import PlayDefinitionSerializer, PlayCategory, PlayCategorySerializer
from apps.teams.models import Team
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response  # Make sure this is imported


class PlayCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    A simple ViewSet for listing all PlayCategories, ordered by their ID.
    """

    queryset = PlayCategory.objects.all().order_by("id")
    serializer_class = PlayCategorySerializer
    permission_classes = [permissions.IsAuthenticated]


class PlayDefinitionViewSet(viewsets.ModelViewSet):
    queryset = PlayDefinition.objects.all()
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

    @action(detail=False, methods=["get"])
    def templates(self, request):
        """
        An endpoint to get all generic play definitions that are part of the
        "Default Play Templates" team. This is a public resource for all logged-in users.
        """
        try:
            # We find the default team by name, which is more robust than using ID=1
            default_team = Team.objects.get(name="Default Play Templates")
            templates = PlayDefinition.objects.filter(team=default_team)
            serializer = self.get_serializer(templates, many=True)
            return Response(serializer.data)
        except Team.DoesNotExist:
            return Response(
                {"error": "Default play templates team not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
