# apps/users/views.py

from typing import Any, Dict, List, Optional, Type
from django.contrib.auth import get_user_model  # pyright: ignore[reportMissingImports]
from django.http import HttpRequest
from django.db.models import QuerySet
from rest_framework import (  # pyright: ignore[reportMissingImports]
    generics,
    permissions,
    viewsets,
)  # pyright: ignore[reportMissingImports]
from rest_framework.pagination import PageNumberPagination
from django_ratelimit.decorators import ratelimit
from django_filters.rest_framework import (  # pyright: ignore[reportMissingImports]
    DjangoFilterBackend,
)  # pyright: ignore[reportMissingImports]
from .serializers import RegisterSerializer, UserSerializer, UserListSerializer, CoachUpdateSerializer
from .filters import UserFilter
from django.db.models import Q  # pyright: ignore[reportMissingImports]
from apps.teams.models import Team
from rest_framework import (  # pyright: ignore[reportMissingImports]
    viewsets,
    permissions,
)  # <-- Add viewsets  # pyright: ignore[reportMissingImports]
from apps.users.permissions import IsTeamScopedObject  # New import

User = get_user_model()


class UserPagination(PageNumberPagination):
    page_size = 50
    page_size_query_param = "page_size"
    max_page_size = 200


# View for Registering a new User
class RegisterView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]  # Anyone can register
    serializer_class = RegisterSerializer

    @ratelimit(key='ip', rate='5/h', method='POST')
    def post(self, request, *args, **kwargs):
        """Rate limited registration - 5 registrations per hour per IP"""
        return super().post(request, *args, **kwargs)


# View to get the current user's data
class CurrentUserView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]  # Must be logged in to access
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user


class UserSearchView(generics.ListAPIView):
    """
    An endpoint for searching users.
    ?search=query -> returns users whose username, first or last name contains the query.
    """

    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserSerializer

    def get_queryset(self):
        # The search query is passed as a URL parameter, e.g., /api/users/search/?search=john
        query = self.request.query_params.get("search", None)

        # Start with a base queryset of ONLY players
        queryset = User.objects.filter(role=User.Role.PLAYER)

        if query:
            # Search in username, first_name, and last_name fields, case-insensitive
            return User.objects.filter(
                Q(username__icontains=query)
                | Q(first_name__icontains=query)
                | Q(last_name__icontains=query)
            ).exclude(
                id=self.request.user.id
            )  # Exclude the user themselves from the search

        # Exclude any players who are already on a team.
        # The 'player_on_teams' is the related_name from the Team model's 'players' field.
        # The '__isnull=True' filter finds users where this relationship is empty.
        # We also exclude the user making the request.
        return queryset.filter(player_on_teams__isnull=True).exclude(
            id=self.request.user.id
        )


class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated, IsTeamScopedObject]
    filter_backends = [DjangoFilterBackend]
    filterset_class = UserFilter
    pagination_class = UserPagination

    @ratelimit(key='ip', rate='200/h', method='GET')
    def list(self, request, *args, **kwargs):
        """Rate limited list view - 200 requests per hour per IP"""
        return super().list(request, *args, **kwargs)

    @ratelimit(key='ip', rate='300/h', method='GET')
    def retrieve(self, request, *args, **kwargs):
        """Rate limited retrieve view - 300 requests per hour per IP"""
        return super().retrieve(request, *args, **kwargs)

    @ratelimit(key='user', rate='5/h', method='POST')
    def create(self, request, *args, **kwargs):
        """Rate limited create view - 5 requests per hour per user"""
        return super().create(request, *args, **kwargs)

    @ratelimit(key='user', rate='10/h', method=['PUT', 'PATCH'])
    def update(self, request, *args, **kwargs):
        """Rate limited update view - 10 requests per hour per user"""
        return super().update(request, *args, **kwargs)

    @ratelimit(key='user', rate='3/h', method='DELETE')
    def destroy(self, request, *args, **kwargs):
        """Rate limited delete view - 3 requests per hour per user"""
        return super().destroy(request, *args, **kwargs)

    def get_queryset(self) -> QuerySet[User]:
        """
        Optimized query to get users that the current user can access.
        Uses a single query with proper prefetching to avoid N+1 problems.
        """
        user = self.request.user

        # If the user is a superuser, return all users without filtering.
        if user.is_superuser:
            return User.objects.all().prefetch_related(
                "player_on_teams", "coach_on_teams"
            )

        # Optimized single query: Get all users who are on teams where the current user is a member
        # This avoids multiple queries and union operations
        return User.objects.filter(
            Q(player_on_teams__players=user) | 
            Q(coach_on_teams__coaches=user) |
            Q(id=user.id)  # Include the user themselves
        ).distinct().prefetch_related(
            "player_on_teams", "coach_on_teams"
        )

    def get_serializer_class(self) -> Type[Any]:
        """
        Use different serializers based on action for optimal performance.
        """
        if self.action == "list":
            return UserListSerializer  # Lightweight for lists
        elif self.action in ["update", "partial_update"]:
            instance = self.get_object()
            # If the user being updated is a coach, use the specific serializer
            if instance.role == User.Role.COACH:
                return CoachUpdateSerializer
            return UserSerializer
        # For retrieve, create, destroy - use full serializer
        return UserSerializer

    def perform_update(self, serializer):
        # Optional: Add extra validation here if needed, e.g., a coach can't change a user's role.
        # For now, we allow updating the fields in the serializer.
        serializer.save()
