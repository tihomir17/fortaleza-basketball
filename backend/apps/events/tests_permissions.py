import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.events.models import CalendarEvent
from apps.teams.models import Team
from apps.users.models import User


class EventPermissionsTests(APITestCase):
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

        # Create events
        self.event = CalendarEvent.objects.create(
            title="Team Practice",
            description="Regular team practice",
            team=self.team,
            created_by=self.coach,
            start_time="2024-01-15T10:00:00Z",
            end_time="2024-01-15T12:00:00Z",
        )

        self.other_event = CalendarEvent.objects.create(
            title="Other Team Event",
            description="Another team's event",
            team=self.other_team,
            created_by=self.other_coach,
            start_time="2024-01-16T10:00:00Z",
            end_time="2024-01-16T12:00:00Z",
        )

        self.url = reverse("event-list")
        self.event_detail_url = reverse("event-detail", args=[self.event.id])
        self.other_event_detail_url = reverse(
            "event-detail", args=[self.other_event.id]
        )

    def auth(self, user):
        self.client.force_authenticate(user=user)

    def test_team_member_can_list_team_events(self):
        """Team members can list events for their team."""
        self.auth(self.player)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["title"], "Team Practice")

    def test_non_member_cannot_see_team_events(self):
        """Non-team members cannot see team events."""
        self.auth(self.other_coach)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 0)

    def test_coach_can_create_event_for_team(self):
        """Coach can create events for their team."""
        self.auth(self.coach)
        data = {
            "title": "New Practice",
            "description": "Additional practice session",
            "team": self.team.id,
            "start_time": "2024-01-17T10:00:00Z",
            "end_time": "2024-01-17T12:00:00Z",
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["title"], "New Practice")

    def test_player_cannot_create_event(self):
        """Players cannot create events."""
        self.auth(self.player)
        data = {
            "title": "New Practice",
            "description": "Additional practice session",
            "team": self.team.id,
            "start_time": "2024-01-17T10:00:00Z",
            "end_time": "2024-01-17T12:00:00Z",
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_coach_cannot_create_event_for_other_team(self):
        """Coach cannot create events for other teams."""
        self.auth(self.coach)
        data = {
            "title": "New Practice",
            "description": "Additional practice session",
            "team": self.other_team.id,
            "start_time": "2024-01-17T10:00:00Z",
            "end_time": "2024-01-17T12:00:00Z",
        }
        res = self.client.post(self.url, data, format="json")
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_creator_can_update_event(self):
        """Event creator can update the event."""
        self.auth(self.coach)
        res = self.client.patch(
            self.event_detail_url,
            {"title": "Updated Practice"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["title"], "Updated Practice")

    def test_non_creator_cannot_update_event(self):
        """Non-creator cannot update the event."""
        self.auth(self.player)
        res = self.client.patch(
            self.event_detail_url,
            {"title": "Updated Practice"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_creator_can_delete_event(self):
        """Event creator can delete the event."""
        self.auth(self.coach)
        res = self.client.delete(self.event_detail_url)
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)

    def test_non_creator_cannot_delete_event(self):
        """Non-creator cannot delete the event."""
        self.auth(self.player)
        res = self.client.delete(self.event_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_team_member_can_view_event_detail(self):
        """Team members can view event details."""
        self.auth(self.player)
        res = self.client.get(self.event_detail_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["title"], "Team Practice")

    def test_non_member_cannot_view_event_detail(self):
        """Non-team members cannot view event details."""
        self.auth(self.other_coach)
        res = self.client.get(self.event_detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
