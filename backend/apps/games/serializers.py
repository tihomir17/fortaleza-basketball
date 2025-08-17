# apps/games/serializers.py
from rest_framework import serializers
from .models import Game
from apps.teams.serializers import TeamReadSerializer

class GameSerializer(serializers.ModelSerializer):
    home_team = TeamReadSerializer(read_only=True)
    away_team = TeamReadSerializer(read_only=True)

    class Meta:
        model = Game
        fields = '__all__'