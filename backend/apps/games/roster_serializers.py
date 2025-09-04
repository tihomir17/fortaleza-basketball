# backend/apps/games/roster_serializers.py

from rest_framework import serializers
from .models import GameRoster
from apps.teams.serializers import TeamReadSerializer
from apps.users.serializers import UserSerializer


class GameRosterSerializer(serializers.ModelSerializer):
    team = TeamReadSerializer(read_only=True)
    players = UserSerializer(many=True, read_only=True)
    starting_five = UserSerializer(many=True, read_only=True)

    class Meta:
        model = GameRoster
        fields = ["id", "team", "players", "starting_five", "created_at"]
