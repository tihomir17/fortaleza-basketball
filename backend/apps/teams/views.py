# apps/teams/views.py

from django.db.models import Q
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response # Make sure this is imported
from .models import Team
from .serializers import TeamReadSerializer, TeamWriteSerializer, UserSerializer
from django.contrib.auth import get_user_model
from django.contrib.auth.models import UserManager
from django.shortcuts import get_object_or_404
from apps.plays.serializers import PlayDefinitionSerializer

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
        
        if user.is_superuser:
            return Team.objects.all()

        return self.queryset.filter(
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
        team_to_join = self.get_object() # The team we are adding to
        user_id = request.data.get('user_id')
        role = request.data.get('role')

        if not user_id or not role:
            return Response({'error': 'User ID and role are required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user_to_add = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        if role.lower() == 'player':
            # Check if this player is on any other team.
            # The 'player_on_teams' is the related_name from the Team model.
            existing_teams = user_to_add.player_on_teams.all()
            
            if existing_teams.exists():
                print(f"Player {user_to_add.username} is already on teams: {list(existing_teams)}. Removing them first.")
                # Remove the player from all teams they are currently on.
                for team in existing_teams:
                    team.players.remove(user_to_add)
            
            # Now, add the player to the new team.
            team_to_join.players.add(user_to_add)
            return Response({'status': f'Player {user_to_add.username} added to {team_to_join.name}'}, status=status.HTTP_200_OK)
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

    @action(detail=True, methods=['post'])
    def create_and_add_player(self, request, pk=None):
        """
        Creates a new user with role 'PLAYER' and adds them directly to this team.
        This is for coaches to manually build their roster.
        """
        team = self.get_object()
        email = request.data.get('email')
        username = request.data.get('username')
        first_name = request.data.get('first_name', '') # Optional first name
        last_name = request.data.get('last_name', '')   # Optional last name
        jersey_number = request.data.get('jersey_number', None) # Get the new field

        if not username or not email:
            return Response({'error': 'Username and email are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(Q(email=email) | Q(username=username)).exists():
            return Response({'error': 'A user with this email or username already exists.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Create a full user account, but they can't log in.
            new_player = User.objects.create_user(
                username=username,
                email=email,
                first_name=first_name,
                last_name=last_name,
                password=None,
                role=User.Role.PLAYER,
                is_active=False # is_active=False means they cannot log in.
            )
            if jersey_number is not None:
                new_player.jersey_number = jersey_number
           
            new_player.save()

            team.players.add(new_player)
            serializer = UserSerializer(new_player)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
    @action(detail=True, methods=['get'])
    def plays(self, request, pk=None):
        """
        Custom action to retrieve the playbook for a single team.
        This handles: GET /api/teams/{id}/plays/
        """
        user = request.user
        
        # Step 1: Get the queryset of all teams this user is allowed to see.
        allowed_teams = self.get_queryset()
        
        # Step 2: From that allowed list, get the specific team requested by its pk.
        # If the team is not in the allowed list, this will correctly raise a 404 Not Found error.
        team = get_object_or_404(allowed_teams, pk=pk)
        
        # Step 3: Get and serialize the plays for the confirmed-accessible team.
        plays_queryset = team.plays.all().order_by('name')
        serializer = PlayDefinitionSerializer(plays_queryset, many=True)
        
        return Response(serializer.data)