# backend/apps/events/views.py

from rest_framework import viewsets, permissions
from rest_framework.pagination import PageNumberPagination
from django_filters.rest_framework import DjangoFilterBackend
from .models import CalendarEvent
from .serializers import CalendarEventSerializer, CalendarEventListSerializer
from .filters import CalendarEventFilter
from django.db.models import Q
from apps.teams.models import Team  # Import the Team model
from apps.users.permissions import IsTeamScopedObject  # New import


class CalendarEventPagination(PageNumberPagination):
    page_size = 50
    page_size_query_param = "page_size"
    max_page_size = 200


class CalendarEventViewSet(viewsets.ModelViewSet):
    serializer_class = CalendarEventSerializer
    permission_classes = [permissions.IsAuthenticated, IsTeamScopedObject]
    queryset = CalendarEvent.objects.all()
    filter_backends = [DjangoFilterBackend]
    filterset_class = CalendarEventFilter
    pagination_class = CalendarEventPagination

    def get_serializer_class(self):
        """Use lightweight serializer for list views"""
        if self.action == "list":
            return CalendarEventListSerializer
        return CalendarEventSerializer

    def get_queryset(self):
        """
        Users can only see events for teams they are a member of,
        or individual events they are attending.
        """
        user = self.request.user
        if user.is_superuser:
            return self.queryset.select_related("team", "created_by").prefetch_related(
                "attendees"
            )

        # Get the actual Team objects the user is a member of.
        # We use the correct related_names from the Team model.
        member_of_teams = Team.objects.filter(
            Q(players=user) | Q(coaches=user) | Q(staff=user)
        ).distinct()

        # Filter events where the event's team is in our list of teams,
        # OR where the user is a direct attendee.
        return (
            self.queryset.filter(Q(team__in=member_of_teams) | Q(attendees=user))
            .distinct()
            .select_related("team", "created_by")
            .prefetch_related("attendees")
        )

    def perform_create(self, serializer):
        user = self.request.user
        
        # Players cannot create events
        if user.role == 'PLAYER':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Players cannot create events.")
        
        # If no team is provided and user is a coach or staff, auto-assign their primary team
        if not serializer.validated_data.get('team') and user.role in ['COACH', 'STAFF']:
            # Get the first team where the user is a coach or staff
            user_teams = Team.objects.filter(
                Q(coaches=user) | Q(staff=user)
            )
            if user_teams.exists():
                serializer.validated_data['team'] = user_teams.first()
        
        serializer.save(created_by=user)
    
    def perform_update(self, serializer):
        user = self.request.user
        
        # Players cannot update events
        if user.role == 'PLAYER':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Players cannot edit events.")
        
        serializer.save()
    
    def perform_destroy(self, instance):
        user = self.request.user
        
        # Players cannot delete events
        if user.role == 'PLAYER':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Players cannot delete events.")
        
        instance.delete()
