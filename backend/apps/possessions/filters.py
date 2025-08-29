import django_filters
from apps.possessions.models import Possession


class PossessionFilter(django_filters.FilterSet):
    class Meta:
        model = Possession
        fields = {
            "game": ["exact"],
            "team": ["exact"],
            "opponent": ["exact"],
            "quarter": ["exact"],
            "outcome": ["exact"],
            "start_time_in_game": ["exact", "gte", "lte"],
            "duration_seconds": ["exact", "gte", "lte"],
            "logged_by": ["exact"],
        }
