# backend/apps/games/serializers.py

from rest_framework import serializers
from django.db import models
from django.utils import timezone
from .models import Game, ScoutingReport
from apps.teams.models import Team
from apps.teams.serializers import TeamReadSerializer
from apps.possessions.nested_serializers import PossessionInGameSerializer
from .roster_serializers import GameRosterSerializer


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
    
    # Custom field to handle timezone-aware datetimes
    game_date = serializers.DateTimeField()

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
    
    def validate_game_date(self, value):
        """
        Ensure the datetime is timezone-aware.
        If it's naive, make it timezone-aware using the current timezone.
        """
        if timezone.is_naive(value):
            return timezone.make_aware(value)
        return value

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
    home_team_roster = GameRosterSerializer(read_only=True, required=False)
    away_team_roster = GameRosterSerializer(read_only=True, required=False)

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
            "home_team_roster",
            "away_team_roster",
        ]


# --- LIGHTWEIGHT READ SERIALIZER (For faster loading) ---
class GameReadLightweightSerializer(serializers.ModelSerializer):
    # When reading, we show the full, nested objects but without possessions.
    home_team = TeamReadSerializer(read_only=True)
    away_team = TeamReadSerializer(read_only=True)
    # Include roster data for game setup functionality
    home_team_roster = GameRosterSerializer(read_only=True, required=False)
    away_team_roster = GameRosterSerializer(read_only=True, required=False)

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
            "home_team_roster",
            "away_team_roster",
        ]


# --- SCOUTING REPORT SERIALIZER ---
class ScoutingReportSerializer(serializers.ModelSerializer):
    team = TeamReadSerializer(read_only=True)
    created_by = serializers.StringRelatedField(read_only=True)
    tagged_users = serializers.StringRelatedField(many=True, read_only=True)
    file_size_mb = serializers.SerializerMethodField()
    download_url = serializers.SerializerMethodField()
    youtube_embed_url = serializers.SerializerMethodField()
    youtube_thumbnail_url = serializers.SerializerMethodField()

    class Meta:
        model = ScoutingReport
        fields = [
            "id",
            "title",
            "description",
            "report_type",
            "file_size",
            "file_size_mb",
            "download_url",
            "youtube_url",
            "youtube_embed_url",
            "youtube_thumbnail_url",
            "tagged_users",
            "team",
            "quarter_filter",
            "last_games",
            "outcome_filter",
            "home_away_filter",
            "min_possessions",
            "created_by",
            "created_at",
        ]
        read_only_fields = ["file_size", "created_by", "created_at"]

    def get_file_size_mb(self, obj):
        return obj.get_file_size_mb()

    def get_download_url(self, obj):
        return obj.get_download_url()

    def get_youtube_embed_url(self, obj):
        return obj.get_youtube_embed_url()

    def get_youtube_thumbnail_url(self, obj):
        return obj.get_youtube_thumbnail_url()


class ScoutingReportCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating scouting reports with file uploads"""

    tagged_user_ids = serializers.CharField(
        write_only=True,
        required=False,
        help_text="JSON string of user IDs to tag with download rights",
    )

    class Meta:
        model = ScoutingReport
        fields = [
            "title",
            "description",
            "report_type",
            "pdf_file",
            "youtube_url",
            "tagged_user_ids",
        ]

    def validate(self, data):
        report_type = data.get("report_type")

        if report_type == ScoutingReport.ReportType.UPLOADED_PDF:
            if not data.get("pdf_file"):
                raise serializers.ValidationError(
                    "PDF file is required for uploaded PDF reports"
                )
            if data.get("youtube_url"):
                raise serializers.ValidationError(
                    "YouTube URL should not be provided for PDF reports"
                )
        elif report_type == ScoutingReport.ReportType.YOUTUBE_LINK:
            if not data.get("youtube_url"):
                raise serializers.ValidationError(
                    "YouTube URL is required for YouTube link reports"
                )
            if data.get("pdf_file"):
                raise serializers.ValidationError(
                    "PDF file should not be provided for YouTube link reports"
                )

        return data

    def create(self, validated_data):
        tagged_user_ids_str = validated_data.pop("tagged_user_ids", None)
        tagged_user_ids = []

        # Parse JSON string if provided
        if tagged_user_ids_str:
            try:
                import json

                tagged_user_ids = json.loads(tagged_user_ids_str)
                if not isinstance(tagged_user_ids, list):
                    tagged_user_ids = []
            except (json.JSONDecodeError, TypeError):
                tagged_user_ids = []

        # Set file size for PDF uploads
        if (
            validated_data.get("pdf_file")
            and validated_data.get("report_type")
            == ScoutingReport.ReportType.UPLOADED_PDF
        ):
            validated_data["file_size"] = validated_data["pdf_file"].size

        # Create the report
        report = ScoutingReport.objects.create(**validated_data)

        # Add tagged users
        if tagged_user_ids:
            from apps.users.models import User

            tagged_users = User.objects.filter(id__in=tagged_user_ids)
            report.tagged_users.set(tagged_users)

        return report
