import django_filters
from apps.users.models import User


class UserFilter(django_filters.FilterSet):
    class Meta:
        model = User
        fields = {
            "username": ["exact", "icontains"],
            "email": ["exact", "icontains"],
            "first_name": ["exact", "icontains"],
            "last_name": ["exact", "icontains"],
            "role": ["exact"],
            "is_active": ["exact"],
        }
