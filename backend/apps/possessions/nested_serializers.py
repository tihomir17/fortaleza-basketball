# backend/apps/possessions/nested_serializers.py

from rest_framework import serializers
from .models import Possession
from apps.teams.serializers import TeamReadSerializer
from apps.games.roster_serializers import GameRosterSerializer
from apps.users.serializers import UserSerializer


# This is a "shallow" serializer. It has NO IMPORTS from other apps' serializers.
# Its only purpose is to be safely imported by other apps without causing a cycle.
class PossessionInGameSerializer(serializers.ModelSerializer):
    team = GameRosterSerializer(read_only=True)
    opponent = GameRosterSerializer(read_only=True)
    scorer = UserSerializer(read_only=True)
    assisted_by = UserSerializer(read_only=True)
    blocked_by = UserSerializer(read_only=True)
    stolen_by = UserSerializer(read_only=True)
    fouled_by = UserSerializer(read_only=True)
    players_on_court = UserSerializer(read_only=True, many=True)
    defensive_players_on_court = UserSerializer(read_only=True, many=True)
    offensive_rebound_players = UserSerializer(read_only=True, many=True)

    class Meta:
        model = Possession
        fields = [
            "id",
            "team",
            "opponent",
            "quarter",
            "start_time_in_game",
            "duration_seconds",
            "outcome",
            "points_scored",
            # Offensive rebounds
            "is_offensive_rebound",
            "offensive_rebound_count",
            "players_on_court",
            "defensive_players_on_court",
            "offensive_rebound_players",
            "offensive_set",
            "defensive_set",
            "offensive_sequence",
            "defensive_sequence",
            # Player attributions
            "scorer",
            "assisted_by",
            "blocked_by",
            "stolen_by",
            "fouled_by",
        ]
