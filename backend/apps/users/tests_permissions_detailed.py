import pytest
from django.test import TestCase
from django.contrib.auth.models import AnonymousUser
from rest_framework.test import APIRequestFactory
from rest_framework.permissions import SAFE_METHODS

from apps.users.models import User
from apps.teams.models import Team
from apps.games.models import Game
from apps.plays.models import PlayDefinition
from apps.events.models import CalendarEvent
from apps.competitions.models import Competition
from apps.possessions.models import Possession
from apps.users.permissions import IsTeamScopedObject


class IsTeamScopedObjectTests(TestCase):
    def setUp(self):
        self.factory = APIRequestFactory()
        self.permission = IsTeamScopedObject()

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
        self.other_player = User.objects.create_user(
            username="other_player", password="testpass123", role=User.Role.PLAYER
        )

        # Create teams
        self.team = Team.objects.create(name="Test Team", created_by=self.coach)
        self.team.coaches.add(self.coach)
        self.team.players.add(self.player)

        self.other_team = Team.objects.create(
            name="Other Team", created_by=self.other_coach
        )
        self.other_team.coaches.add(self.other_coach)
        self.other_team.players.add(self.other_player)

        # Create objects
        self.game = Game.objects.create(
            home_team=self.team,
            away_team=self.other_team,
            game_date="2024-01-15",
            created_by=self.coach,
        )

        self.play = PlayDefinition.objects.create(
            name="Test Play",
            description="A test play",
            team=self.team,
            created_by=self.coach,
        )

        self.event = CalendarEvent.objects.create(
            title="Team Practice",
            description="Regular team practice",
            team=self.team,
            created_by=self.coach,
            start_time="2024-01-15T10:00:00Z",
            end_time="2024-01-15T12:00:00Z",
        )

        self.competition = Competition.objects.create(
            name="Test Competition",
            season="2024",
            created_by=self.coach,
        )

        self.possession = Possession.objects.create(
            game=self.game,
            team=self.team,
            opponent=self.other_team,
            start_time_in_game="10:00",
            duration_seconds=24,
            quarter=1,
            outcome=Possession.OutcomeChoices.MADE_2PTS,
        )

    def test_safe_methods_for_team_member(self):
        """Team members can perform safe methods on team objects."""
        for method in SAFE_METHODS:
            request = self.factory.generic(method, "/test/")
            request.user = self.player

            # Test with different object types
            for obj in [self.game, self.play, self.event, self.possession]:
                has_permission = self.permission.has_object_permission(
                    request, None, obj
                )
                self.assertTrue(
                    has_permission,
                    f"Player should have {method} permission on {obj.__class__.__name__}",
                )

    def test_safe_methods_for_non_member(self):
        """Non-team members cannot perform safe methods on team objects."""
        for method in SAFE_METHODS:
            request = self.factory.generic(method, "/test/")
            request.user = self.other_player

            # Test with different object types
            for obj in [self.game, self.play, self.event, self.possession]:
                has_permission = self.permission.has_object_permission(
                    request, None, obj
                )
                self.assertFalse(
                    has_permission,
                    f"Other player should not have {method} permission on {obj.__class__.__name__}",
                )

    def test_post_method_for_coach(self):
        """Coaches can create objects for their team."""
        request = self.factory.post("/test/")
        request.user = self.coach

        # Test with different object types
        for obj in [self.game, self.play, self.event, self.possession]:
            has_permission = self.permission.has_object_permission(request, None, obj)
            self.assertTrue(
                has_permission,
                f"Coach should have POST permission on {obj.__class__.__name__}",
            )

    def test_post_method_for_player(self):
        """Players cannot create objects."""
        request = self.factory.post("/test/")
        request.user = self.player

        # Test with different object types
        for obj in [self.game, self.play, self.event, self.possession]:
            has_permission = self.permission.has_object_permission(request, None, obj)
            self.assertFalse(
                has_permission,
                f"Player should not have POST permission on {obj.__class__.__name__}",
            )

    def test_post_method_for_other_coach(self):
        """Other coaches cannot create objects for teams they don't coach."""
        request = self.factory.post("/test/")
        request.user = self.other_coach

        # Test with different object types
        for obj in [self.game, self.play, self.event, self.possession]:
            has_permission = self.permission.has_object_permission(request, None, obj)
            self.assertFalse(
                has_permission,
                f"Other coach should not have POST permission on {obj.__class__.__name__}",
            )

    def test_put_patch_delete_for_coach(self):
        """Coaches can update/delete objects for their team."""
        for method in ["PUT", "PATCH", "DELETE"]:
            request = self.factory.generic(method, "/test/")
            request.user = self.coach

            # Test with different object types
            for obj in [self.game, self.play, self.event, self.possession]:
                has_permission = self.permission.has_object_permission(
                    request, None, obj
                )
                self.assertTrue(
                    has_permission,
                    f"Coach should have {method} permission on {obj.__class__.__name__}",
                )

    def test_put_patch_delete_for_player(self):
        """Players cannot update/delete objects."""
        for method in ["PUT", "PATCH", "DELETE"]:
            request = self.factory.generic(method, "/test/")
            request.user = self.player

            # Test with different object types
            for obj in [self.game, self.play, self.event, self.possession]:
                has_permission = self.permission.has_object_permission(
                    request, None, obj
                )
                self.assertFalse(
                    has_permission,
                    f"Player should not have {method} permission on {obj.__class__.__name__}",
                )

    def test_competition_creator_permissions(self):
        """Competition creator has full permissions."""
        for method in ["PUT", "PATCH", "DELETE"]:
            request = self.factory.generic(method, "/test/")
            request.user = self.coach  # Creator

            has_permission = self.permission.has_object_permission(
                request, None, self.competition
            )
            self.assertTrue(
                has_permission,
                f"Creator should have {method} permission on competition",
            )

    def test_competition_non_creator_permissions(self):
        """Non-creators cannot modify competitions."""
        for method in ["PUT", "PATCH", "DELETE"]:
            request = self.factory.generic(method, "/test/")
            request.user = self.other_coach  # Non-creator

            has_permission = self.permission.has_object_permission(
                request, None, self.competition
            )
            self.assertFalse(
                has_permission,
                f"Non-creator should not have {method} permission on competition",
            )

    def test_user_self_update_permission(self):
        """Users can update their own profiles."""
        request = self.factory.patch("/test/")
        request.user = self.player

        has_permission = self.permission.has_object_permission(
            request, None, self.player
        )
        self.assertTrue(
            has_permission, "User should be able to update their own profile"
        )

    def test_user_other_update_permission(self):
        """Users cannot update other users' profiles."""
        request = self.factory.patch("/test/")
        request.user = self.player

        has_permission = self.permission.has_object_permission(
            request, None, self.coach
        )
        self.assertFalse(
            has_permission, "User should not be able to update other users' profiles"
        )

    def test_coach_update_team_member_permission(self):
        """Coaches can update team member profiles."""
        request = self.factory.patch("/test/")
        request.user = self.coach

        has_permission = self.permission.has_object_permission(
            request, None, self.player
        )
        self.assertTrue(
            has_permission, "Coach should be able to update team member profiles"
        )

    def test_coach_update_non_team_member_permission(self):
        """Coaches cannot update non-team member profiles."""
        request = self.factory.patch("/test/")
        request.user = self.coach

        has_permission = self.permission.has_object_permission(
            request, None, self.other_player
        )
        self.assertFalse(
            has_permission,
            "Coach should not be able to update non-team member profiles",
        )

    def test_anonymous_user_permissions(self):
        """Anonymous users have no permissions."""
        request = self.factory.get("/test/")
        request.user = AnonymousUser()

        for obj in [
            self.game,
            self.play,
            self.event,
            self.competition,
            self.possession,
        ]:
            has_permission = self.permission.has_object_permission(request, None, obj)
            self.assertFalse(
                has_permission,
                f"Anonymous user should not have permissions on {obj.__class__.__name__}",
            )

    def test_unsupported_object_type(self):
        """Test with unsupported object type."""
        request = self.factory.get("/test/")
        request.user = self.coach

        unsupported_obj = Team(name="Test")  # Team is not in the permission logic

        has_permission = self.permission.has_object_permission(
            request, None, unsupported_obj
        )
        self.assertFalse(
            has_permission, "Unsupported object types should not have permissions"
        )

    def test_possession_with_team_id_in_data(self):
        """Test possession creation with team_id in request data."""
        request = self.factory.post("/test/")
        request.user = self.coach
        request.data = {"team_id": self.team.id}

        has_permission = self.permission.has_object_permission(
            request, None, self.possession
        )
        self.assertTrue(
            has_permission, "Coach should have permission when team_id is provided"
        )

    def test_possession_with_team_in_data(self):
        """Test possession creation with team in request data."""
        request = self.factory.post("/test/")
        request.user = self.coach
        request.data = {"team": self.team.id}

        has_permission = self.permission.has_object_permission(
            request, None, self.possession
        )
        self.assertTrue(
            has_permission, "Coach should have permission when team is provided"
        )
