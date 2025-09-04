from django.urls import path
from . import views

app_name = "scouting"

urlpatterns = [
    path("self_scouting/", views.self_scouting, name="self_scouting"),
]
