# backend/apps/possessions/serializers.py

from rest_framework import serializers
from .models import Possession
from apps.teams.models import Team
from apps.teams.serializers import TeamReadSerializer

from apps.games.models import Game
from apps.games.serializers import GameSerializer


class PossessionSerializer(serializers.ModelSerializer):
    # --- For Reading Data (Output) ---
    game = GameSerializer(read_only=True)
    team = TeamReadSerializer(read_only=True)

    # --- For Writing Data (Input) ---
    game_id = serializers.PrimaryKeyRelatedField(
        queryset=Game.objects.all(), source="game", write_only=True
    )
    team_id = serializers.PrimaryKeyRelatedField(
        queryset=Team.objects.all(), source="team", write_only=True
    )

    opponent_id = serializers.PrimaryKeyRelatedField(
        queryset=Team.objects.all(), source="opponent", write_only=True
    )

    class Meta:
        model = Possession
        fields = [
            "id",
            "game",
            "team",
            "opponent",
            "start_time_in_game",
            "duration_seconds",
            "quarter",
            "outcome",
            "offensive_sequence",
            "defensive_sequence",
            "logged_by",
            "game_id",
            "team_id",
            "opponent_id",
        ]
        read_only_fields = ["logged_by"]
