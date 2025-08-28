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
    created_by = UserSerializer(read_only=True)  # Also serialize the creator

    class Meta:
        model = Team
        fields = ["id", "name", "created_by", "players", "coaches", "competition"]

    def to_representation(self, instance):
        """
        This method is the final step before turning data into JSON.
        We will override it to manually fetch and serialize the members,
        ensuring the complete, correct data is always included.
        """
        # Start with the default representation (for fields like 'id' and 'name')
        representation = super().to_representation(instance)

        # print(f"Instance: {instance}")

        # Manually fetch all coaches and players from the database for this team instance
        coaches_queryset = instance.coaches.all()
        players_queryset = instance.players.all()

        # print(f"Serializing team: {instance.name}")
        # print(f"Coaches found MANUALLY: {list(coaches_queryset)}")
        # print(f"Players found MANUALLY: {list(players_queryset)}")

        # Serialize the querysets using the UserSerializer
        representation["coaches"] = UserSerializer(coaches_queryset, many=True).data
        representation["players"] = UserSerializer(players_queryset, many=True).data

        return representation
