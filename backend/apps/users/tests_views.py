import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.teams.models import Team
from apps.users.models import User


class UserViewsTests(APITestCase):
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
        self.team = Team.objects.create(name="Test Team", created_by=self.coach)
        self.team.coaches.add(self.coach)
        self.team.players.add(self.player)

        self.other_team = Team.objects.create(
            name="Other Team", created_by=self.other_coach
        )
        self.other_team.coaches.add(self.other_coach)

        self.url = reverse("user-list")
        self.coach_detail_url = reverse("user-detail", args=[self.coach.id])
        self.player_detail_url = reverse("user-detail", args=[self.player.id])

    def auth(self, user):
        self.client.force_authenticate(user=user)

    def test_coach_can_list_team_members(self):
        """Coach can list members of their team."""
        self.auth(self.coach)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 2)  # coach and player

    def test_player_can_list_team_members(self):
        """Player can list members of their team."""
        self.auth(self.player)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 2)  # coach and player

    def test_non_member_cannot_list_team_members(self):
        """Non-team members cannot list team members."""
        self.auth(self.other_coach)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 0)

    def test_coach_can_view_team_member_detail(self):
        """Coach can view details of team members."""
        self.auth(self.coach)
        res = self.client.get(self.player_detail_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["username"], "player")

    def test_player_can_view_team_member_detail(self):
        """Player can view details of team members."""
        self.auth(self.player)
        res = self.client.get(self.coach_detail_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["username"], "coach")

    def test_non_member_cannot_view_team_member_detail(self):
        """Non-team members cannot view team member details."""
        self.auth(self.other_coach)
        res = self.client.get(self.player_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_user_can_update_own_profile(self):
        """User can update their own profile."""
        self.auth(self.player)
        res = self.client.patch(
            self.player_detail_url,
            {"first_name": "Updated Name"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["first_name"], "Updated Name")

    def test_coach_can_update_team_member(self):
        """Coach can update team member profiles."""
        self.auth(self.coach)
        res = self.client.patch(
            self.player_detail_url,
            {"first_name": "Coach Updated"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["first_name"], "Coach Updated")

    def test_user_cannot_update_other_user(self):
        """User cannot update other users' profiles."""
        self.auth(self.player)
        res = self.client.patch(
            self.coach_detail_url,
            {"first_name": "Player Updated"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_coach_cannot_update_non_team_member(self):
        """Coach cannot update non-team member profiles."""
        self.auth(self.coach)
        res = self.client.patch(
            reverse("user-detail", args=[self.other_coach.id]),
            {"first_name": "Coach Updated"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_user_can_delete_own_profile(self):
        """User can delete their own profile."""
        self.auth(self.player)
        res = self.client.delete(self.player_detail_url)
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)

    def test_coach_can_delete_team_member(self):
        """Coach can delete team member profiles."""
        self.auth(self.coach)
        res = self.client.delete(self.player_detail_url)
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)

    def test_user_cannot_delete_other_user(self):
        """User cannot delete other users' profiles."""
        self.auth(self.player)
        res = self.client.delete(self.coach_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_coach_cannot_delete_non_team_member(self):
        """Coach cannot delete non-team member profiles."""
        self.auth(self.coach)
        res = self.client.delete(reverse("user-detail", args=[self.other_coach.id]))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_filter_by_role(self):
        """Test filtering users by role."""
        self.auth(self.coach)
        res = self.client.get(f"{self.url}?role=coach")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["role"], "coach")

    def test_filter_by_username(self):
        """Test filtering users by username."""
        self.auth(self.coach)
        res = self.client.get(f"{self.url}?username=player")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["username"], "player")

    def test_search_by_name(self):
        """Test searching users by name."""
        self.player.first_name = "John"
        self.player.last_name = "Doe"
        self.player.save()

        self.auth(self.coach)
        res = self.client.get(f"{self.url}?search=John")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["username"], "player")
