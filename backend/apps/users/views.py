# apps/users/views.py

from django.contrib.auth import get_user_model  # pyright: ignore[reportMissingImports]
from rest_framework import (  # pyright: ignore[reportMissingImports]
    generics,
    permissions,
)  # pyright: ignore[reportMissingImports]
from django_filters.rest_framework import (  # pyright: ignore[reportMissingImports]
    DjangoFilterBackend,
)  # pyright: ignore[reportMissingImports]
from .serializers import RegisterSerializer, UserSerializer, CoachUpdateSerializer
from .filters import UserFilter
from django.db.models import Q  # pyright: ignore[reportMissingImports]
from apps.teams.models import Team
from rest_framework import (  # pyright: ignore[reportMissingImports]
    viewsets,
    permissions,
)  # <-- Add viewsets  # pyright: ignore[reportMissingImports]
from apps.users.permissions import IsTeamScopedObject  # New import

User = get_user_model()


# View for Registering a new User
class RegisterView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]  # Anyone can register
    serializer_class = RegisterSerializer


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

    def get_queryset(self):
        """
        THIS IS THE SIMPLEST POSSIBLE LOGIC.
        It ensures a user can edit themselves or any other member of their teams.
        """
        user = self.request.user

        # If the user is a superuser, return all users without filtering.
        if user.is_superuser:
            return User.objects.all().prefetch_related(
                "player_on_teams", "coach_on_teams"
            )

        # Step 1: Get all teams the current user is a member of.
        my_teams = Team.objects.filter(Q(players=user) | Q(coaches=user))

        # Step 2: Get all players from those teams.
        players_on_my_teams = User.objects.filter(player_on_teams__in=my_teams)

        # Step 3: Get all coaches from those teams.
        coaches_on_my_teams = User.objects.filter(coach_on_teams__in=my_teams)

        # Step 4: Combine them all with a union and add the user themselves.
        # The .union() method combines querysets.
        allowed_users = players_on_my_teams.union(coaches_on_my_teams)

        # Step 5: Since union doesn't work well with further filtering,
        # we get the IDs and do a final clean query.
        allowed_ids = set(allowed_users.values_list("id", flat=True))
        allowed_ids.add(user.id)  # Add the user's own ID

        print(f"\n--- FINAL UserViewSet get_queryset ---")
        print(f"User '{user.username}' is on teams: {list(my_teams)}")
        print(f"Allowed to edit user IDs: {list(allowed_ids)}")
        print(f"--- END --- \n")

        return User.objects.filter(id__in=allowed_ids).prefetch_related(
            "player_on_teams", "coach_on_teams"
        )

    def get_serializer_class(self):
        """
        Use a different serializer for updating coaches vs players.
        """
        # When updating an existing user...
        if self.action in ["update", "partial_update"]:
            instance = self.get_object()
            # If the user being updated is a coach, use the specific serializer
            if instance.role == User.Role.COACH:
                return CoachUpdateSerializer

        # For all other actions, use the default comprehensive serializer
        return UserSerializer

    def perform_update(self, serializer):
        # Optional: Add extra validation here if needed, e.g., a coach can't change a user's role.
        # For now, we allow updating the fields in the serializer.
        serializer.save()
