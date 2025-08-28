# backend/apps/users/management/commands/populate_db.py

import datetime
import json
import os
import random
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.db import transaction

# Import all necessary models
from apps.competitions.models import Competition
from apps.teams.models import Team
from apps.games.models import Game
from apps.plays.models import PlayCategory, PlayDefinition
from apps.events.models import CalendarEvent
from apps.possessions.models import Possession

User = get_user_model()


class Command(BaseCommand):
    help = "Populates the database with a large, realistic set of NBB league data."

    @transaction.atomic
    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.SUCCESS("--- Starting Database Population ---"))

        # --- 1. CLEAN UP OLD DATA ---
        self.stdout.write("Deleting old data...")
        Possession.objects.all().delete()
        CalendarEvent.objects.all().delete()
        Game.objects.all().delete()
        PlayDefinition.objects.all().delete()
        PlayCategory.objects.all().delete()
        Team.objects.all().delete()
        Competition.objects.all().delete()
        User.objects.filter(is_superuser=False).delete()
        self.stdout.write("Old data deleted.")

        # --- 2. GET SUPERUSER ---
        superuser = User.objects.filter(is_superuser=True).order_by("pk").first()
        if not superuser:
            self.stdout.write(
                self.style.ERROR(
                    'FATAL: No superuser found. Please create one first with "python manage.py createsuperuser".'
                )
            )
            return

        # --- 3. CREATE COMPETITION ---
        self.stdout.write("Creating NBB Competition...")
        nbb_competition, _ = Competition.objects.get_or_create(
            name="Novo Basquete Brasil",
            defaults={"season": "2025-2026", "created_by": superuser},
        )

        # --- 4. CREATE NBB TEAMS, COACHES, AND PLAYERS ---
        self.stdout.write("Creating 18 NBB teams, 18 coaches, and 360 players...")

        nbb_teams_data = [
            # {'name': 'Bauru Basket', 'full_name': 'Zopone/Unimed/Bauru Basket'},
            # {'name': 'Botafogo', 'full_name': 'Botafogo'},
            # {'name': 'Brasília Basquete', 'full_name': 'CAIXA/Brasília Basquete'},
            # {'name': 'Caxias do Sul', 'full_name': 'Caxias do Sul Basquete'},
            {"name": "Corinthians", "full_name": "Sport Club Corinthians Paulista"},
            {"name": "Flamengo", "full_name": "Clube de Regatas do Flamengo"},
            {"name": "Fortaleza B.C.", "full_name": "Fortaleza Basquete Cearense/CFO"},
            # {'name': 'Sesi Franca', 'full_name': 'Franca Basquete'},
            # {'name': 'Minas', 'full_name': 'KTO Minas'},
            # {'name': 'Mogi Basquete', 'full_name': 'Desk Manager Mogi Basquete'},
            {
                "name": "Pato Basquete",
                "full_name": "Associação Basquetebol Arte de Pato Branco",
            },
            # {'name': 'Paulistano', 'full_name': 'Paulistano/Corpore'},
            # {'name': 'Pinheiros', 'full_name': 'Esporte Clube Pinheiros'},
            # {'name': 'São José', 'full_name': 'Farma Conde/São José Basketball'},
            {"name": "São Paulo", "full_name": "São Paulo Futebol Clube"},
            # {'name': 'União Corinthians', 'full_name': 'Ceisc/União Corinthians'},
            # {'name': 'Unifacisa', 'full_name': 'Unifacisa'},
            {"name": "Vasco da Gama", "full_name": "R10 Score Vasco da Gama"},
        ]

        all_teams = []
        player_counter = 1
        for i, team_data in enumerate(nbb_teams_data):
            # Create a unique coach for each team
            coach = User.objects.create_user(
                username=f"coach_{i+1}",
                password="password",
                first_name=f'Coach_{team_data["name"]}',
                last_name="User",
                role=User.Role.COACH,
                coach_type="HEAD_COACH",
            )

            team = Team.objects.create(
                name=team_data["name"],
                competition=nbb_competition,
                created_by=superuser,
                logo_url="https://via.placeholder.com/100",
            )

            team.coaches.add(coach)

            # Create and assign 20 players to this team
            team_players = []
            for j in range(20):
                player = User.objects.create_user(
                    username=f"player{player_counter}",
                    password="password",
                    first_name=f"Player",
                    last_name=f"{player_counter}",
                    role=User.Role.PLAYER,
                    jersey_number=random.randint(0, 99),
                )
                team_players.append(player)
                player_counter += 1
            team.players.set(team_players)
            all_teams.append(team)
            self.stdout.write(
                f"  - Created team: {team.name} with 1 coach and 20 players."
            )

        # --- 5. LOAD PLAY DEFINITIONS FROM JSON ---
        self.stdout.write("Loading generic play definitions...")
        default_team, _ = Team.objects.get_or_create(
            name="Default Play Templates",
            defaults={"competition": nbb_competition, "created_by": superuser},
        )

        PlayCategory.objects.all().delete()
        PlayDefinition.objects.filter(team=default_team).delete()

        json_path = os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "..",
            "plays",
            "fixtures",
            "initial_play_definitions.json",
        )
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        for category_data in data:
            category, _ = PlayCategory.objects.get_or_create(
                name=category_data["category"]
            )
            for play_data in category_data["plays"]:
                # Use get_or_create to avoid creating duplicates for the same team.
                # It looks for a play with this name and team.
                # If it exists, it does nothing.
                # If it doesn't exist, it creates it using the 'defaults'.
                play_def, created = PlayDefinition.objects.get_or_create(
                    name=play_data["name"],
                    team=default_team,
                    defaults={
                        "category": category,
                        "subcategory": play_data.get("subcategory"),
                        "action_type": play_data.get("action_type", "NORMAL"),
                        "play_type": "OFFENSIVE",  # A sensible default
                    },
                )
        self.stdout.write("Play definitions loaded.")

        # --- 6. CREATE SAMPLE GAMES ---
        self.stdout.write("Creating sample games...")
        game1 = Game.objects.create(
            competition=nbb_competition,
            home_team=all_teams[0],
            away_team=all_teams[1],
            game_date=datetime.date.today() - datetime.timedelta(days=7),
            home_team_score=102,
            away_team_score=95,
        )
        game2 = Game.objects.create(
            competition=nbb_competition,
            home_team=all_teams[2],
            away_team=all_teams[3],
            game_date=datetime.date.today() - datetime.timedelta(days=5),
        )
        game3 = Game.objects.create(
            competition=nbb_competition,
            home_team=all_teams[4],
            away_team=all_teams[5],
            game_date=datetime.date.today() - datetime.timedelta(days=1),
        )

        # --- 7. CREATE SAMPLE POSSESSIONS ---
        self.stdout.write("Creating sample possessions for games...")
        outcomes = [choice[0] for choice in Possession.OutcomeChoices.choices]
        for game in [game1, game2, game3]:
            for i in range(
                random.randint(15, 30)
            ):  # Create a random number of possessions
                possession_team = random.choice([game.home_team, game.away_team])
                opponent_team = (
                    game.away_team
                    if possession_team == game.home_team
                    else game.home_team
                )
                quarter = random.randint(1, 4)

                Possession.objects.create(
                    game=game,
                    team=possession_team,
                    opponent=opponent_team,
                    quarter=quarter,
                    start_time_in_game=f"{random.randint(0,11):02}:{random.randint(0,59):02}",
                    duration_seconds=random.randint(5, 24),
                    offensive_sequence="Sample / PnR / Kick Out",
                    defensive_sequence="Sample / Hedge",
                    outcome=random.choice(outcomes),
                    logged_by=superuser,
                )

        self.stdout.write(self.style.SUCCESS("--- Database Population Complete! ---"))
