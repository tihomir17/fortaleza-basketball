from django.contrib import admin
from .models import Competition

# Create an interface for the Competition model.
admin.site.register(Competition)
