# apps/users/serializers.py

from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        # Fields to include in the API response
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'role', 'coach_type', 'jersey_number']

class CoachUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        # Define ONLY the fields a coach can change about another coach/themselves
        fields = ['first_name', 'last_name', 'coach_type']

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})

    class Meta:
        model = User
        fields = ('username', 'password', 'email', 'first_name', 'last_name', 'role', 'coach_type')

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role=validated_data.get('role', User.Role.PLAYER),
            coach_type=validated_data.get('coach_type', User.CoachType.NONE)
        )
        user.set_password(validated_data['password'])
        user.save()
        return user