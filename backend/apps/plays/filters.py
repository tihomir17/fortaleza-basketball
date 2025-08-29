import django_filters
from apps.plays.models import PlayCategory, PlayDefinition


class PlayCategoryFilter(django_filters.FilterSet):
    class Meta:
        model = PlayCategory
        fields = {
            "name": ["exact", "icontains"],
        }


class PlayDefinitionFilter(django_filters.FilterSet):
    class Meta:
        model = PlayDefinition
        fields = {
            "name": ["exact", "icontains"],
            "play_type": ["exact"],
            "team": ["exact"],
            "category": ["exact"],
            "action_type": ["exact"],
        }
