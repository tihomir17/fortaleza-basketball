# apps/competitions/serializers.py
from rest_framework import serializers
from .models import Competition
from apps.teams.serializers import TeamReadSerializer


class CompetitionSerializer(serializers.ModelSerializer):
    # When we view a competition, we can also see a list of its teams
    teams = TeamReadSerializer(many=True, read_only=True)

    class Meta:
        model = Competition
        fields = ["id", "name", "season", "created_by", "teams"]
        read_only_fields = ["created_by"]
