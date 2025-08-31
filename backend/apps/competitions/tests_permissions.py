import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.competitions.models import Competition
from apps.teams.models import Team
from apps.users.models import User


class CompetitionPermissionsTests(APITestCase):
    def setUp(self):
        # Create users
        self.creator = User.objects.create_user(
            username="creator", password="testpass123", role=User.Role.COACH
        )
        self.coach = User.objects.create_user(
            username="coach", password="testpass123", role=User.Role.COACH
        )
        self.player = User.objects.create_user(
            username="player", password="testpass123", role=User.Role.PLAYER
        )

        # Create teams
        self.team = Team.objects.create(name="Test Team", created_by=self.creator)
        self.team.coaches.add(self.creator)
        self.team.players.add(self.player)

        self.other_team = Team.objects.create(name="Other Team", created_by=self.coach)
        self.other_team.coaches.add(self.coach)

        # Create competitions
        self.competition = Competition.objects.create(
            name="Test Competition",
            season="2024",
            created_by=self.creator,
        )

        self.other_competition = Competition.objects.create(
            name="Other Competition",
            season="2024",
            created_by=self.coach,
        )

        self.url = reverse("competition-list")
        self.competition_detail_url = reverse(
            "competition-detail", args=[self.competition.id]
        )
        self.other_competition_detail_url = reverse(
            "competition-detail", args=[self.other_competition.id]
        )

    def auth(self, user):
        self.client.force_authenticate(user=user)

    def test_anyone_can_list_competitions(self):
        """Anyone can list competitions."""
        self.auth(self.player)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 2)

    def test_anyone_can_view_competition_detail(self):
        """Anyone can view competition details."""
        self.auth(self.player)
        res = self.client.get(self.competition_detail_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["name"], "Test Competition")

    def test_creator_can_create_competition(self):
        """Creator can create competitions."""
        self.auth(self.creator)
        data = {
            "name": "New Competition",
            "season": "2025",
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["name"], "New Competition")

    def test_non_creator_cannot_create_competition(self):
        """Non-creator cannot create competitions."""
        self.auth(self.coach)
        data = {
            "name": "New Competition",
            "season": "2025",
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_creator_can_update_competition(self):
        """Creator can update their competition."""
        self.auth(self.creator)
        res = self.client.patch(
            self.competition_detail_url,
            {"name": "Updated Competition"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["name"], "Updated Competition")

    def test_non_creator_cannot_update_competition(self):
        """Non-creator cannot update competition."""
        self.auth(self.coach)
        res = self.client.patch(
            self.competition_detail_url,
            {"name": "Updated Competition"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_creator_can_delete_competition(self):
        """Creator can delete their competition."""
        self.auth(self.creator)
        res = self.client.delete(self.competition_detail_url)
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)

    def test_non_creator_cannot_delete_competition(self):
        """Non-creator cannot delete competition."""
        self.auth(self.coach)
        res = self.client.delete(self.competition_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_creator_cannot_update_other_competition(self):
        """Creator cannot update other competitions."""
        self.auth(self.creator)
        res = self.client.patch(
            self.other_competition_detail_url,
            {"name": "Updated Competition"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_creator_cannot_delete_other_competition(self):
        """Creator cannot delete other competitions."""
        self.auth(self.creator)
        res = self.client.delete(self.other_competition_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_player_cannot_create_competition(self):
        """Players cannot create competitions."""
        self.auth(self.player)
        data = {
            "name": "New Competition",
            "season": "2025",
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_player_cannot_update_competition(self):
        """Players cannot update competitions."""
        self.auth(self.player)
        res = self.client.patch(
            self.competition_detail_url,
            {"name": "Updated Competition"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_player_cannot_delete_competition(self):
        """Players cannot delete competitions."""
        self.auth(self.player)
        res = self.client.delete(self.competition_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
