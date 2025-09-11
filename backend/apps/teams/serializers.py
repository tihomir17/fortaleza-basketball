# apps/teams/serializers.py
from rest_framework import serializers
from .models import Team
from apps.users.serializers import UserSerializer


class TeamWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Team
        fields = ["name", "competition"]  # The user only provides the name.


class TeamReadSerializer(serializers.ModelSerializer):
    # We declare these so DRF knows about them, but they will be
    # populated by our custom to_representation method.
    players = UserSerializer(many=True, read_only=True)
    coaches = UserSerializer(many=True, read_only=True)
    staff = UserSerializer(many=True, read_only=True)
    created_by = UserSerializer(read_only=True)  # Also serialize the creator
    
    # Add computed fields for member counts
    player_count = serializers.SerializerMethodField()
    coach_count = serializers.SerializerMethodField()
    staff_count = serializers.SerializerMethodField()
    total_members = serializers.SerializerMethodField()

    class Meta:
        model = Team
        fields = [
            "id", "name", "created_by", "players", "coaches", "staff", "competition",
            "player_count", "coach_count", "staff_count", "total_members", "logo_url"
        ]

    def get_player_count(self, obj):
        return obj.players.count()

    def get_coach_count(self, obj):
        return obj.coaches.count()

    def get_staff_count(self, obj):
        return obj.staff.count()

    def get_total_members(self, obj):
        return obj.players.count() + obj.coaches.count() + obj.staff.count()

    def to_representation(self, instance):
        """
        This method is the final step before turning data into JSON.
        We will override it to manually fetch and serialize the members,
        ensuring the complete, correct data is always included.
        """
        # Start with the default representation (for fields like 'id' and 'name')
        representation = super().to_representation(instance)

        # Manually fetch all coaches, staff, and players from the database for this team instance
        # Order coaches so HEAD_COACH appears first, then ASSISTANT_COACH
        coaches_queryset = instance.coaches.all().order_by(
            'coach_type'  # This will put HEAD_COACH first, then ASSISTANT_COACH
        )
        staff_queryset = instance.staff.all()
        players_queryset = instance.players.all().order_by('jersey_number', 'first_name', 'last_name')

        # Serialize the querysets using the UserSerializer
        representation["coaches"] = UserSerializer(coaches_queryset, many=True).data
        representation["staff"] = UserSerializer(staff_queryset, many=True).data
        representation["players"] = UserSerializer(players_queryset, many=True).data

        return representation
