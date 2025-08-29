import django_filters
from apps.events.models import CalendarEvent


class CalendarEventFilter(django_filters.FilterSet):
    class Meta:
        model = CalendarEvent
        fields = {
            "team": ["exact"],
            "event_type": ["exact"],
            "start_time": ["exact", "gte", "lte"],
            "end_time": ["exact", "gte", "lte"],
        }
