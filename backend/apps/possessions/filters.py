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
            "created_by": ["exact"],
            "points_scored": ["exact", "gte", "lte"],
            "offensive_set": ["exact"],
            "pnr_type": ["exact"],
            "pnr_result": ["exact"],
            "has_paint_touch": ["exact"],
            "has_kick_out": ["exact"],
            "has_extra_pass": ["exact"],
            "number_of_passes": ["exact", "gte", "lte"],
            "is_offensive_rebound": ["exact"],
            "offensive_rebound_count": ["exact", "gte", "lte"],
            "defensive_set": ["exact"],
            "defensive_pnr": ["exact"],
            "box_out_count": ["exact", "gte", "lte"],
            "offensive_rebounds_allowed": ["exact", "gte", "lte"],
            "shoot_time": ["exact"],
            "shoot_quality": ["exact"],
            "time_range": ["exact"],
            "after_timeout": ["exact"],
            "players_on_court": ["exact"],
            "offensive_rebound_players": ["exact"],
        }
