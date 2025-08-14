# apps/teams/serializers.py
from rest_framework import serializers
from .models import Team
from apps.users.serializers import UserSerializer

class TeamSerializer(serializers.ModelSerializer):
    # Use UserSerializer to represent players and coaches
    players = UserSerializer(many=True, read_only=True)
    coaches = UserSerializer(many=True, read_only=True)

    class Meta:
        model = Team
        fields = ['id', 'name', 'created_by', 'players', 'coaches']