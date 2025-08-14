# apps/possessions/serializers.py
from rest_framework import serializers
from .models import Possession

class PossessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Possession
        fields = '__all__' # Include all fields