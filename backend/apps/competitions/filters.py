import django_filters  # pyright: ignore[reportMissingImports]
from apps.competitions.models import Competition


class CompetitionFilter(django_filters.FilterSet):
    class Meta:
        model = Competition
        fields = {
            "name": ["exact", "icontains"],
            "season": ["exact", "icontains"],
        }
