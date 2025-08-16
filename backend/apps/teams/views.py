# apps/teams/views.py

from django.db.models import Q
from rest_framework import viewsets, permissions
from rest_framework.response import Response # Make sure this is imported
from .models import Team
from .serializers import TeamReadSerializer, TeamWriteSerializer

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

    # --- TEMPORARY DEBUGGING 'create' METHOD ---
    def create(self, request, *args, **kwargs):
        print("\n--- INTERCEPTING CREATE REQUEST ---")
        print(f"Request Data Received: {request.data}")
        
        serializer = self.get_serializer(data=request.data)
        
        # Manually check for validity without raising an immediate exception
        is_valid = serializer.is_valid()
        
        if not is_valid:
            print("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            print("!!! SERIALIZER VALIDATION FAILED !!!")
            print(f"!!! ERRORS: {serializer.errors}")
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
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