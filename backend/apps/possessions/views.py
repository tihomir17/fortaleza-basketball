# backend/apps/possessions/views.py

from django.db.models import Q
from rest_framework import viewsets, permissions

# We do not need status or Response for this simple fix
from .models import Possession
from apps.teams.models import Team

# We only need to import the one serializer you are using
from .serializers import PossessionSerializer


class PossessionViewSet(viewsets.ModelViewSet):
    """
    ViewSet for viewing and creating Possession instances.
    """

    permission_classes = [permissions.IsAuthenticated]
    queryset = Possession.objects.all().order_by("-id")

    # We use your single, unified serializer for all actions.
    serializer_class = PossessionSerializer

    # The get_serializer_class method is NOT needed because we only have one serializer.
    # def get_serializer_class(self): ...

    def get_queryset(self):
        """
        Primary security filter.
        """
        user = self.request.user
        base_queryset = super().get_queryset()

        if user.is_superuser:
            return base_queryset

        member_of_teams_ids = (
            user.player_on_teams.all()
            .values_list("id", flat=True)
            .union(user.coach_on_teams.all().values_list("id", flat=True))
        )

        return base_queryset.filter(
            Q(team_id__in=member_of_teams_ids) | Q(opponent_id__in=member_of_teams_ids)
        ).distinct()

    # The custom 'create' method is NOT needed. The default mixin works correctly.
    # def create(self, request, *args, **kwargs): ...

    def perform_create(self, serializer):
        """
        This hook is the only customization needed. It correctly sets the 'logged_by' user.
        The default create action in ModelViewSet will handle the rest, including
        generating the correct response with nested objects.
        """
        serializer.save(logged_by=self.request.user)
