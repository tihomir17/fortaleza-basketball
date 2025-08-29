# apps/plays/models.py

from django.db import models  # pyright: ignore[reportMissingImports]
from django.conf import settings  # pyright: ignore[reportMissingImports]
from django.utils.translation import (
    gettext_lazy as _,
)  # pyright: ignore[reportMissingImports]


class PlayCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        verbose_name_plural = "Play Categories"

    def __str__(self):
        return self.name


class PlayDefinition(models.Model):
    """
    Stores the definition of an offensive or defensive play.
    """

    # --- THIS IS THE NEW ENUM FOR BUTTON BEHAVIOR ---
    class ActionType(models.TextChoices):
        NORMAL = "NORMAL", _("Normal Button")
        STARTS_POSSESSION = "STARTS_POSSESSION", _(
            "Starts a New Possession (e.g., START)"
        )
        ENDS_POSSESSION = "ENDS_POSSESSION", _("Ends a Possession (e.g., END)")
        TRIGGERS_SHOT_RESULT = "TRIGGERS_SHOT_RESULT", _(
            "Triggers Shot Result (e.g., 2pt, 3pt)"
        )
        IS_SHOT_RESULT = "IS_SHOT_RESULT", _("Is a Shot Result (e.g., Made, Miss)")
        OPENS_TURNOVER_MENU = "OPENS_TURNOVER_MENU", _("Opens Turnover Sub-Menu")
        OPENS_FT_MENU = "OPENS_FT_MENU", _("Opens Free Throw Sub-Menu")
        # Add other special types as needed

    name = models.CharField(_("Play Name"), max_length=255)
    description = models.TextField(_("Description"), blank=True, null=True)
    play_type = models.CharField(
        _("Play Type"),
        max_length=50,
        choices=[("OFFENSIVE", "Offensive"), ("DEFENSIVE", "Defensive")],
    )
    team = models.ForeignKey(
        "teams.Team", on_delete=models.CASCADE, related_name="plays"
    )
    parent = models.ForeignKey(
        "self", on_delete=models.CASCADE, null=True, blank=True, related_name="children"
    )

    category = models.ForeignKey(
        PlayCategory,
        on_delete=models.SET_NULL,
        related_name="plays",
        null=True,
        blank=True,
    )

    subcategory = models.CharField(
        _("UI Sub-Category"), max_length=100, blank=True, null=True
    )

    # --- THIS IS THE NEW FIELD TO CONTROL UI BEHAVIOR ---
    action_type = models.CharField(
        _("UI Action Type"),
        max_length=50,
        choices=ActionType.choices,
        default=ActionType.NORMAL,
        help_text="Defines the button's special behavior in the live tracking UI.",
    )

    diagram_url = models.URLField(blank=True, null=True)
    video_url = models.URLField(blank=True, null=True)

    class Meta:
        unique_together = ("name", "team")

    def __str__(self):
        if self.parent:
            return f"{self.parent.name} -> {self.name}"
        return self.name
