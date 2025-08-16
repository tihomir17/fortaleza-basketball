# apps/teams/views.py

from django.db.models import Q
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response # Make sure this is imported
from .models import Team
from .serializers import TeamReadSerializer, TeamWriteSerializer
from django.contrib.auth import get_user_model

User = get_user_model() # A shortcut to the active User model

class TeamViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    queryset = Team.objects.all()

    def get_serializer_class(self):
        """
        This hook tells the ViewSet which serializer to use based on the action.
        """
        # For writing data, use the simple serializer.
        if self.action in ['create', 'update', 'partial_update']:
            return TeamWriteSerializer
        
        # For reading data, use the powerful serializer that shows the full roster.
        return TeamReadSerializer

    def get_queryset(self):
        # Security filter
        user = self.request.user
        if not user.is_authenticated:
            return Team.objects.none()
        # This query now includes teams the user created,
        # in addition to teams they are a member of.
        return Team.objects.filter(
            Q(coaches=user) | Q(players=user) | Q(created_by=user)
        ).distinct()

    def create(self, request, *args, **kwargs):
        print(f"Request Data Received: {request.data}")
        
        serializer = self.get_serializer(data=request.data)
        
        # Manually check for validity without raising an immediate exception
        is_valid = serializer.is_valid()
        
        if not is_valid:
            # Return the detailed errors to the frontend as well
            return Response(serializer.errors, status=400)
        
        print("--- Serializer is valid. Proceeding to perform_create. ---")
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=201, headers=headers)
    
    def perform_create(self, serializer):
        # This method for setting the creator remains the same.
        team = serializer.save(created_by=self.request.user)
        # The creator is also automatically added to the list of coaches for the new team.
        team.coaches.add(self.request.user)

    @action(detail=True, methods=['post'])
    def add_member(self, request, pk=None):
        """
        Adds a user to a team's roster as either a player or a coach.
        Expects a body like: {'user_id': <id>, 'role': 'player'}
        """
        team = self.get_object() # This automatically handles permissions
        user_id = request.data.get('user_id')
        role = request.data.get('role')

        if not user_id or not role:
            return Response({'error': 'User ID and role are required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user_to_add = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        if role.lower() == 'player':
            team.players.add(user_to_add)
            return Response({'status': f'Player {user_to_add.username} added to {team.name}'}, status=status.HTTP_200_OK)
        elif role.lower() == 'coach':
            team.coaches.add(user_to_add)
            return Response({'status': f'Coach {user_to_add.username} added to {team.name}'}, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Invalid role specified.'}, status=status.HTTP_400_BAD_REQUEST)

    # ADD THIS ACTION
    @action(detail=True, methods=['post'])
    def remove_member(self, request, pk=None):
        """
        Removes a user from a team's roster.
        Expects a body like: {'user_id': <id>, 'role': 'player'}
        """
        team = self.get_object()
        user_id = request.data.get('user_id')
        role = request.data.get('role')

        if not user_id or not role:
            return Response({'error': 'User ID and role are required.'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            user_to_remove = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        if role.lower() == 'player':
            team.players.remove(user_to_remove)
            return Response({'status': f'Player {user_to_remove.username} removed from {team.name}'}, status=status.HTTP_200_OK)
        elif role.lower() == 'coach':
            team.coaches.remove(user_to_remove)
            return Response({'status': f'Coach {user_to_remove.username} removed from {team.name}'}, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Invalid role specified.'}, status=status.HTTP_400_BAD_REQUEST)        