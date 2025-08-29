import django_filters
from apps.games.models import Game


class GameFilter(django_filters.FilterSet):
    class Meta:
        model = Game
        fields = {
            "competition": ["exact"],
            "home_team": ["exact"],
            "away_team": ["exact"],
            "game_date": ["exact", "gte", "lte", "date__gte", "date__lte"],
        }
