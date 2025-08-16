# apps/plays/views.py
from rest_framework import viewsets, permissions
from .models import PlayDefinition
from rest_framework.exceptions import PermissionDenied
from .serializers import PlayDefinitionSerializer
from apps.users.models import User

class PlayDefinitionViewSet(viewsets.ModelViewSet):
    queryset = PlayDefinition.objects.all()
    serializer_class = PlayDefinitionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        """
        This custom method adds security checks before creating a new play.
        """
        user = self.request.user
        team = serializer.validated_data['team'] # Get the team from the incoming data

        # SECURITY CHECK 1: Is the user a coach?
        if user.role != User.Role.COACH:    #'COACH':
            raise PermissionDenied("Only coaches can create plays.")

        # SECURITY CHECK 2: Is the coach a member of the team they are creating a play for?
        is_member = team.coaches.filter(pk=user.pk).exists()
        if not is_member:
            raise PermissionDenied("You can only create plays for a team you are a coach of.")

        # If all checks pass, save the new play.
        serializer.save()