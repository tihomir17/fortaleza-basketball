from django.apps import AppConfig


class CompetitionManagementConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.competition_management"

    def ready(self):
        import apps.competition_management.admin_config
