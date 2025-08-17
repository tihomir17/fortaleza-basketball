# apps/users/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils.translation import gettext_lazy as _

class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN = 'ADMIN', _('Admin')
        COACH = 'COACH', _('Coach')
        PLAYER = 'PLAYER', _('Player')

    class CoachType(models.TextChoices):
        HEAD_COACH = 'HEAD_COACH', _('Head Coach')
        ASSISTANT_COACH = 'ASSISTANT_COACH', _('Assistant Coach')
        SCOUTING_COACH = 'SCOUTING_COACH', _('Scouting Coach')
        ANALYTIC_COACH = 'ANALYTIC_COACH', _('Analytic Coach')
        NONE = 'NONE', _('None')

    role = models.CharField(_('Role'), max_length=50, choices=Role.choices, default=Role.PLAYER)
    coach_type = models.CharField(
        _('Coach Type'), max_length=50, choices=CoachType.choices,
        default=CoachType.NONE, blank=True,
        help_text=_('Only applicable if the role is Coach.')
    )

    jersey_number = models.PositiveIntegerField(
        _('Jersey Number'),
        null=True,
        blank=True
    )    

    def save(self, *args, **kwargs):
        if self.role != self.Role.COACH:
            self.coach_type = self.CoachType.NONE
        super().save(*args, **kwargs)