# apps/users/views.py

from rest_framework import generics, permissions
from .serializers import RegisterSerializer, UserSerializer

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