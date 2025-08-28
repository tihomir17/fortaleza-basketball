# apps/plays/views.py

from .models import PlayDefinition
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

    @action(detail=False, methods=['get'])
    def templates(self, request):
        """
        Returns the master list of all generic play definitions used for the
        live tracking screen buttons.
        """
        try:
            # Find the template team by its specific name
            template_team = Team.objects.get(name="Default Play Templates")
            # Filter plays belonging only to that team
            template_plays = PlayDefinition.objects.filter(team=template_team)
            serializer = self.get_serializer(template_plays, many=True)
            return Response(serializer.data)
        except Team.DoesNotExist:
            return Response(
                {"error": "The 'Default Play Templates' team was not found in the database."},
                status=status.HTTP_404_NOT_FOUND
            )