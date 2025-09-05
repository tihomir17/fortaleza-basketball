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

    # Game flow and statistics
    lead_changes = models.IntegerField(
        default=0, help_text="Number of lead changes in the game"
    )
    is_close_game = models.BooleanField(
        default=False, help_text="Game decided by 10 points or less"
    )
    is_blowout = models.BooleanField(
        default=False, help_text="Game decided by 20 points or more"
    )
    clutch_situations = models.IntegerField(
        default=0, help_text="Number of clutch situations in last 2 minutes"
    )

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
    """Model for storing scouting reports (PDFs and YouTube links)"""

    class ReportType(models.TextChoices):
        GENERATED_PDF = "GENERATED_PDF", "Generated PDF"
        UPLOADED_PDF = "UPLOADED_PDF", "Uploaded PDF"
        YOUTUBE_LINK = "YOUTUBE_LINK", "YouTube Link"

    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    report_type = models.CharField(
        max_length=20,
        choices=ReportType.choices,
        default=ReportType.GENERATED_PDF,
    )

    # File fields (only one will be used based on report_type)
    pdf_file = models.FileField(upload_to="scouting_reports/", null=True, blank=True)
    file_size = models.IntegerField(
        help_text="File size in bytes", null=True, blank=True
    )
    youtube_url = models.URLField(blank=True, help_text="YouTube video URL")

    # Tagged users with download rights
    tagged_users = models.ManyToManyField(
        User,
        related_name="tagged_scouting_reports",
        blank=True,
        help_text="Users who have access to download/view this report",
    )

    # Filter parameters used to generate the report (only for generated PDFs)
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
        if self.file_size:
            return round(self.file_size / (1024 * 1024), 4)
        return 0

    def get_download_url(self):
        """Return the download URL for the PDF file"""
        return self.pdf_file.url if self.pdf_file else None

    def get_youtube_embed_url(self):
        """Convert YouTube URL to embed URL"""
        if not self.youtube_url:
            return None

        # Extract video ID from various YouTube URL formats
        import re

        video_id = None

        # Standard YouTube URLs
        patterns = [
            r"(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([^&\n?#]+)",
        ]

        for pattern in patterns:
            match = re.search(pattern, self.youtube_url)
            if match:
                video_id = match.group(1)
                break

        if video_id:
            return f"https://www.youtube.com/embed/{video_id}"
        return None

    def get_youtube_thumbnail_url(self):
        """Get YouTube thumbnail URL"""
        if not self.youtube_url:
            return None

        embed_url = self.get_youtube_embed_url()
        if embed_url:
            video_id = embed_url.split("/")[-1]
            return f"https://img.youtube.com/vi/{video_id}/maxresdefault.jpg"
        return None


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
