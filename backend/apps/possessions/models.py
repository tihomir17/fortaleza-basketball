# backend/apps/possessions/models.py

from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.translation import gettext_lazy as _
from django.conf import settings
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from apps.games.models import Game, GameRoster
from apps.users.models import User


class Possession(models.Model):
    class OutcomeChoices(models.TextChoices):
        MADE_2PTS = "MADE_2PTS", _("Made 2-Point Shot")
        MISSED_2PTS = "MISSED_2PTS", _("Missed 2-Point Shot")
        MADE_3PTS = "MADE_3PTS", _("Made 3-Point Shot")
        MISSED_3PTS = "MISSED_3PTS", _("Missed 3-Point Shot")
        MADE_FTS = "MADE_FTS", _("Made Free Throw")
        MISSED_FTS = "MISSED_FTS", _("Missed Free Throw")
        TURNOVER = "TURNOVER", _("Turnover")
        FOUL = "FOUL", _("Foul")
        REBOUND = "REBOUND", _("Rebound")
        STEAL = "STEAL", _("Steal")
        BLOCK = "BLOCK", _("Block")
        TECHNICAL_FOUL = "TECHNICAL_FOUL", _("Technical Foul")
        COACH_CHALLENGE = "COACH_CHALLENGE", _("Coach Challenge")

    class OffensiveSetChoices(models.TextChoices):
        PICK_AND_ROLL = "PICK_AND_ROLL", _("Pick and Roll")
        PICK_AND_POP = "PICK_AND_POP", _("Pick and Pop")
        HANDOFF = "HANDOFF", _("Handoff")
        BACKDOOR = "BACKDOOR", _("Backdoor")
        FLARE = "FLARE", _("Flare")
        DOWN_SCREEN = "DOWN_SCREEN", _("Down Screen")
        UP_SCREEN = "UP_SCREEN", _("Up Screen")
        CROSS_SCREEN = "CROSS_SCREEN", _("Cross Screen")
        POST_UP = "POST_UP", _("Post Up")
        ISOLATION = "ISOLATION", _("Isolation")
        TRANSITION = "TRANSITION", _("Transition")
        OFFENSIVE_REBOUND = "OFFENSIVE_REBOUND", _("Offensive Rebound")
        # Additional sets from JSON file
        SET_1 = "Set 1", _("Set 1")
        SET_2 = "Set 2", _("Set 2")
        SET_3 = "Set 3", _("Set 3")
        SET_4 = "Set 4", _("Set 4")
        SET_5 = "Set 5", _("Set 5")
        SET_6 = "Set 6", _("Set 6")
        SET_7 = "Set 7", _("Set 7")
        SET_8 = "Set 8", _("Set 8")
        SET_9 = "Set 9", _("Set 9")
        SET_10 = "Set 10", _("Set 10")
        SET_11 = "Set 11", _("Set 11")
        SET_12 = "Set 12", _("Set 12")
        SET_13 = "Set 13", _("Set 13")
        SET_14 = "Set 14", _("Set 14")
        SET_15 = "Set 15", _("Set 15")
        SET_16 = "Set 16", _("Set 16")
        SET_17 = "Set 17", _("Set 17")
        SET_18 = "Set 18", _("Set 18")
        SET_19 = "Set 19", _("Set 19")
        SET_20 = "Set 20", _("Set 20")
        FASTBREAK = "FastBreak", _("Fast Break")
        TRANSIT = "Transit", _("Transit")
        LESS_THAN_14S = "<14s", _("Less than 14s")
        BOB_1 = "BoB 1", _("BoB 1")
        BOB_2 = "BoB 2", _("BoB 2")
        SOB_1 = "SoB 1", _("SoB 1")
        SOB_2 = "SoB 2", _("SoB 2")
        SPECIAL_1 = "Special 1", _("Special 1")
        SPECIAL_2 = "Special 2", _("Special 2")
        ATO_SPEC = "ATO Spec", _("ATO Special")
        PNR = "PnR", _("Pick and Roll")
        SCORE = "Score", _("Score")
        BIG_GUY = "Big Guy", _("Big Guy")
        THIRD_GUY = "3rd Guy", _("3rd Guy")
        ISO = "ISO", _("Isolation")
        HIGH_POST = "HighPost", _("High Post")
        LOW_POST = "LowPost", _("Low Post")
        ATTACK_CLOSEOUT = "Attack CloseOut", _("Attack Close Out")
        AFTER_KICK_OUT = "After Kick Out", _("After Kick Out")
        AFTER_EXT_PASS = "After Ext Pass", _("After Extra Pass")
        CUTS = "Cuts", _("Cuts")
        AFTER_OFF_REB = "After Off Reb", _("After Offensive Rebound")
        AFTER_HANDOFF = "After HandOff", _("After Hand Off")
        AFTER_OFFSCREEN = "After OffScreen", _("After Off Screen")
        TECHNICAL_FOUL = "Technical Foul", _("Technical Foul")
        COACH_CHALLENGE = "Coach Challenge", _("Coach Challenge")
        OTHER = "OTHER", _("Other")

    class DefensiveSetChoices(models.TextChoices):
        MAN_TO_MAN = "MAN_TO_MAN", _("Man to Man")
        ZONE_2_3 = "ZONE_2_3", _("2-3 Zone")
        ZONE_3_2 = "ZONE_3_2", _("3-2 Zone")
        ZONE_1_3_1 = "ZONE_1_3_1", _("1-3-1 Zone")
        PRESS = "PRESS", _("Press")
        TRAP = "TRAP", _("Trap")
        SWITCH = "SWITCH", _("Switch")
        ICE = "ICE", _("Ice")
        GO_OVER = "GO_OVER", _("Go Over")
        GO_UNDER = "GO_UNDER", _("Go Under")
        # Additional defensive sets from JSON file
        HEDGE = "HEDGE", _("Hedge")
        FLAT = "FLAT", _("Flat")
        WEAK = "WEAK", _("Weak")
        ZONE = "zone", _("Zone")
        FULL_COURT_PRESS = "Full court press", _("Full Court Press")
        THREE_QUARTER_COURT_PRESS = "3/4 court press", _("3/4 Court Press")
        HALF_COURT_PRESS = "Half court press", _("Half Court Press")
        TECHNICAL_FOUL = "Technical Foul", _("Technical Foul")
        OTHER = "OTHER", _("Other")

    class PnRTypeChoices(models.TextChoices):
        BALL_SCREEN = "BALL_SCREEN", _("Ball Screen")
        OFF_BALL_SCREEN = "OFF_BALL_SCREEN", _("Off Ball Screen")
        HANDOFF_SCREEN = "HANDOFF_SCREEN", _("Handoff Screen")
        NONE = "NONE", _("None")

    class PnRResultChoices(models.TextChoices):
        SCORER = "SCORER", _("Scorer")
        BIG_GUY = "BIG_GUY", _("Big Guy")
        KICK_OUT = "KICK_OUT", _("Kick Out")
        REJECT = "REJECT", _("Reject")
        NONE = "NONE", _("None")

    class DefensivePnRChoices(models.TextChoices):
        SWITCH = "SWITCH", _("Switch")
        ICE = "ICE", _("Ice")
        GO_OVER = "GO_OVER", _("Go Over")
        GO_UNDER = "GO_UNDER", _("Go Under")
        TRAP = "TRAP", _("Trap")
        NONE = "NONE", _("None")

    class ShootQualityChoices(models.TextChoices):
        EXCELLENT = "EXCELLENT", _("Excellent")
        GOOD = "GOOD", _("Good")
        AVERAGE = "AVERAGE", _("Average")
        POOR = "POOR", _("Poor")
        CONTESTED = "CONTESTED", _("Contested")
        OPEN = "OPEN", _("Open")

    class TimeRangeChoices(models.TextChoices):
        EARLY_SHOT_CLOCK = "EARLY_SHOT_CLOCK", _("Early Shot Clock (0-7s)")
        MID_SHOT_CLOCK = "MID_SHOT_CLOCK", _("Mid Shot Clock (8-14s)")
        LATE_SHOT_CLOCK = "LATE_SHOT_CLOCK", _("Late Shot Clock (15-24s)")
        SHOT_CLOCK_VIOLATION = "SHOT_CLOCK_VIOLATION", _("Shot Clock Violation")

    # Basic possession fields
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name="possessions")
    team = models.ForeignKey(
        GameRoster, on_delete=models.CASCADE, related_name="offensive_possessions"
    )
    opponent = models.ForeignKey(
        GameRoster, on_delete=models.CASCADE, related_name="defensive_possessions"
    )
    quarter = models.IntegerField()
    start_time_in_game = models.CharField(
        max_length=10
    )  # Format: "MM:SS" (time remaining in quarter)
    duration_seconds = models.IntegerField(default=0)
    outcome = models.CharField(max_length=50)
    points_scored = models.IntegerField(default=0)
    created_by = models.ForeignKey("users.User", on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Offensive analysis fields
    offensive_set = models.CharField(
        max_length=20, choices=OffensiveSetChoices.choices, null=True, blank=True
    )
    pnr_type = models.CharField(
        max_length=20, choices=PnRTypeChoices.choices, default=PnRTypeChoices.NONE
    )
    pnr_result = models.CharField(
        max_length=20, choices=PnRResultChoices.choices, default=PnRResultChoices.NONE
    )

    # Sequence analysis
    has_paint_touch = models.BooleanField(default=False)
    has_kick_out = models.BooleanField(default=False)
    has_extra_pass = models.BooleanField(default=False)
    number_of_passes = models.PositiveIntegerField(default=0)

    # Offensive rebounds
    is_offensive_rebound = models.BooleanField(default=False)
    offensive_rebound_players = models.ManyToManyField(
        "users.User", related_name="offensive_rebounds", blank=True
    )
    offensive_rebound_count = models.PositiveIntegerField(default=0)

    # Defensive analysis
    defensive_set = models.CharField(
        max_length=20, choices=DefensiveSetChoices.choices, null=True, blank=True
    )
    defensive_pnr = models.CharField(
        max_length=20,
        choices=DefensivePnRChoices.choices,
        default=DefensivePnRChoices.NONE,
    )

    # Box out analysis
    box_out_count = models.PositiveIntegerField(default=0)
    offensive_rebounds_allowed = models.PositiveIntegerField(default=0)

    # Shooting analysis
    shoot_time = models.PositiveIntegerField(
        null=True, blank=True
    )  # Seconds into possession
    shoot_quality = models.CharField(
        max_length=20, choices=ShootQualityChoices.choices, null=True, blank=True
    )
    time_range = models.CharField(
        max_length=25, choices=TimeRangeChoices.choices, null=True, blank=True
    )

    # Context
    after_timeout = models.BooleanField(default=False)

    # Player attributions (for detailed player stats)
    scorer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="scored_possessions",
        null=True,
        blank=True,
    )
    assisted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="assisted_possessions",
        null=True,
        blank=True,
    )
    blocked_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="blocked_possessions",
        null=True,
        blank=True,
    )
    stolen_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="stolen_possessions",
        null=True,
        blank=True,
    )
    fouled_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="fouled_possessions",
        null=True,
        blank=True,
    )

    # Players on court (for lineup analysis)
    players_on_court = models.ManyToManyField(
        "users.User", related_name="possessions_on_court", blank=True
    )
    defensive_players_on_court = models.ManyToManyField(
        "users.User", related_name="defensive_possessions_on_court", blank=True
    )

    # Sequence fields for tracking possession actions
    offensive_sequence = models.TextField(
        blank=True, help_text="Sequence of offensive actions"
    )
    defensive_sequence = models.TextField(
        blank=True, help_text="Sequence of defensive actions"
    )

    # Special scenarios
    is_buzzer_beater = models.BooleanField(
        default=False, help_text="Game-winning shot at the buzzer"
    )
    is_technical_foul = models.BooleanField(
        default=False, help_text="Technical foul possession"
    )
    technical_foul_player = models.ForeignKey(
        "users.User",
        on_delete=models.SET_NULL,
        related_name="technical_foul_possessions",
        null=True,
        blank=True,
        help_text="Player who committed the technical foul",
    )
    is_coach_challenge = models.BooleanField(
        default=False, help_text="Coach's challenge possession"
    )

    # Additional metadata
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ["game", "quarter", "start_time_in_game"]
        indexes = [
            models.Index(fields=["game", "quarter"]),
            models.Index(fields=["team", "offensive_set"]),
            models.Index(fields=["opponent", "defensive_set"]),
            models.Index(fields=["pnr_type", "pnr_result"]),
            models.Index(fields=["outcome", "points_scored"]),
            models.Index(fields=["has_paint_touch", "has_kick_out"]),
            models.Index(fields=["is_offensive_rebound", "offensive_rebound_count"]),
            models.Index(fields=["shoot_quality", "shoot_time"]),
            models.Index(fields=["after_timeout"]),
        ]

    def __str__(self):
        return f"{self.team} vs {self.opponent} - Q{self.quarter} {self.start_time_in_game} - {self.outcome}"

    def save(self, *args, **kwargs):
        # Auto-calculate points based on outcome
        if self.outcome == self.OutcomeChoices.MADE_2PTS:
            self.points_scored = 2
        elif self.outcome == self.OutcomeChoices.MADE_3PTS:
            self.points_scored = 3
        elif self.outcome == self.OutcomeChoices.MADE_FTS:
            self.points_scored = 1
        else:
            self.points_scored = 0

        # Auto-set scorer if not already set and we have an offensive sequence
        if not self.scorer and self.offensive_sequence and self.points_scored > 0:
            scorer = parse_player_from_sequence(self.offensive_sequence, self.team)
            if scorer:
                self.scorer = scorer

        super().save(*args, **kwargs)

    @property
    def ppp(self):
        """Points per possession"""
        return self.points_scored

    @property
    def is_successful(self):
        """Whether the possession resulted in points"""
        return self.points_scored > 0

    @property
    def is_pnr_possession(self):
        """Whether this is a pick and roll possession"""
        return self.pnr_type != self.PnRTypeChoices.NONE

    @property
    def has_sequence_actions(self):
        """Whether the possession has any sequence actions"""
        return self.has_paint_touch or self.has_kick_out or self.has_extra_pass


# Signal handlers to update game score when possessions change
@receiver(post_save, sender=Possession)
def update_game_score_on_possession_save(sender, instance, created, **kwargs):
    """Update game score when a possession is created or updated"""
    update_game_score(instance.game)


@receiver(post_delete, sender=Possession)
def update_game_score_on_possession_delete(sender, instance, **kwargs):
    """Update game score when a possession is deleted"""
    try:
        # Check if the game still exists before trying to update it
        if hasattr(instance, 'game') and instance.game:
            update_game_score(instance.game)
    except Exception:
        # If game is already deleted or doesn't exist, skip the update
        pass


def update_game_score(game):
    """Calculate and update the game score based on all possessions"""
    from django.db.models import Sum, Case, When, IntegerField
    
    # Get all possessions for this game
    possessions = Possession.objects.filter(game=game)
    
    # Calculate home team score (points scored by home team roster)
    home_team_score = possessions.filter(
        team__team=game.home_team
    ).aggregate(
        total=Sum('points_scored')
    )['total'] or 0
    
    # Calculate away team score (points scored by away team roster)
    away_team_score = possessions.filter(
        team__team=game.away_team
    ).aggregate(
        total=Sum('points_scored')
    )['total'] or 0
    
    # Update the game scores
    game.home_team_score = home_team_score
    game.away_team_score = away_team_score
    game.save(update_fields=['home_team_score', 'away_team_score'])


def parse_player_from_sequence(sequence, team_roster):
    """Parse the offensive sequence to extract the player number who scored"""
    if not sequence or not team_roster:
        return None
    
    # Split the sequence by '/' and look for player numbers
    parts = [part.strip() for part in sequence.split('/')]
    
    for part in parts:
        # Check if this part is a number (player jersey number)
        if part.isdigit():
            player_number = int(part)
            # Find the player with this jersey number in the roster
            try:
                player = team_roster.players.get(jersey_number=player_number)
                return player
            except:
                continue
    
    return None
