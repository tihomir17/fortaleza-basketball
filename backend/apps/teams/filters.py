import django_filters
from apps.teams.models import Team


class TeamFilter(django_filters.FilterSet):
    class Meta:
        model = Team
        fields = {
            "name": ["exact", "icontains"],
            "competition": ["exact"],
            "created_by": ["exact"],
        }
