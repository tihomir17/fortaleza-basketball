from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from .models import Game
from .serializers import GameReadSerializer, GameWriteSerializer


class GameViewSet(viewsets.ModelViewSet):
    queryset = Game.objects.all().order_by("-game_date")
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        """
        Use the 'Write' serializer for creating/updating,
        and the 'Read' serializer for viewing.
        """
        if self.action in ["create", "update", "partial_update"]:
            return GameWriteSerializer
        return GameReadSerializer

    def create(self, request, *args, **kwargs):
        """
        Custom create action to ensure the response uses the ReadSerializer.
        """
        # Use the 'Write' serializer to validate the incoming data
        write_serializer = self.get_serializer(data=request.data)
        write_serializer.is_valid(raise_exception=True)

        # self.perform_create saves the object and returns the model instance
        instance = self.perform_create(write_serializer)

        # Now, create a 'Read' serializer using the new instance to generate the response
        read_serializer = GameReadSerializer(
            instance, context=self.get_serializer_context()
        )

        headers = self.get_success_headers(read_serializer.data)
        # Return the data from the 'Read' serializer, which contains the full nested objects
        return Response(
            read_serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )

    def perform_create(self, serializer):
        """
        This hook is called by 'create' and just saves the instance.
        """
        return serializer.save()
