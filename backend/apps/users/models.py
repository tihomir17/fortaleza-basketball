# apps/users/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils.translation import gettext_lazy as _


class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN = "ADMIN", _("Admin")
        COACH = "COACH", _("Coach")
        PLAYER = "PLAYER", _("Player")
        STAFF = "STAFF", _("Staff")

    class CoachType(models.TextChoices):
        HEAD_COACH = "HEAD_COACH", _("Head Coach")
        ASSISTANT_COACH = "ASSISTANT_COACH", _("Assistant Coach")
        SCOUTING_COACH = "SCOUTING_COACH", _("Scouting Coach")
        ANALYTIC_COACH = "ANALYTIC_COACH", _("Analytic Coach")
        NONE = "NONE", _("None")

    class StaffType(models.TextChoices):
        PHYSIO = "PHYSIO", _("Physiotherapist")
        STRENGTH_CONDITIONING = "STRENGTH_CONDITIONING", _("Strength & Conditioning")
        MANAGEMENT = "MANAGEMENT", _("Management")
        NONE = "NONE", _("None")

    role = models.CharField(
        _("Role"), max_length=50, choices=Role.choices, default=Role.PLAYER
    )
    coach_type = models.CharField(
        _("Coach Type"),
        max_length=50,
        choices=CoachType.choices,
        default=CoachType.NONE,
        blank=True,
        help_text=_("Only applicable if the role is Coach."),
    )
    staff_type = models.CharField(
        _("Staff Type"),
        max_length=50,
        choices=StaffType.choices,
        default=StaffType.NONE,
        blank=True,
        help_text=_("Only applicable if the role is Staff."),
    )

    jersey_number = models.PositiveIntegerField(
        _("Jersey Number"), null=True, blank=True
    )
    
    # Player-specific fields
    position = models.CharField(
        _("Position"), 
        max_length=10, 
        choices=[
            ("PG", "Point Guard"),
            ("SG", "Shooting Guard"),
            ("SF", "Small Forward"),
            ("PF", "Power Forward"),
            ("C", "Center"),
        ],
        null=True, 
        blank=True,
        help_text=_("Player position (only applicable if role is Player)")
    )
    
    # Player skill ratings
    overall_rating = models.PositiveIntegerField(
        _("Overall Rating"), null=True, blank=True, help_text=_("Player overall rating (1-100)")
    )
    three_point_rating = models.PositiveIntegerField(
        _("Three Point Rating"), null=True, blank=True, help_text=_("Player three point shooting rating (1-100)")
    )
    defense_rating = models.PositiveIntegerField(
        _("Defense Rating"), null=True, blank=True, help_text=_("Player defensive rating (1-100)")
    )
    passing_rating = models.PositiveIntegerField(
        _("Passing Rating"), null=True, blank=True, help_text=_("Player passing rating (1-100)")
    )
    rebounding_rating = models.PositiveIntegerField(
        _("Rebounding Rating"), null=True, blank=True, help_text=_("Player rebounding rating (1-100)")
    )

    def save(self, *args, **kwargs):
        if self.role != self.Role.COACH:
            self.coach_type = self.CoachType.NONE
        if self.role != self.Role.STAFF:
            self.staff_type = self.StaffType.NONE
        super().save(*args, **kwargs)
