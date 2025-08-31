import pytest
import datetime
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.games.models import Game
from apps.possessions.models import Possession
from apps.teams.models import Team
from apps.competitions.models import Competition
from apps.users.models import User


class PossessionValidationTests(APITestCase):
    def setUp(self):
        # Create users
        self.coach = User.objects.create_user(
            username="coach", password="testpass123", role=User.Role.COACH
        )

        # Create competition
        self.competition = Competition.objects.create(
            name="Test League", season="2024", created_by=self.coach
        )

        # Create teams
        self.team_a = Team.objects.create(
            name="Team A", competition=self.competition, created_by=self.coach
        )
        self.team_b = Team.objects.create(
            name="Team B", competition=self.competition, created_by=self.coach
        )
        self.team_c = Team.objects.create(
            name="Team C", competition=self.competition, created_by=self.coach
        )

        # Create game
        self.game = Game.objects.create(
            competition=self.competition,
            home_team=self.team_a,
            away_team=self.team_b,
            game_date=datetime.datetime.now(),
        )

        self.team_a.coaches.add(self.coach)

        self.url = reverse("possession-list")

    def auth(self, user):
        self.client.force_authenticate(user=user)

    def test_team_not_in_game_validation_error(self):
        """Cannot create possession with team not in the game."""
        self.auth(self.coach)
        data = {
            "game_id": self.game.id,
            "team_id": self.team_c.id,  # Team C is not in the game
            "opponent_id": self.team_b.id,
            "start_time_in_game": "10:00",
            "duration_seconds": 24,
            "quarter": 1,
            "outcome": Possession.OutcomeChoices.MADE_2PTS,
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("team_id", res.data)

    def test_opponent_not_in_game_validation_error(self):
        """Cannot create possession with opponent not in the game."""
        self.auth(self.coach)
        data = {
            "game_id": self.game.id,
            "team_id": self.team_a.id,
            "opponent_id": self.team_c.id,  # Team C is not in the game
            "start_time_in_game": "10:00",
            "duration_seconds": 24,
            "quarter": 1,
            "outcome": Possession.OutcomeChoices.MADE_2PTS,
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("opponent_id", res.data)

    def test_team_equals_opponent_validation_error(self):
        """Cannot create possession with team equal to opponent."""
        self.auth(self.coach)
        data = {
            "game_id": self.game.id,
            "team_id": self.team_a.id,
            "opponent_id": self.team_a.id,  # Same as team
            "start_time_in_game": "10:00",
            "duration_seconds": 24,
            "quarter": 1,
            "outcome": Possession.OutcomeChoices.MADE_2PTS,
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("non_field_errors", res.data)

    def test_outcome_alias_normalization(self):
        """Test that outcome aliases are normalized correctly."""
        self.auth(self.coach)
        data = {
            "game_id": self.game.id,
            "team_id": self.team_a.id,
            "opponent_id": self.team_b.id,
            "start_time_in_game": "10:00",
            "duration_seconds": 24,
            "quarter": 1,
            "outcome": "MADE_2PT",  # Alias for MADE_2PTS
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["outcome"], "MADE_2PTS")  # Should be normalized

    def test_other_outcome_aliases(self):
        """Test other outcome aliases are normalized."""
        self.auth(self.coach)
        aliases = [
            ("MISSED_2PT", "MISSED_2PTS"),
            ("MADE_3PT", "MADE_3PTS"),
            ("MISSED_3PT", "MISSED_3PTS"),
            ("MADE_FT", "MADE_FTS"),
            ("MISSED_FT", "MISSED_FTS"),
        ]

        for alias, expected in aliases:
            data = {
                "game_id": self.game.id,
                "team_id": self.team_a.id,
                "opponent_id": self.team_b.id,
                "start_time_in_game": "10:00",
                "duration_seconds": 24,
                "quarter": 1,
                "outcome": alias,
            }
            res = self.client.post(self.url, data, format="json")
            self.assertEqual(res.status_code, status.HTTP_201_CREATED)
            self.assertEqual(res.data["outcome"], expected)

    def test_valid_possession_creation(self):
        """Test valid possession creation with proper validation."""
        self.auth(self.coach)
        data = {
            "game_id": self.game.id,
            "team_id": self.team_a.id,
            "opponent_id": self.team_b.id,
            "start_time_in_game": "10:00",
            "duration_seconds": 24,
            "quarter": 1,
            "outcome": Possession.OutcomeChoices.MADE_2PTS,
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["team"], self.team_a.id)
        self.assertEqual(res.data["opponent"], self.team_b.id)
        self.assertEqual(res.data["game"], self.game.id)

    def test_possession_without_opponent(self):
        """Test possession creation without opponent (optional field)."""
        self.auth(self.coach)
        data = {
            "game_id": self.game.id,
            "team_id": self.team_a.id,
            # No opponent_id
            "start_time_in_game": "10:00",
            "duration_seconds": 24,
            "quarter": 1,
            "outcome": Possession.OutcomeChoices.MADE_2PTS,
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIsNone(res.data["opponent"])
