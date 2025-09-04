# apps/games/models.py
from django.db import models
from django.contrib.auth import get_user_model
from apps.teams.models import Team
from apps.competitions.models import Competition

User = get_user_model()


class Game(models.Model):
    home_team = models.ForeignKey(
        Team, on_delete=models.CASCADE, related_name="home_games"
    )
    away_team = models.ForeignKey(
        Team, on_delete=models.CASCADE, related_name="away_games"
    )
    competition = models.ForeignKey(
        Competition, on_delete=models.CASCADE, related_name="games"
    )
    game_date = models.DateTimeField()
    home_team_score = models.IntegerField(default=0)
    away_team_score = models.IntegerField(default=0)
    quarter = models.IntegerField(default=1)
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="created_games",
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True, null=True, blank=True)

    class Meta:
        ordering = ["-game_date"]

    def __str__(self):
        return f"{self.home_team.name} vs {self.away_team.name} - {self.game_date.strftime('%Y-%m-%d')}"


class ScoutingReport(models.Model):
    """Model for storing generated scouting report PDFs"""

    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    pdf_file = models.FileField(upload_to="scouting_reports/")
    file_size = models.IntegerField(help_text="File size in bytes")

    # Filter parameters used to generate the report
    team = models.ForeignKey(
        Team,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="scouting_reports",
    )
    quarter_filter = models.IntegerField(null=True, blank=True)
    last_games = models.IntegerField(null=True, blank=True)
    outcome_filter = models.CharField(
        max_length=10, null=True, blank=True
    )  # 'W', 'L', or null
    home_away_filter = models.CharField(
        max_length=10, null=True, blank=True
    )  # 'Home', 'Away', or null
    min_possessions = models.IntegerField(default=10)

    # Metadata
    created_by = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="created_reports"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} - {self.created_at.strftime('%Y-%m-%d %H:%M')}"

    def get_file_size_mb(self):
        """Return file size in MB"""
        return round(self.file_size / (1024 * 1024), 2)

    def get_download_url(self):
        """Return the download URL for the PDF file"""
        return self.pdf_file.url if self.pdf_file else None


class GameRoster(models.Model):
    """Tracks which 12 players are active for each team in a specific game"""

    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name="rosters")
    team = models.ForeignKey(
        Team, on_delete=models.CASCADE, related_name="game_rosters"
    )
    players = models.ManyToManyField(User, related_name="game_rosters")
    starting_five = models.ManyToManyField(User, related_name="starting_five_rosters")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ["game", "team"]
        ordering = ["game", "team"]

    def __str__(self):
        return f"{self.team.name} roster for {self.game}"

    @property
    def bench_players(self):
        """Returns the 7 bench players (non-starting five)"""
        return self.players.exclude(
            id__in=self.starting_five.values_list("id", flat=True)
        )

    @property
    def is_valid(self):
        """Ensures exactly 12 players total and 5 starting five"""
        return self.players.count() == 12 and self.starting_five.count() == 5
