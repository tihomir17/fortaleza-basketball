# apps/users/views.py

from django.contrib.auth import get_user_model
from rest_framework import generics, permissions
from .serializers import RegisterSerializer, UserSerializer
from django.db.models import Q

User = get_user_model()

# View for Registering a new User
class RegisterView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny] # Anyone can register
    serializer_class = RegisterSerializer

# View to get the current user's data
class CurrentUserView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated] # Must be logged in to access
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
        query = self.request.query_params.get('search', None)

        # Start with a base queryset of ONLY players
        queryset = User.objects.filter(role=User.Role.PLAYER)

        if query:
            # Search in username, first_name, and last_name fields, case-insensitive
            return User.objects.filter(
                Q(username__icontains=query) |
                Q(first_name__icontains=query) |
                Q(last_name__icontains=query)
            ).exclude(id=self.request.user.id) # Exclude the user themselves from the search
        
        # Exclude any players who are already on a team.
        # The 'player_on_teams' is the related_name from the Team model's 'players' field.
        # The '__isnull=True' filter finds users where this relationship is empty.
        # We also exclude the user making the request.
        return queryset.filter(player_on_teams__isnull=True).exclude(id=self.request.user.id)