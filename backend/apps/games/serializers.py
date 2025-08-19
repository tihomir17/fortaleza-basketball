# backend/apps/games/serializers.py

from rest_framework import serializers
from .models import Game
from apps.teams.serializers import TeamReadSerializer
# Import from the new, safe file
from apps.possessions.nested_serializers import PossessionInGameSerializer

class GameSerializer(serializers.ModelSerializer):
    home_team = TeamReadSerializer(read_only=True)
    away_team = TeamReadSerializer(read_only=True)
    
    # This now safely uses the shallow serializer
    possessions = PossessionInGameSerializer(many=True, read_only=True)

    class Meta:
        model = Game
        fields = ['id', 'competition', 'home_team', 'away_team', 'game_date', 
                  'home_team_score', 'away_team_score', 'possessions']