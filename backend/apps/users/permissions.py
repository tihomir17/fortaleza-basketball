from rest_framework.permissions import BasePermission, SAFE_METHODS
from django.db.models import Q
from apps.teams.models import Team

class IsTeamScopedObject(BasePermission):
    message = "You do not have permission to access this object."

    def has_object_permission(self, request, view, obj) -> bool:
        user = request.user
        if not user.is_authenticated:
            return False
        if user.is_superuser:
            return True

        # Determine the object's team(s) and check membership
        team_ids = set()
        # Common relations
        if hasattr(obj, 'team_id') and obj.team_id:
            team_ids.add(obj.team_id)
        if hasattr(obj, 'team') and getattr(obj, 'team', None) is not None and hasattr(obj.team, 'id'):
            team_ids.add(obj.team.id)
        if hasattr(obj, 'home_team_id') and obj.home_team_id:
            team_ids.add(obj.home_team_id)
        if hasattr(obj, 'away_team_id') and obj.away_team_id:
            team_ids.add(obj.away_team_id)
        if hasattr(obj, 'opponent_id') and obj.opponent_id:
            team_ids.add(obj.opponent_id)

        if not team_ids:
            # If object doesn't relate to a team, allow safe reads only
            return request.method in SAFE_METHODS

        is_member = Team.objects.filter(
            Q(id__in=team_ids) & (Q(players=user) | Q(coaches=user) | Q(created_by=user))
        ).exists()
        return is_member
