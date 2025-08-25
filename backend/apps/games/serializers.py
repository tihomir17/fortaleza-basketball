# backend/apps/games/serializers.py

from rest_framework import serializers
from .models import Game
from apps.teams.models import Team
from apps.teams.serializers import TeamReadSerializer
from apps.possessions.nested_serializers import PossessionInGameSerializer


# --- WRITE SERIALIZER (For input) ---
class GameWriteSerializer(serializers.ModelSerializer):
    # When creating, we expect simple integer IDs for the relationships.
    home_team = serializers.PrimaryKeyRelatedField(queryset=Team.objects.all())
    away_team = serializers.PrimaryKeyRelatedField(queryset=Team.objects.all())

    class Meta:
        model = Game
        fields = [
            "id",
            "competition",
            "home_team",
            "away_team",
            "game_date",
            "home_team_score",
            "away_team_score",
        ]

    def validate(self, data):
        """
        Add validation to ensure home_team and away_team are not the same.
        """
        if data["home_team"] == data["away_team"]:
            raise serializers.ValidationError(
                "Home team and away team cannot be the same."
            )
        return data


# --- READ SERIALIZER (For output) ---
class GameReadSerializer(serializers.ModelSerializer):
    # When reading, we show the full, nested objects.
    home_team = TeamReadSerializer(read_only=True)
    away_team = TeamReadSerializer(read_only=True)
    possessions = PossessionInGameSerializer(many=True, read_only=True)

    class Meta:
        model = Game
        fields = [
            "id",
            "competition",
            "home_team",
            "away_team",
            "game_date",
            "home_team_score",
            "away_team_score",
            "possessions",
        ]
