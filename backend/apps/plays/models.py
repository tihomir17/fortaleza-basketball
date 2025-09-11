# apps/plays/models.py

from django.db import models  # pyright: ignore[reportMissingImports]
from django.conf import settings  # pyright: ignore[reportMissingImports]
from django.utils.translation import (  # pyright: ignore[reportMissingImports]
    gettext_lazy as _,
)  # pyright: ignore[reportMissingImports]


class PlayCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        verbose_name_plural = "Play Categories"

    def __str__(self):
        return self.name


class PlayStep(models.Model):
    """
    Individual steps within a play definition.
    """
    play = models.ForeignKey(
        "PlayDefinition",
        on_delete=models.CASCADE,
        related_name="steps"
    )
    order = models.PositiveIntegerField(_("Step Order"))
    title = models.CharField(_("Step Title"), max_length=255)
    description = models.TextField(_("Step Description"))
    diagram = models.URLField(_("Step Diagram"), blank=True, null=True)
    duration = models.PositiveIntegerField(
        _("Step Duration (seconds)"),
        default=30,
        help_text="Duration of this step in seconds"
    )

    class Meta:
        ordering = ['order']
        unique_together = ('play', 'order')

    def __str__(self):
        return f"{self.play.name} - Step {self.order}: {self.title}"


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

    # Additional fields for frontend compatibility
    tags = models.JSONField(default=list, blank=True, help_text="List of tags for categorization")
    difficulty = models.CharField(
        _("Difficulty Level"),
        max_length=20,
        choices=[
            ("Beginner", "Beginner"),
            ("Intermediate", "Intermediate"),
            ("Advanced", "Advanced"),
        ],
        default="Beginner",
    )
    duration = models.PositiveIntegerField(
        _("Duration (seconds)"),
        default=12,
        help_text="Estimated duration of the play in seconds (max 24 for shot clock)"
    )
    players = models.PositiveIntegerField(
        _("Number of Players"),
        default=5,
        help_text="Number of players involved in this play"
    )
    success_rate = models.FloatField(
        _("Success Rate"),
        default=0.0,
        help_text="Success rate percentage (0-100)"
    )
    last_used = models.DateField(
        _("Last Used"),
        null=True,
        blank=True,
        help_text="Date when this play was last used"
    )
    is_favorite = models.BooleanField(
        _("Is Favorite"),
        default=False,
        help_text="Whether this play is marked as favorite"
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_plays",
        help_text="User who created this play"
    )

    class Meta:
        unique_together = ("name", "team")

    def __str__(self):
        if self.parent:
            return f"{self.parent.name} -> {self.name}"
        return self.name
