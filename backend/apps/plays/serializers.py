# apps/plays/serializers.py
from rest_framework import serializers
from .models import PlayDefinition

class PlayDefinitionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlayDefinition
        fields = '__all__' # Include all fields