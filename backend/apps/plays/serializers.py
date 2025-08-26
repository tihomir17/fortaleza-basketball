# apps/plays/serializers.py
from rest_framework import serializers
from .models import PlayDefinition, PlayCategory


class PlayCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = PlayCategory
        fields = ["id", "name", "description"]


class PlayDefinitionSerializer(serializers.ModelSerializer):
    # When we READ a play, we want to see the full category object
    category = PlayCategorySerializer(read_only=True)
    # When we WRITE a play, we'll send the integer ID for the category
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=PlayCategory.objects.all(),
        source="category",
        write_only=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model = PlayDefinition
        # Add the new fields to the list
        fields = [
            "id",
            "name",
            "description",
            "play_type",
            "team",
            "parent",
            "category",
            "subcategory",
            "category_id",
        ]
