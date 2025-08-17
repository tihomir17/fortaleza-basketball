# backend/apps/possessions/models.py

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _

class Possession(models.Model):
    class QuarterChoices(models.IntegerChoices):
        FIRST = 1, _('1st Quarter')
        SECOND = 2, _('2nd Quarter')
        THIRD = 3, _('3rd Quarter')
        FOURTH = 4, _('4th Quarter')
        OT1 = 5, _('Overtime 1')
        OT2 = 6, _('Overtime 2')

    class OutcomeChoices(models.TextChoices):
        MADE_2PT = 'MADE_2PT', _('Made 2-Point Shot')
        MISSED_2PT = 'MISSED_2PT', _('Missed 2-Point Shot')
        MADE_3PT = 'MADE_3PT', _('Made 3-Point Shot')
        MISSED_3PT = 'MISSED_3PT', _('Missed 3-Point Shot')
        MADE_FT = 'MADE_FT', _('Made Free Throw(s)')
        MISSED_FT = 'MISSED_FT', _('Missed Free Throw(s)')
        TURNOVER_OFFENSIVE_FOUL = 'TO_OFFENSIVE_FOUL', _('Turnover: Offensive Foul')
        TURNOVER_OUT_OF_BOUNDS = 'TO_OUT_OF_BOUNDS', _('Turnover: Out of Bounds')
        TURNOVER_TRAVEL = 'TO_TRAVEL', _('Turnover: Traveling')
        TURNOVER_SHOT_CLOCK = 'TO_SHOT_CLOCK', _('Turnover: Shot Clock')
        TURNOVER_8_SECONDS = 'TO_8_SECONDS', _('Turnover: 8 Seconds')
        TURNOVER_3_SECONDS = 'TO_3_SECONDS', _('Turnover: 3 Seconds')
        OTHER = 'OTHER', _('Other')

    # Team relationships
    team = models.ForeignKey('teams.Team', on_delete=models.CASCADE, related_name='possessions')
    opponent = models.ForeignKey(
        'teams.Team', on_delete=models.SET_NULL, null=True,
        blank=True, related_name='opponent_possessions'
    )
    
    # Metadata
    start_time_in_game = models.CharField(_('Start Time (e.g., 12:00)'), max_length=5)
    duration_seconds = models.PositiveIntegerField(_('Duration (seconds)'))
    quarter = models.IntegerField(_('Quarter'), choices=QuarterChoices.choices)
    
    # The definitive result
    outcome = models.CharField(_('Outcome'), max_length=50, choices=OutcomeChoices.choices)
    
    # The two sequences, stored as flexible text blocks
    offensive_sequence = models.TextField(
        _('Offensive Sequence'), blank=True,
        help_text="The sequence of offensive actions, e.g., 'P&R -> Cut -> Kickout Pass'."
    )
    defensive_sequence = models.TextField(
        _('Defensive Sequence'), blank=True,
        help_text="The sequence of defensive actions, e.g., 'Hedge -> Switch'."
    )

    logged_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    
    class Meta:
        ordering = ['-id'] # Show newest possessions first by default

    def __str__(self):
        opponent_name = self.opponent.name if self.opponent else "Unknown"
        return f"{self.team.name} vs {opponent_name} in Q{self.quarter} at {self.start_time_in_game}"
