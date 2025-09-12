from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.teams.models import Team
from apps.competitions.models import Competition
from apps.plays.models import PlayCategory, PlayDefinition
import os
import json

User = get_user_model()


class Command(BaseCommand):
    help = "Test loading play definitions from JSON file"

    def handle(self, *args, **options):
        self.stdout.write("Testing play definitions loading...")

        # Create admin user
        admin_user, created = User.objects.get_or_create(
            username="admin",
            defaults={
                "first_name": "Admin",
                "last_name": "User",
                "email": "admin@example.com",
                "is_staff": True,
                "is_superuser": True,
            },
        )

        # Create a default team for generic play templates
        default_team, _ = Team.objects.get_or_create(
            name="Default Play Templates",
            defaults={
                "created_by": admin_user,
                "competition": Competition.objects.first(),
            },
        )

        # Clear existing play definitions for the default team
        PlayCategory.objects.all().delete()
        PlayDefinition.objects.filter(team=default_team).delete()

        # Path to the JSON fixture file
        json_path = os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "..",
            "..",
            "data",
            "initial_play_definitions.json",
        )

        if not os.path.exists(json_path):
            self.stdout.write(
                self.style.ERROR(f"Play definitions file not found at: {json_path}")
            )
            return

        self.stdout.write(f"Using play definitions from: {json_path}")
        
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            total_plays_created = 0
            skipped_control_plays = 0

            for category_data in data:
                category_name = category_data["category"]
                
                # Skip Control category as requested
                if category_name == "Control":
                    skipped_control_plays = len(category_data["plays"])
                    self.stdout.write(f"  - Skipping Control category ({skipped_control_plays} plays)")
                    continue

                category, _ = PlayCategory.objects.get_or_create(name=category_name)

                for play_data in category_data["plays"]:
                    # Determine play type based on category
                    play_type = "NEUTRAL"  # Default
                    if "Defense" in category_name:
                        play_type = "DEFENSIVE"
                    elif "Offense" in category_name:
                        play_type = "OFFENSIVE"
                    elif category_name in ["Transition", "Set"]:
                        play_type = "OFFENSIVE"
                    elif category_name in ["Zone", "Press"]:
                        play_type = "DEFENSIVE"
                    elif category_name == "Players":
                        play_type = "NEUTRAL"
                    elif category_name == "Outcome":
                        play_type = "NEUTRAL"
                    elif category_name == "Shoot":
                        play_type = "NEUTRAL"
                    elif category_name == "Tag Offensive Rebound":
                        play_type = "NEUTRAL"
                    elif category_name == "Advanced":
                        play_type = "NEUTRAL"

                    # Create play definition
                    play_def, created = PlayDefinition.objects.get_or_create(
                        name=play_data["name"],
                        team=default_team,
                        defaults={
                            "category": category,
                            "subcategory": play_data.get("subcategory"),
                            "action_type": play_data.get("action_type", "NORMAL"),
                            "play_type": play_type,
                            "description": f"Generic {play_data['name']} play from {category_name}",
                        },
                    )

                    if created:
                        total_plays_created += 1
                        self.stdout.write(f"  - Created play: {play_data['name']} ({play_type})")

            self.stdout.write(
                f"✓ Loaded {total_plays_created} play definitions (skipped {skipped_control_plays} Control plays)"
            )

            # Show some statistics
            offensive_plays = PlayDefinition.objects.filter(play_type="OFFENSIVE").count()
            defensive_plays = PlayDefinition.objects.filter(play_type="DEFENSIVE").count()
            neutral_plays = PlayDefinition.objects.filter(play_type="NEUTRAL").count()
            
            self.stdout.write(f"  - Offensive plays: {offensive_plays}")
            self.stdout.write(f"  - Defensive plays: {defensive_plays}")
            self.stdout.write(f"  - Neutral plays: {neutral_plays}")

        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error loading play definitions: {e}"))
