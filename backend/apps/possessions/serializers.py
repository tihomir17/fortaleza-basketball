# backend/apps/possessions/serializers.py

from rest_framework import serializers  # pyright: ignore[reportMissingImports]
from apps.teams.models import Team
from apps.games.models import Game, GameRoster
from apps.possessions.models import Possession
from apps.teams.serializers import TeamReadSerializer
from apps.games.serializers import GameReadSerializer, GameWriteSerializer
from apps.games.roster_serializers import GameRosterSerializer
from apps.users.serializers import UserSerializer


# Lightweight serializer for possession lists
class PossessionListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for possession lists - minimal fields for better performance"""
    class Meta:
        model = Possession
        fields = [
            "id",
            "game",
            "team",
            "opponent",
            "quarter",
            "start_time_in_game",
            "outcome",
            "points_scored",
            "created_at",
        ]


# This is the "deep" serializer for the main /api/possessions/ endpoint.
class PossessionSerializer(serializers.ModelSerializer):
    game = GameReadSerializer(read_only=True)
    team = GameRosterSerializer(read_only=True)
    opponent = GameRosterSerializer(read_only=True)
    scorer = UserSerializer(read_only=True)
    assisted_by = UserSerializer(read_only=True)
    blocked_by = UserSerializer(read_only=True)
    stolen_by = UserSerializer(read_only=True)
    fouled_by = UserSerializer(read_only=True)

    # Write-only id fields
    game_id = serializers.PrimaryKeyRelatedField(
        queryset=Game.objects.all(), source="game", write_only=True, required=True
    )
    team_id = serializers.PrimaryKeyRelatedField(
        queryset=GameRoster.objects.all(), source="team", write_only=True, required=True
    )
    opponent_id = serializers.PrimaryKeyRelatedField(
        queryset=GameRoster.objects.all(),
        source="opponent",
        write_only=True,
        required=False,
        allow_null=True,
    )

    def validate_outcome(self, value: str) -> str:
        alias_map = {
            "MADE_2PT": Possession.OutcomeChoices.MADE_2PTS,
            "MISSED_2PT": Possession.OutcomeChoices.MISSED_2PTS,
            "MADE_3PT": Possession.OutcomeChoices.MADE_3PTS,
            "MISSED_3PT": Possession.OutcomeChoices.MISSED_3PTS,
        }
        return alias_map.get(value, value)

    def validate(self, attrs):
        game = attrs.get("game")
        team = attrs.get("team")
        opponent = attrs.get("opponent")
        errors = {}

        if game and team:
            # team is now a GameRoster, so we check team.team.id
            if team.team.id not in {game.home_team_id, game.away_team_id}:
                errors["team_id"] = [
                    "Team must be either the home or away team for the selected game."
                ]
        if game and opponent:
            expected_opponent_id = (
                (
                    game.away_team_id
                    if team and team.team.id == game.home_team_id
                    else game.home_team_id
                )
                if team
                else None
            )
            if opponent.team.id not in {game.home_team_id, game.away_team_id}:
                errors["opponent_id"] = [
                    "Opponent must be either the home or away team for the selected game."
                ]
            elif expected_opponent_id and opponent.team.id != expected_opponent_id:
                errors["opponent_id"] = [
                    "Opponent must be the other team in the game, not the same as the possession team."
                ]

        # Validate that rosters are properly created before allowing possession logging
        if game and team and opponent:
            from apps.games.models import GameRoster
            
            # Check if both rosters exist
            try:
                home_roster = GameRoster.objects.get(game=game, team=game.home_team)
                away_roster = GameRoster.objects.get(game=game, team=game.away_team)
                
                # Check if rosters have minimum required players (10)
                if home_roster.players.count() < 10:
                    errors["roster"] = [
                        f"Home team ({game.home_team.name}) roster has only {home_roster.players.count()} players. Minimum 10 players required before logging possessions."
                    ]
                
                if away_roster.players.count() < 10:
                    errors["roster"] = [
                        f"Away team ({game.away_team.name}) roster has only {away_roster.players.count()} players. Minimum 10 players required before logging possessions."
                    ]
                    
            except GameRoster.DoesNotExist as e:
                missing_team = game.home_team.name if "home" in str(e) else game.away_team.name
                errors["roster"] = [
                    f"Game roster for {missing_team} not found. Please create rosters for both teams before logging possessions."
                ]

        if errors:
            raise serializers.ValidationError(errors)
        return attrs

    def create(self, validated_data):
        # Handle ManyToMany fields separately
        players_on_court_data = validated_data.pop("players_on_court", [])
        offensive_rebound_players_data = validated_data.pop(
            "offensive_rebound_players", []
        )

        # Create the possession
        possession = super().create(validated_data)

        # Add ManyToMany relationships
        if players_on_court_data:
            possession.players_on_court.set(players_on_court_data)
        if offensive_rebound_players_data:
            possession.offensive_rebound_players.set(offensive_rebound_players_data)

        return possession

    def update(self, instance, validated_data):
        # Handle ManyToMany fields separately
        players_on_court_data = validated_data.pop("players_on_court", None)
        offensive_rebound_players_data = validated_data.pop(
            "offensive_rebound_players", None
        )

        # Update the possession
        possession = super().update(instance, validated_data)

        # Update ManyToMany relationships if provided
        if players_on_court_data is not None:
            possession.players_on_court.set(players_on_court_data)
        if offensive_rebound_players_data is not None:
            possession.offensive_rebound_players.set(offensive_rebound_players_data)

        return possession

    class Meta:
        model = Possession
        fields = [
            "id",
            "game",
            "team",
            "opponent",
            "quarter",
            "start_time_in_game",
            "duration_seconds",
            "outcome",
            "points_scored",
            # Offensive analysis fields
            "offensive_set",
            "pnr_type",
            "pnr_result",
            "has_paint_touch",
            "has_kick_out",
            "has_extra_pass",
            "number_of_passes",
            # Offensive rebounds
            "is_offensive_rebound",
            "offensive_rebound_count",
            "offensive_rebound_players",
            # Defensive analysis fields
            "defensive_set",
            "defensive_pnr",
            "box_out_count",
            "offensive_rebounds_allowed",
            # Shooting analysis
            "shoot_time",
            "shoot_quality",
            "time_range",
            # Context
            "after_timeout",
            # Player attributions
            "scorer",
            "assisted_by",
            "blocked_by",
            "stolen_by",
            "fouled_by",
            "players_on_court",
            "notes",
            # Sequence fields
            "offensive_sequence",
            "defensive_sequence",
            # Metadata
            "created_by",
            "created_at",
            "updated_at",
            # write-only ids for create/update
            "game_id",
            "team_id",
            "opponent_id",
        ]
        read_only_fields = ["created_by", "created_at", "updated_at", "points_scored"]
