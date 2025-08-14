# apps/teams/views.py
from rest_framework import viewsets, permissions
from .models import Team
from .serializers import TeamSerializer
from django.db.models import Q

class TeamViewSet(viewsets.ModelViewSet):
    serializer_class = TeamSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        This view should return a list of all the teams
        for the currently authenticated user.
        """
        user = self.request.user

        # --- START DEBUGGING PRINTS ---
        print("\n--- Inside TeamViewSet.get_queryset ---")
        print(f"Authenticated user: {user.username} (ID: {user.id})")
        print(f"User role: {user.role}")

        # Let's see what the database thinks
        coaching_teams = Team.objects.filter(coaches__id=user.id)
        print(f"Teams this user is coaching (by ID): {list(coaching_teams)}")

        playing_teams = Team.objects.filter(players__id=user.id)
        print(f"Teams this user is playing for (by ID): {list(playing_teams)}")

        # The final combined query
        queryset = Team.objects.filter(Q(coaches=user) | Q(players=user)).distinct()
        print(f"Final combined queryset result: {list(queryset)}")
        print("--- End Debugging ---\n")
        # --- END DEBUGGING PRINTS ---

        return queryset