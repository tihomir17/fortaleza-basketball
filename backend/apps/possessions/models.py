# backend/apps/possessions/models.py

from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.translation import gettext_lazy as _
from django.conf import settings
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
