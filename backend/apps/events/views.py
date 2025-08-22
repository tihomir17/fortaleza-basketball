# apps/events/views.py
from rest_framework import viewsets, permissions
from .models import CalendarEvent
from .serializers import CalendarEventSerializer
from django.db.models import Q


class CalendarEventViewSet(viewsets.ModelViewSet):
    serializer_class = CalendarEventSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        Users can only see events for teams they are a member of,
        or individual events they are attending.
        """
        user = self.request.user
        if user.is_superuser:
            return CalendarEvent.objects.all()

        # Get teams the user is a member of
        user_teams = user.player_on_teams.all().union(user.coach_on_teams.all())

        return CalendarEvent.objects.filter(
            Q(team__in=user_teams) | Q(attendees=user)
        ).distinct()

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
