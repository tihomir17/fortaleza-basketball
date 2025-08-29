from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import Game
from apps.teams.models import Team
from .serializers import GameReadSerializer, GameWriteSerializer
from .filters import GameFilter
from django.db.models import Q  # Import Q
from apps.users.permissions import IsTeamScopedObject  # New import


class GameViewSet(viewsets.ModelViewSet):
    queryset = Game.objects.all().order_by("-game_date")
    permission_classes = [permissions.IsAuthenticated, IsTeamScopedObject]
    filter_backends = [DjangoFilterBackend]
    filterset_class = GameFilter

    def get_serializer_class(self):
        """
        Use the 'Write' serializer for creating/updating,
        and the 'Read' serializer for viewing.
        """
        if self.action in ["create", "update", "partial_update"]:
            return GameWriteSerializer
        return GameReadSerializer

    def get_queryset(self):
        """
        Filters games to only show those involving teams the user is a member of.
        Superusers can see all games.
        """
        user = self.request.user

        # Superusers see everything
        if user.is_superuser:
            return self.queryset.select_related('competition', 'home_team', 'away_team')

        # Get all teams the user is a member of
        member_of_teams = Team.objects.filter(
            Q(players=user) | Q(coaches=user)
        ).distinct()

        # Filter games where one of the user's teams was either home or away
        return self.queryset.filter(
            Q(home_team__in=member_of_teams) | Q(away_team__in=member_of_teams)
        ).distinct().select_related('competition', 'home_team', 'away_team')

    def create(self, request, *args, **kwargs):
        """
        Custom create action to ensure the response uses the ReadSerializer.
        """
        # Use the 'Write' serializer to validate the incoming data
        write_serializer = self.get_serializer(data=request.data)
        write_serializer.is_valid(raise_exception=True)

        # self.perform_create saves the object and returns the model instance
        instance = self.perform_create(write_serializer)

        # Now, create a 'Read' serializer using the new instance to generate the response
        read_serializer = GameReadSerializer(
            instance, context=self.get_serializer_context()
        )

        headers = self.get_success_headers(read_serializer.data)
        # Return the data from the 'Read' serializer, which contains the full nested objects
        return Response(
            read_serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )

    def perform_create(self, serializer):
        """
        This hook is called by 'create' and just saves the instance.
        """
        return serializer.save()
