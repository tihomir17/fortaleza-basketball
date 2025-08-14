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
        # Filter teams where the user is listed in the 'coaches' or 'players' ManyToManyField
        return Team.objects.filter(Q(coaches=user) | Q(players=user)).distinct()