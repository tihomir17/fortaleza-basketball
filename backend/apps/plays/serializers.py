# apps/plays/serializers.py
from rest_framework import serializers
from .models import PlayDefinition

class PlayDefinitionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlayDefinition
        # '__all__' will automatically include our new 'parent' field
        fields = '__all__'