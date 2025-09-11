# apps/plays/serializers.py
from rest_framework import serializers
from .models import PlayDefinition, PlayCategory, PlayStep


class PlayCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = PlayCategory
        fields = ["id", "name", "description"]


class PlayStepSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlayStep
        fields = ["id", "order", "title", "description", "diagram", "duration"]


class PlayDefinitionSerializer(serializers.ModelSerializer):
    # This ensures the nested category object is serialized correctly
    category = PlayCategorySerializer(read_only=True)
    steps = PlayStepSerializer(many=True, read_only=True)
    created_by_name = serializers.CharField(source="created_by.get_full_name", read_only=True)

    category_id = serializers.PrimaryKeyRelatedField(
        queryset=PlayCategory.objects.all(),
        source="category",
        write_only=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model = PlayDefinition
        fields = [
            "id",
            "name",
            "description",
            "play_type",
            "team",
            "parent",
            "category",
            "subcategory",
            "action_type",
            "diagram_url",
            "video_url",
            "tags",
            "difficulty",
            "duration",
            "players",
            "success_rate",
            "last_used",
            "is_favorite",
            "created_by",
            "created_by_name",
            "steps",
            "category_id",
        ]
        read_only_fields = ["created_by"]
