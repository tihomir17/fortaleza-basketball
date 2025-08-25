# backend/apps/events/views.py

from rest_framework import viewsets, permissions
from .models import CalendarEvent
from .serializers import CalendarEventSerializer
from django.db.models import Q
from apps.teams.models import Team  # Import the Team model


class CalendarEventViewSet(viewsets.ModelViewSet):
    serializer_class = CalendarEventSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = CalendarEvent.objects.all()

    def get_queryset(self):
        """
        Users can only see events for teams they are a member of,
        or individual events they are attending.
        """
        user = self.request.user
        if user.is_superuser:
            return self.queryset

        # Get the actual Team objects the user is a member of.
        # We use the correct related_names from the Team model.
        member_of_teams = Team.objects.filter(
            Q(players=user) | Q(coaches=user)
        ).distinct()

        # Filter events where the event's team is in our list of teams,
        # OR where the user is a direct attendee.
        return self.queryset.filter(
            Q(team__in=member_of_teams) | Q(attendees=user)
        ).distinct()

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
