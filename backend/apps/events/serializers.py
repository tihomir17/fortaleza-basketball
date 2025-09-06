# apps/events/serializers.py
from rest_framework import serializers
from .models import CalendarEvent


class CalendarEventListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for calendar event lists"""
    class Meta:
        model = CalendarEvent
        fields = [
            "id",
            "title",
            "event_type",
            "start_time",
            "end_time",
            "team",
        ]


class CalendarEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = CalendarEvent
        fields = "__all__"
        read_only_fields = ["created_by"]
