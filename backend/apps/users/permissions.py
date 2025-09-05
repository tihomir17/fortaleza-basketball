from rest_framework.permissions import (
    BasePermission,
    SAFE_METHODS,
)  # pyright: ignore[reportMissingImports]
from django.db.models import Q  # pyright: ignore[reportMissingImports]
from django.contrib.auth import get_user_model  # pyright: ignore[reportMissingImports]
from apps.teams.models import Team

User = get_user_model()


def has_admin_rights(user):
    """Check if user has admin rights (Head Coach or Assistant Coach)"""
    if not user or not user.is_authenticated:
        return False
    if user.is_superuser:
        return True
    if user.role == User.Role.ADMIN:
        return True
    if user.role == User.Role.COACH and user.coach_type in [User.CoachType.HEAD_COACH, User.CoachType.ASSISTANT_COACH]:
        return True
    return False


class IsTeamScopedObject(BasePermission):
    message = "You do not have permission to access this resource."

    def has_permission(self, request, view) -> bool:
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        if request.method in SAFE_METHODS:
            return True

        # Check if this is a competition creation
        if (
            hasattr(view, "get_queryset")
            and "competition" in str(view.get_queryset().model).lower()
        ):
            # For competitions, only coaches can create
            return user.role == User.Role.COACH

        data = request.data or {}
        # Accept team or team_id
        team_id = data.get("team_id") or data.get("team")
        if team_id:
            return Team.objects.filter(id=team_id, coaches=user).exists()
        home_team_id = data.get("home_team")
        away_team_id = data.get("away_team")
        if home_team_id or away_team_id:
            return Team.objects.filter(
                Q(id=home_team_id) | Q(id=away_team_id), coaches=user
            ).exists()
        return True

    def has_object_permission(self, request, view, obj) -> bool:
        user = request.user
        if not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        is_safe = request.method in SAFE_METHODS

        # Team objects: writes allowed to coaches/creator; reads allowed to members
        if isinstance(obj, Team):
            if is_safe:
                return Team.objects.filter(
                    Q(id=obj.id)
                    & (Q(players=user) | Q(coaches=user) | Q(created_by=user))
                ).exists()
            return (
                obj.coaches.filter(id=user.id).exists() or obj.created_by_id == user.id
            )

        # User objects
        if isinstance(obj, User):
            if obj.id == user.id:
                return True
            if not is_safe:
                coach_teams = Team.objects.filter(coaches=user)
                return Team.objects.filter(
                    Q(players=obj) | Q(coaches=obj), id__in=coach_teams.values("id")
                ).exists()
            return Team.objects.filter(
                Q(players=user) | Q(coaches=user), Q(players=obj) | Q(coaches=obj)
            ).exists()

        # Competition objects: only creator can modify; reads allowed
        try:
            from apps.competitions.models import (
                Competition,
            )  # local import to avoid cycles

            if isinstance(obj, Competition):
                return is_safe or (obj.created_by_id == user.id)
        except Exception:
            pass

        team_ids = set()
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
            return is_safe

        is_member = Team.objects.filter(
            Q(id__in=team_ids)
            & (Q(players=user) | Q(coaches=user) | Q(created_by=user))
        ).exists()
        if not is_member:
            return False
        if not is_safe:
            return Team.objects.filter(id__in=team_ids, coaches=user).exists()
        return True
