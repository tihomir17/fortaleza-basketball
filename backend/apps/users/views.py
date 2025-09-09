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
from django_filters.rest_framework import (  # pyright: ignore[reportMissingImports]
    DjangoFilterBackend,
)  # pyright: ignore[reportMissingImports]
from .serializers import RegisterSerializer, UserSerializer, UserListSerializer, CoachUpdateSerializer, ChangePasswordSerializer, ResetPasswordSerializer
from .filters import UserFilter
from django.db.models import Q  # pyright: ignore[reportMissingImports]
from apps.teams.models import Team
from rest_framework import (  # pyright: ignore[reportMissingImports]
    viewsets,
    permissions,
    status,
)  # <-- Add viewsets  # pyright: ignore[reportMissingImports]
from rest_framework.decorators import action
from rest_framework.response import Response
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

    def post(self, request, *args, **kwargs):
        """Registration endpoint"""
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
        # The search query is passed as a URL parameter, e.g., /api/users/search/?search=john&role=player
        query = self.request.query_params.get("search", None)
        role = self.request.query_params.get("role", None)

        if query:
            # Start with base search query
            queryset = User.objects.filter(
                Q(username__icontains=query)
                | Q(first_name__icontains=query)
                | Q(last_name__icontains=query)
            ).exclude(
                id=self.request.user.id
            )  # Exclude the user themselves from the search
            
            # Filter by role if specified
            if role:
                role_upper = role.upper()
                if role_upper == 'PLAYER':
                    queryset = queryset.filter(role=User.Role.PLAYER)
                elif role_upper == 'COACH':
                    queryset = queryset.filter(role=User.Role.COACH)
                elif role_upper == 'STAFF':
                    queryset = queryset.filter(role=User.Role.STAFF)
            
            return queryset

        # If no search query, return empty queryset
        return User.objects.none()


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated, IsTeamScopedObject]
    filter_backends = [DjangoFilterBackend]
    filterset_class = UserFilter
    pagination_class = UserPagination

    def list(self, request, *args, **kwargs):
        """List view for users"""
        return super().list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        """Retrieve view for users"""
        return super().retrieve(request, *args, **kwargs)

    def create(self, request, *args, **kwargs):
        """Create view for users"""
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        """Update view for users"""
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        """Delete view for users"""
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

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def change_password(self, request):
        """
        Change password for the current user
        """
        serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            user = request.user
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            
            return Response({
                'message': 'Password changed successfully'
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def reset_password(self, request, pk=None):
        """
        Reset password for a specific user (admin/coach only)
        """
        user = self.get_object()
        
        # Check if current user has permission to reset this user's password
        if not (request.user.is_superuser or 
                (request.user.role == User.Role.COACH and 
                 user.role in [User.Role.PLAYER, User.Role.STAFF])):
            return Response({
                'error': 'You do not have permission to reset this user\'s password'
            }, status=status.HTTP_403_FORBIDDEN)
        
        serializer = ResetPasswordSerializer(data=request.data)
        if serializer.is_valid():
            new_password = serializer.validated_data['new_password']
            user.set_password(new_password)
            user.save()
            
            return Response({
                'message': f'Password reset successfully for {user.username}',
                'new_password': new_password
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
