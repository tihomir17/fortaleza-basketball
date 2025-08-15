# apps/teams/views.py

from django.db.models import Q
from rest_framework import viewsets, permissions
from .models import Team
from .serializers import TeamSerializer
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.db import connection

class TeamViewSet(viewsets.ModelViewSet):
    """
    This ViewSet automatically provides `list`, `create`, `retrieve`,
    `update`, and `destroy` actions.
    """
    serializer_class = TeamSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        This single method is the source of truth for all data access.
        It is automatically used by BOTH the list view (`/api/teams/`)
        and the detail view (`/api/teams/{id}/`).

        It filters the queryset to ONLY include teams where the logged-in
        user is a member, providing inherent security.
        """
        user = self.request.user
        if not user.is_authenticated:
            return Team.objects.none() # Return empty if no user

        # This is the most standard and robust way to query this relationship.
        # It directly filters the Team objects based on the user.
        return Team.objects.filter(
            Q(coaches=user) | Q(players=user)
        ).distinct()

    # def list(self, request, *args, **kwargs):
    #     """
    #     A simplified and foolproof method to list teams for the current user.
    #     """
    #     user = request.user
        
    #     print("\n--- INSIDE SIMPLIFIED list METHOD ---")
    #     print(f"User: '{user.username}'")

    #     # Step 1: Get the IDs of teams the user coaches.
    #     coached_team_ids = user.teams_as_coach.values_list('id', flat=True)
    #     print(f"User coaches teams with IDs: {list(coached_team_ids)}")

    #     # Step 2: Get the IDs of teams the user plays for.
    #     player_team_ids = user.teams_as_player.values_list('id', flat=True)
    #     print(f"User plays for teams with IDs: {list(player_team_ids)}")
        
    #     # Step 3: Combine the ID lists and remove duplicates.
    #     all_team_ids = set(coached_team_ids) | set(player_team_ids)
    #     print(f"Total unique team IDs: {list(all_team_ids)}")
        
    #     # Step 4: Perform a single, clean query to get the team objects.
    #     final_queryset = Team.objects.filter(id__in=all_team_ids)
    #     print(f"Final QuerySet result: {list(final_queryset)}")
    #     print("--- END OF SIMPLIFIED list METHOD ---\n")
        
    #     serializer = self.get_serializer(final_queryset, many=True)
    #     return Response(serializer.data)

    # def retrieve(self, request, pk=None, *args, **kwargs):
    #     """
    #     This corrected retrieve method works with our simplified logic.
    #     """
    #     user = request.user
    #     team_instance = self.get_object()

    #     is_coach = user.teams_as_coach.filter(pk=team_instance.pk).exists()
    #     is_player = user.teams_as_player.filter(pk=team_instance.pk).exists()

    #     if not (is_coach or is_player):
    #         raise PermissionDenied("You do not have permission to view this team.")

    #     serializer = self.get_serializer(team_instance)
    #     return Response(serializer.data)
