import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.games.models import Game
from apps.teams.models import Team
from apps.users.models import User


class GamePermissionsTests(APITestCase):
    def setUp(self):
        # Create users
        self.coach = User.objects.create_user(
            username="coach", password="testpass123", role=User.Role.COACH
        )
        self.player = User.objects.create_user(
            username="player", password="testpass123", role=User.Role.PLAYER
        )
        self.other_coach = User.objects.create_user(
            username="other_coach", password="testpass123", role=User.Role.COACH
        )

        # Create teams
        self.team_a = Team.objects.create(name="Team A", created_by=self.coach)
        self.team_b = Team.objects.create(name="Team B", created_by=self.coach)
        self.team_c = Team.objects.create(name="Team C", created_by=self.other_coach)

        # Create games
        self.game = Game.objects.create(
            competition=self.competition,
            home_team=self.team1,
            away_team=self.team2,
            game_date=datetime.datetime.now(),
        )

        self.other_game = Game.objects.create(
            home_team=self.team_c,
            away_team=self.team_a,
            game_date="2024-01-16",
            created_by=self.other_coach,
        )

        self.coach.teams.add(self.team_a)
        self.player.teams.add(self.team_a)

        self.url = reverse("game-list")
        self.game_detail_url = reverse("game-detail", args=[self.game.id])
        self.other_game_detail_url = reverse("game-detail", args=[self.other_game.id])

    def auth(self, user):
        self.client.force_authenticate(user=user)

    def test_team_member_can_list_team_games(self):
        """Team members can list games involving their team."""
        self.auth(self.player)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 2)  # Both games involve team_a

    def test_non_member_cannot_see_team_games(self):
        """Non-team members cannot see team games."""
        self.auth(self.other_coach)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 1)  # Only the game they created

    def test_coach_can_create_game_for_team(self):
        """Coach can create games involving their team."""
        self.auth(self.coach)
        data = {
            "home_team": self.team_a.id,
            "away_team": self.team_c.id,
            "game_date": "2024-01-17",
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["home_team"], self.team_a.id)

    def test_player_cannot_create_game(self):
        """Players cannot create games."""
        self.auth(self.player)
        data = {
            "home_team": self.team_a.id,
            "away_team": self.team_c.id,
            "game_date": "2024-01-17",
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_coach_cannot_create_game_without_team(self):
        """Coach cannot create games not involving their team."""
        self.auth(self.coach)
        data = {
            "home_team": self.team_c.id,
            "away_team": self.team_b.id,
            "game_date": "2024-01-17",
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_creator_can_update_game(self):
        """Game creator can update the game."""
        self.auth(self.coach)
        res = self.client.patch(
            self.game_detail_url,
            {"game_date": "2024-01-18"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_non_creator_cannot_update_game(self):
        """Non-creator cannot update the game."""
        self.auth(self.player)
        res = self.client.patch(
            self.game_detail_url,
            {"game_date": "2024-01-18"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_creator_can_delete_game(self):
        """Game creator can delete the game."""
        self.auth(self.coach)
        res = self.client.delete(self.game_detail_url)
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)

    def test_non_creator_cannot_delete_game(self):
        """Non-creator cannot delete the game."""
        self.auth(self.player)
        res = self.client.delete(self.game_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_team_member_can_view_game_detail(self):
        """Team members can view game details."""
        self.auth(self.player)
        res = self.client.get(self.game_detail_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["home_team"], self.team_a.id)

    def test_non_member_cannot_view_game_detail(self):
        """Non-team members cannot view game details."""
        self.auth(self.other_coach)
        res = self.client.get(self.game_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_cannot_create_game_same_team(self):
        """Cannot create game with same team as home and away."""
        self.auth(self.coach)
        data = {
            "home_team": self.team_a.id,
            "away_team": self.team_a.id,
            "game_date": "2024-01-17",
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
