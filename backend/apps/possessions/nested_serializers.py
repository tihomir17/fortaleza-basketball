# backend/apps/possessions/nested_serializers.py

from rest_framework import serializers
from .models import Possession
from apps.teams.serializers import TeamReadSerializer

# This is a "shallow" serializer. It has NO IMPORTS from other apps' serializers.
# Its only purpose is to be safely imported by other apps without causing a cycle.
class PossessionInGameSerializer(serializers.ModelSerializer):
    team = TeamReadSerializer(read_only=True)
    opponent = TeamReadSerializer(read_only=True)

    class Meta:
        model = Possession
        fields = [
            'id', 'team', 'opponent', 'start_time_in_game', 'duration_seconds',
            'quarter', 'outcome', 'offensive_sequence', 'defensive_sequence',
        ]