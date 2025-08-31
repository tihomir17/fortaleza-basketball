import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.plays.models import PlayDefinition, PlayCategory
from apps.teams.models import Team
from apps.competitions.models import Competition
from apps.users.models import User


class PlayPermissionsTests(APITestCase):
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

        # Create competition
        self.competition = Competition.objects.create(
            name="Test League", season="2024", created_by=self.coach
        )

        # Create teams
        self.team = Team.objects.create(
            name="Test Team", competition=self.competition, created_by=self.coach
        )
        self.team.coaches.add(self.coach)
        self.team.players.add(self.player)

        self.other_team = Team.objects.create(
            name="Other Team", competition=self.competition, created_by=self.other_coach
        )
        self.other_team.coaches.add(self.other_coach)

        # Create play category
        self.category = PlayCategory.objects.create(name="Test Category")

        # Create play definitions
        self.play = PlayDefinition.objects.create(
            name="Test Play",
            play_type="OFFENSIVE",
            team=self.team,
            category=self.category,
        )

        self.other_play = PlayDefinition.objects.create(
            name="Other Play",
            description="Another test play",
            play_type="OFFENSIVE",
            team=self.other_team,
            category=self.category,
        )

        self.url = reverse("playdefinition-list")
        self.play_detail_url = reverse("playdefinition-detail", args=[self.play.id])
        self.other_play_detail_url = reverse(
            "playdefinition-detail", args=[self.other_play.id]
        )

    def auth(self, user):
        self.client.force_authenticate(user=user)

    def test_coach_can_update_own_team_play(self):
        """Coach can update plays for their own team."""
        self.auth(self.coach)
        res = self.client.patch(
            self.play_detail_url,
            {"name": "Updated Play Name"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["name"], "Updated Play Name")

    def test_player_cannot_update_play(self):
        """Players cannot update plays."""
        self.auth(self.player)
        res = self.client.patch(
            self.play_detail_url,
            {"name": "Updated Play Name"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_coach_cannot_update_other_team_play(self):
        """Coach cannot update plays for other teams."""
        self.auth(self.coach)
        res = self.client.patch(
            self.other_play_detail_url,
            {"name": "Updated Play Name"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_templates_action_returns_play_templates(self):
        """Templates action returns play templates for the team."""
        self.auth(self.coach)
        res = self.client.get(f"{self.url}templates/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("templates", res.data)
        self.assertEqual(len(res.data["templates"]), 1)
        self.assertEqual(res.data["templates"][0]["name"], "Test Play")

    def test_templates_action_for_non_member_returns_empty(self):
        """Non-team members get empty templates."""
        self.auth(self.other_coach)
        res = self.client.get(f"{self.url}templates/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("templates", res.data)
        self.assertEqual(len(res.data["templates"]), 0)

    def test_coach_can_delete_own_team_play(self):
        """Coach can delete plays for their own team."""
        self.auth(self.coach)
        res = self.client.delete(self.play_detail_url)
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)

    def test_player_cannot_delete_play(self):
        """Players cannot delete plays."""
        self.auth(self.player)
        res = self.client.delete(self.play_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_coach_cannot_delete_other_team_play(self):
        """Coach cannot delete plays for other teams."""
        self.auth(self.coach)
        res = self.client.delete(self.other_play_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
