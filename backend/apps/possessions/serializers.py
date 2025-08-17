# backend/apps/possessions/serializers.py

from rest_framework import serializers
from .models import Possession
from apps.teams.models import Team
from apps.teams.serializers import TeamReadSerializer # For displaying team info

class PossessionSerializer(serializers.ModelSerializer):
    # For GET requests, we want to show the full nested team objects.
    team = TeamReadSerializer(read_only=True)
    opponent = TeamReadSerializer(read_only=True)

    # For POST/PUT requests, the frontend will send the integer IDs for the teams.
    # The 'source' argument tells DRF which model field to populate with the ID.
    team_id = serializers.PrimaryKeyRelatedField(
        queryset=Team.objects.all(), source='team', write_only=True
    )
    opponent_id = serializers.PrimaryKeyRelatedField(
        queryset=Team.objects.all(), source='opponent', write_only=True, required=False, allow_null=True
    )

    class Meta:
        model = Possession
        fields = [
            'id',
            'team',                 # read-only nested object
            'opponent',             # read-only nested object
            'start_time_in_game',
            'duration_seconds',
            'quarter',
            'outcome',
            'offensive_sequence',
            'defensive_sequence',
            'logged_by',
            'team_id',              # write-only ID
            'opponent_id',          # write-only ID
        ]
        # These fields are handled by the view or the write-only fields above.
        read_only_fields = ['logged_by']