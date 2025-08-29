# apps/plays/serializers.py
from rest_framework import serializers
from .models import PlayDefinition, PlayCategory


class PlayCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = PlayCategory
        fields = ["id", "name", "description"]


# The PlayDefinitionSerializer is likely already correct
class PlayDefinitionSerializer(serializers.ModelSerializer):
    # This ensures the nested category object is serialized correctly
    category = PlayCategorySerializer(read_only=True)

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
            "category_id",
        ]
