import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.teams.models import Team
from apps.competitions.models import Competition
from apps.users.models import User


class TeamActionsTests(APITestCase):
    def setUp(self):
        # Create users
        self.coach = User.objects.create_user(
            username="coach", password="testpass123", role=User.Role.COACH
        )
        self.player = User.objects.create_user(
            username="player", password="testpass123", role=User.Role.PLAYER
        )
        self.new_player = User.objects.create_user(
            username="new_player", password="testpass123", role=User.Role.PLAYER
        )
        self.other_coach = User.objects.create_user(
            username="other_coach", password="testpass123", role=User.Role.COACH
        )

        # Create competition
        self.competition = Competition.objects.create(
            name="Test League", season="2024", created_by=self.coach
        )

        # Create team
        self.team = Team.objects.create(
            name="Test Team", competition=self.competition, created_by=self.coach
        )
        self.team.coaches.add(self.coach)
        self.team.players.add(self.player)

        self.url = reverse("team-list")
        self.team_detail_url = reverse("team-detail", args=[self.team.id])

    def auth(self, user):
        self.client.force_authenticate(user=user)

    def test_coach_can_add_member(self):
        """Coach can add a new member to their team."""
        self.auth(self.coach)
        data = {"user_id": self.new_player.id, "role": "player"}
        res = self.client.post(
            f"{self.team_detail_url}add_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn(self.new_player, self.team.players.all())

    def test_coach_can_add_coach(self):
        """Coach can add another coach to their team."""
        self.auth(self.coach)
        data = {"user_id": self.other_coach.id, "role": "coach"}
        res = self.client.post(
            f"{self.team_detail_url}add_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn(self.other_coach, self.team.coaches.all())

    def test_player_cannot_add_member(self):
        """Players cannot add members to the team."""
        self.auth(self.player)
        data = {"user_id": self.new_player.id, "role": "player"}
        res = self.client.post(
            f"{self.team_detail_url}add_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_coach_cannot_add_member_to_other_team(self):
        """Coach cannot add members to other teams."""
        other_team = Team.objects.create(
            name="Other Team", competition=self.competition, created_by=self.other_coach
        )
        self.auth(self.coach)
        data = {"user_id": self.new_player.id, "role": "player"}
        res = self.client.post(
            f"{reverse('team-detail', args=[other_team.id])}add_member/",
            data,
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_add_member_invalid_role(self):
        """Cannot add member with invalid role."""
        self.auth(self.coach)
        data = {"user_id": self.new_player.id, "role": "invalid_role"}
        res = self.client.post(
            f"{self.team_detail_url}add_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_add_member_missing_user_id(self):
        """Cannot add member without user_id."""
        self.auth(self.coach)
        data = {"role": "player"}
        res = self.client.post(
            f"{self.team_detail_url}add_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_add_member_missing_role(self):
        """Cannot add member without role."""
        self.auth(self.coach)
        data = {"user_id": self.new_player.id}
        res = self.client.post(
            f"{self.team_detail_url}add_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_add_member_user_not_found(self):
        """Cannot add non-existent user."""
        self.auth(self.coach)
        data = {"user_id": 99999, "role": "player"}
        res = self.client.post(
            f"{self.team_detail_url}add_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_coach_can_remove_member(self):
        """Coach can remove a member from their team."""
        self.auth(self.coach)
        data = {"user_id": self.player.id}
        res = self.client.post(
            f"{self.team_detail_url}remove_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertNotIn(self.player, self.team.players.all())

    def test_coach_can_remove_coach(self):
        """Coach can remove another coach from their team."""
        self.team.coaches.add(self.other_coach)
        self.auth(self.coach)
        data = {"user_id": self.other_coach.id}
        res = self.client.post(
            f"{self.team_detail_url}remove_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertNotIn(self.other_coach, self.team.coaches.all())

    def test_player_cannot_remove_member(self):
        """Players cannot remove members from the team."""
        self.auth(self.player)
        data = {"user_id": self.new_player.id}
        res = self.client.post(
            f"{self.team_detail_url}remove_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_coach_cannot_remove_member_from_other_team(self):
        """Coach cannot remove members from other teams."""
        other_team = Team.objects.create(name="Other Team", created_by=self.other_coach)
        other_team.players.add(self.new_player)
        self.auth(self.coach)
        data = {"user_id": self.new_player.id}
        res = self.client.post(
            f"{reverse('team-detail', args=[other_team.id])}remove_member/",
            data,
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_remove_member_missing_user_id(self):
        """Cannot remove member without user_id."""
        self.auth(self.coach)
        data = {}
        res = self.client.post(
            f"{self.team_detail_url}remove_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_remove_member_user_not_found(self):
        """Cannot remove non-existent user."""
        self.auth(self.coach)
        data = {"user_id": 99999}
        res = self.client.post(
            f"{self.team_detail_url}remove_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_remove_member_not_on_team(self):
        """Cannot remove user who is not on the team."""
        self.auth(self.coach)
        data = {"user_id": self.new_player.id}
        res = self.client.post(
            f"{self.team_detail_url}remove_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_coach_cannot_remove_themselves(self):
        """Coach cannot remove themselves from the team."""
        self.auth(self.coach)
        data = {"user_id": self.coach.id}
        res = self.client.post(
            f"{self.team_detail_url}remove_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_remove_last_coach_fails(self):
        """Cannot remove the last coach from the team."""
        self.auth(self.coach)
        data = {"user_id": self.coach.id}
        res = self.client.post(
            f"{self.team_detail_url}remove_member/", data, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn(self.coach, self.team.coaches.all())
