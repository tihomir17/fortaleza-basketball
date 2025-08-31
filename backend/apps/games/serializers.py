# backend/apps/games/serializers.py

from rest_framework import serializers
from django.db import models
from .models import Game
from apps.teams.models import Team
from apps.teams.serializers import TeamReadSerializer
from apps.possessions.nested_serializers import PossessionInGameSerializer


# --- LIGHTWEIGHT SERIALIZER (For game lists) ---
class GameListSerializer(serializers.ModelSerializer):
    home_team = TeamReadSerializer(read_only=True)
    away_team = TeamReadSerializer(read_only=True)

    # Add possession statistics without loading all possession data
    total_possessions = serializers.SerializerMethodField()
    offensive_possessions = serializers.SerializerMethodField()
    defensive_possessions = serializers.SerializerMethodField()
    avg_offensive_possession_time = serializers.SerializerMethodField()

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
            "total_possessions",
            "offensive_possessions",
            "defensive_possessions",
            "avg_offensive_possession_time",
        ]

    def get_total_possessions(self, obj):
        return obj.possessions.count()

    def get_offensive_possessions(self, obj):
        return (
            obj.possessions.filter(offensive_sequence__isnull=False)
            .exclude(offensive_sequence="")
            .count()
        )

    def get_defensive_possessions(self, obj):
        return (
            obj.possessions.filter(defensive_sequence__isnull=False)
            .exclude(defensive_sequence="")
            .count()
        )

    def get_avg_offensive_possession_time(self, obj):
        offensive_possessions = obj.possessions.filter(
            offensive_sequence__isnull=False
        ).exclude(offensive_sequence="")

        if offensive_possessions.exists():
            total_time = (
                offensive_possessions.aggregate(total=models.Sum("duration_seconds"))[
                    "total"
                ]
                or 0
            )
            return total_time / offensive_possessions.count()
        return 0


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
    possessions = PossessionInGameSerializer(many=True, read_only=True, required=False)

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


# --- LIGHTWEIGHT READ SERIALIZER (For faster loading) ---
class GameReadLightweightSerializer(serializers.ModelSerializer):
    # When reading, we show the full, nested objects but without possessions.
    home_team = TeamReadSerializer(read_only=True)
    away_team = TeamReadSerializer(read_only=True)

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
