# apps/teams/views.py

from django.db.models import Q
from rest_framework import viewsets, permissions
from .models import Team
from .serializers import TeamSerializer
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.db import connection
from apps.plays.serializers import PlayDefinitionSerializer


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

    @action(detail=True, methods=['get'])
    def plays(self, request, pk=None):
        """
        Custom action to retrieve the playbook for a single team.
        This creates the endpoint: GET /api/teams/{id}/plays/
        """
        # self.get_object() re-uses the logic from get_queryset() to find the
        # team by its 'pk' and automatically ensures the user has permission to see it.
        team = self.get_object()
        
        # Get the related plays for this specific team instance
        plays_queryset = team.plays.all().order_by('name')
        
        # We use the PlayDefinitionSerializer to convert the data to JSON
        serializer = PlayDefinitionSerializer(plays_queryset, many=True)
        
        return Response(serializer.data)