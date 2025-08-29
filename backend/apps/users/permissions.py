from rest_framework.permissions import BasePermission, SAFE_METHODS
from django.db.models import Q
from django.contrib.auth import get_user_model
from apps.teams.models import Team

User = get_user_model()


class IsTeamScopedObject(BasePermission):
    message = "You do not have permission to access this resource."

    def has_permission(self, request, view) -> bool:
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        # Safe methods always allowed; object-level will further restrict
        if request.method in SAFE_METHODS:
            return True

        # Handle create-level checks for some resources where team is in payload
        data = request.data or {}
        # If creating a resource tied to a team, require the requester to be a coach on that team
        team_id = data.get("team")
        if team_id:
            return Team.objects.filter(id=team_id, coaches=user).exists()
        # Game create may specify home/away teams; require coaching at least one
        home_team_id = data.get("home_team")
        away_team_id = data.get("away_team")
        if home_team_id or away_team_id:
            return Team.objects.filter(
                Q(id=home_team_id) | Q(id=away_team_id), coaches=user
            ).exists()
        # For other cases without object context, allow and defer to object-level checks
        return True

    def has_object_permission(self, request, view, obj) -> bool:
        user = request.user
        if not user.is_authenticated:
            return False
        if user.is_superuser:
            return True

        # Reads are allowed if user is related to the object's team(s) (checked below)
        # Writes are limited (coach-only, or other special cases)
        is_safe = request.method in SAFE_METHODS

        # User objects: allow self updates; otherwise require coach and team overlap
        if isinstance(obj, User):
            if obj.id == user.id:
                return True
            if not is_safe:
                # Must be a coach and share at least one team with the target
                coach_teams = Team.objects.filter(coaches=user)
                return Team.objects.filter(
                    Q(players=obj) | Q(coaches=obj), id__in=coach_teams.values("id")
                ).exists()
            # For reads, allow if they share a team
            return Team.objects.filter(
                Q(players=user) | Q(coaches=user), Q(players=obj) | Q(coaches=obj)
            ).exists()

        # Competition objects: only creator can modify; reads allowed to authenticated users
        try:
            from apps.competitions.models import (
                Competition,
            )  # local import to avoid cycles

            if isinstance(obj, Competition):
                return is_safe or (obj.created_by_id == user.id)
        except Exception:
            pass

        # Derive related team ids for generic team-scoped objects
        team_ids = set()
        # Common relations
        if hasattr(obj, "team_id") and obj.team_id:
            team_ids.add(obj.team_id)
        if (
            hasattr(obj, "team")
            and getattr(obj, "team", None) is not None
            and hasattr(obj.team, "id")
        ):
            team_ids.add(obj.team.id)
        if hasattr(obj, "home_team_id") and obj.home_team_id:
            team_ids.add(obj.home_team_id)
        if hasattr(obj, "away_team_id") and obj.away_team_id:
            team_ids.add(obj.away_team_id)
        if hasattr(obj, "opponent_id") and obj.opponent_id:
            team_ids.add(obj.opponent_id)

        if not team_ids:
            # If object doesn't relate to a team, allow safe reads only
            return is_safe

        is_member = Team.objects.filter(
            Q(id__in=team_ids)
            & (Q(players=user) | Q(coaches=user) | Q(created_by=user))
        ).exists()

        if not is_member:
            return False

        # For writes, require that the user is a coach on at least one related team
        if not is_safe:
            return Team.objects.filter(id__in=team_ids, coaches=user).exists()

        return True
