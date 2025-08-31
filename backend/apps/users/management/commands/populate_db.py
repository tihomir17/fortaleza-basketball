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

    def load_play_definitions(self):
        """Load play definitions from JSON file and organize them by category."""
        json_path = os.path.join(
            os.path.dirname(__file__),
            "..",
            "..",
            "..",
            "..",
            "data",
            "initial_play_definitions.json",
        )

        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        # Organize plays by category
        plays_by_category = {}
        for category_data in data:
            category_name = category_data["category"]
            plays_by_category[category_name] = []
            for play_data in category_data["plays"]:
                plays_by_category[category_name].append(play_data["name"])

        return plays_by_category

    def generate_offensive_sequence(self, plays_by_category):
        """Generate realistic offensive sequence using play definitions."""
        sequence_parts = []

        # Start with quarter
        quarter = random.randint(1, 4)
        sequence_parts.append(f"Q{quarter}")

        # Add defensive pressure (from Defense category)
        if "Defense" in plays_by_category:
            defensive_pressures = [
                play
                for play in plays_by_category["Defense"]
                if any(keyword in play.lower() for keyword in ["press", "court"])
            ]
            if defensive_pressures:
                sequence_parts.append(random.choice(defensive_pressures))

        # Add defensive formation (from Defense category)
        if "Defense" in plays_by_category:
            defensive_formations = [
                play
                for play in plays_by_category["Defense"]
                if any(
                    keyword in play.lower()
                    for keyword in ["2-3", "3-2", "1-3-1", "1-2-2", "zone"]
                )
            ]
            if defensive_formations:
                sequence_parts.append(random.choice(defensive_formations))

        # Add offensive set (from Offense category)
        if "Offense" in plays_by_category:
            offensive_sets = [
                play for play in plays_by_category["Offense"] if play.startswith("Set")
            ]
            if offensive_sets:
                sequence_parts.append(random.choice(offensive_sets))

        # Add offensive half court action (from Offense Half Court category)
        if "Offense Half Court" in plays_by_category:
            half_court_actions = plays_by_category["Offense Half Court"]
            if half_court_actions:
                sequence_parts.append(random.choice(half_court_actions))

        # Add shot type (from Outcome category)
        if "Outcome" in plays_by_category:
            shot_types = [
                play
                for play in plays_by_category["Outcome"]
                if any(
                    keyword in play.lower()
                    for keyword in ["2pt", "3pt", "lay up", "shot"]
                )
            ]
            if shot_types:
                sequence_parts.append(random.choice(shot_types))

        # Add shot result (from Outcome category)
        if "Outcome" in plays_by_category:
            shot_results = [
                play
                for play in plays_by_category["Outcome"]
                if any(keyword in play.lower() for keyword in ["made", "miss"])
            ]
            if shot_results:
                sequence_parts.append(random.choice(shot_results))

        return " / ".join(sequence_parts)

    def generate_defensive_sequence(self, plays_by_category):
        """Generate realistic defensive sequence using play definitions."""
        sequence_parts = []

        # Add defensive formation (from Defense category)
        if "Defense" in plays_by_category:
            defensive_formations = [
                play
                for play in plays_by_category["Defense"]
                if any(
                    keyword in play.lower()
                    for keyword in ["2-3", "3-2", "1-3-1", "1-2-2", "zone"]
                )
            ]
            if defensive_formations:
                sequence_parts.append(random.choice(defensive_formations))

        # Add PnR defense (from Defense category)
        if "Defense" in plays_by_category:
            pnr_defenses = [
                play
                for play in plays_by_category["Defense"]
                if any(
                    keyword in play.lower()
                    for keyword in [
                        "switch",
                        "drop",
                        "hedge",
                        "trap",
                        "ice",
                        "flat",
                        "weak",
                    ]
                )
            ]
            if pnr_defenses:
                sequence_parts.append(random.choice(pnr_defenses))

        # Add defensive pressure (from Defense category)
        if "Defense" in plays_by_category:
            defensive_pressures = [
                play
                for play in plays_by_category["Defense"]
                if any(keyword in play.lower() for keyword in ["press", "court"])
            ]
            if defensive_pressures:
                sequence_parts.append(random.choice(defensive_pressures))

        # Add defensive action (from Defense category)
        if "Defense" in plays_by_category:
            defensive_actions = [
                play
                for play in plays_by_category["Defense"]
                if any(keyword in play.lower() for keyword in ["iso"])
            ]
            if defensive_actions:
                sequence_parts.append(random.choice(defensive_actions))

        return " / ".join(sequence_parts)

    @transaction.atomic
    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.SUCCESS("--- Starting Database Population ---"))

        # Clean up old data
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

        # Get superuser
        superuser = User.objects.filter(is_superuser=True).order_by("pk").first()
        if not superuser:
            self.stdout.write(
                self.style.ERROR(
                    'FATAL: No superuser found. Please create one first with "python manage.py createsuperuser".'
                )
            )
            return

        self.stdout.write("Creating NBB Competition...")
        nbb_competition, _ = Competition.objects.get_or_create(
            name="Novo Basquete Brasil",
            defaults={"season": "2025-2026", "created_by": superuser},
        )

        # Create NBB Teams, coaches, players
        self.stdout.write(
            "Creating 18 NBB teams, 18 coaches, and 20 players per team..."
        )

        nbb_teams_data = [
            "Bauru Basket",
            "Botafogo",
            "Brasília Basquete",
            "Caxias do Sul",
            "Corinthians",
            "Flamengo",
            "Fortaleza B.C.",
            "Sesi Franca",
            "Minas",
            "Mogi Basquete",
            "Pato Basquete",
            "Paulistano",
            "Pinheiros",
            "São José",
            "São Paulo",
            "União Corinthians",
            "Unifacisa",
            "Vasco da Gama",
        ]

        # Define realistic player names by nationality
        serbian_names = [
            ("Nikola", "Jokić"),
            ("Bogdan", "Bogdanović"),
            ("Nemanja", "Bjelica"),
            ("Miloš", "Teodosić"),
            ("Stefan", "Jović"),
            ("Marko", "Gudurić"),
            ("Nikola", "Mirotić"),
            ("Vasilije", "Micić"),
            ("Aleksandar", "Vezenkov"),
            ("Filip", "Petrusev"),
            ("Nikola", "Kalinić"),
            ("Stefan", "Birčević"),
            ("Milan", "Mačvan"),
            ("Nemanja", "Dangubić"),
            ("Marko", "Simonović"),
            ("Aleksa", "Avramović"),
            ("Ognjen", "Dobrić"),
            ("Dejan", "Davidovac"),
            ("Stefan", "Lazarević"),
            ("Nikola", "Rakićević"),
            ("Vladimir", "Lučić"),
            ("Miroslav", "Raduljica"),
            ("Nemanja", "Nedović"),
            ("Stefan", "Marković"),
            ("Branko", "Lazić"),
            ("Dragan", "Milosavljević"),
            ("Uroš", "Tripković"),
            ("Marko", "Keselj"),
            ("Novica", "Veličković"),
            ("Dušan", "Kecman"),
            ("Milan", "Gurović"),
            ("Predrag", "Stojaković"),
            ("Vlade", "Divac"),
            ("Peja", "Stojaković"),
            ("Dejan", "Bodiroga"),
            ("Željko", "Rebrača"),
            ("Predrag", "Danilović"),
            ("Sasha", "Đorđević"),
            ("Žarko", "Paspalj"),
            ("Vlado", "Šćepanović"),
            ("Miroslav", "Berić"),
            ("Dragan", "Tarlać"),
            ("Željko", "Obradović"),
            ("Dejan", "Tomasević"),
            ("Predrag", "Drobnjak"),
            ("Marko", "Jarić"),
            ("Darko", "Miličić"),
            ("Nenad", "Krstić"),
            ("Vladimir", "Radmanović"),
            ("Igor", "Rakočević"),
            ("Miloš", "Vujanić"),
            ("Predrag", "Savović"),
            ("Dragan", "Lukovski"),
            ("Vule", "Avdalović"),
            ("Stefan", "Nikolić"),
            ("Milan", "Mačvan"),
            ("Nemanja", "Krstić"),
            ("Stefan", "Birčević"),
            ("Bogdan", "Bogdanović"),
            ("Nemanja", "Dangubić"),
        ]

        us_names = [
            ("LeBron", "James"),
            ("Stephen", "Curry"),
            ("Kevin", "Durant"),
            ("Giannis", "Antetokounmpo"),
            ("Luka", "Dončić"),
            ("Joel", "Embiid"),
            ("Nikola", "Jokić"),
            ("Jayson", "Tatum"),
            ("Devin", "Booker"),
            ("Damian", "Lillard"),
            ("Jimmy", "Butler"),
            ("Bam", "Adebayo"),
            ("Anthony", "Davis"),
            ("Russell", "Westbrook"),
            ("Chris", "Paul"),
            ("Kawhi", "Leonard"),
            ("Paul", "George"),
            ("Kyrie", "Irving"),
            ("James", "Harden"),
            ("Bradley", "Beal"),
            ("Zion", "Williamson"),
            ("Ja", "Morant"),
            ("Trae", "Young"),
            ("De'Aaron", "Fox"),
            ("Shai", "Gilgeous-Alexander"),
            ("Tyrese", "Haliburton"),
            ("Cade", "Cunningham"),
            ("Scottie", "Barnes"),
            ("Evan", "Mobley"),
            ("Jalen", "Green"),
            ("Paolo", "Banchero"),
            ("Jabari", "Smith"),
            ("Chet", "Holmgren"),
            ("Victor", "Wembanyama"),
            ("Scoot", "Henderson"),
            ("Brandon", "Miller"),
            ("Amen", "Thompson"),
            ("Ausar", "Thompson"),
            ("Anthony", "Black"),
            ("Bilal", "Coulibaly"),
            ("Keyonte", "George"),
            ("Jordan", "Hawkins"),
            ("Gradey", "Dick"),
            ("Jett", "Howard"),
            ("Kobe", "Bufkin"),
            ("Jalen", "Hood-Schifino"),
            ("Leonard", "Miller"),
            ("Colby", "Jones"),
            ("Julian", "Strawther"),
            ("Ben", "Sheppard"),
            ("Nick", "Smith"),
            ("Brice", "Sensabaugh"),
        ]

        brazilian_names = [
            ("Anderson", "Varejão"),
            ("Nenê", "Hilário"),
            ("Leandrinho", "Barbosa"),
            ("Tiago", "Splitter"),
            ("Rafael", "Hettsheimeir"),
            ("Guilherme", "Deodato"),
            ("Alex", "Garcia"),
            ("Marcelinho", "Huertas"),
            ("Rafael", "Luz"),
            ("Lucas", "Cipolini"),
            ("João", "Paulo"),
            ("Rafael", "Araújo"),
            ("Vítor", "Benite"),
            ("Rafael", "Hettsheimeir"),
            ("Guilherme", "Deodato"),
            ("Alex", "Garcia"),
            ("Marcelinho", "Huertas"),
            ("Rafael", "Luz"),
            ("Lucas", "Cipolini"),
            ("João", "Paulo"),
            ("Rafael", "Araújo"),
            ("Vítor", "Benite"),
            ("Rafael", "Hettsheimeir"),
            ("Guilherme", "Deodato"),
            ("Alex", "Garcia"),
            ("Marcelinho", "Huertas"),
            ("Rafael", "Luz"),
            ("Lucas", "Cipolini"),
            ("João", "Paulo"),
            ("Rafael", "Araújo"),
            ("Vítor", "Benite"),
            ("Rafael", "Hettsheimeir"),
            ("Guilherme", "Deodato"),
            ("Alex", "Garcia"),
            ("Marcelinho", "Huertas"),
            ("Rafael", "Luz"),
            ("Lucas", "Cipolini"),
            ("João", "Paulo"),
            ("Rafael", "Araújo"),
            ("Vítor", "Benite"),
            ("Rafael", "Hettsheimeir"),
            ("Guilherme", "Deodato"),
            ("Alex", "Garcia"),
            ("Marcelinho", "Huertas"),
            ("Rafael", "Luz"),
            ("Lucas", "Cipolini"),
            ("João", "Paulo"),
            ("Rafael", "Araújo"),
            ("Vítor", "Benite"),
            ("Rafael", "Hettsheimeir"),
            ("Guilherme", "Deodato"),
            ("Alex", "Garcia"),
        ]

        australian_names = [
            ("Ben", "Simmons"),
            ("Patty", "Mills"),
            ("Joe", "Ingles"),
            ("Aron", "Baynes"),
            ("Dante", "Exum"),
            ("Thon", "Maker"),
            ("Jonah", "Bolden"),
            ("Will", "Magnay"),
            ("Josh", "Giddey"),
            ("Dyson", "Daniels"),
            ("Jock", "Landale"),
            ("Duop", "Reath"),
            ("Xavier", "Cook"),
            ("Keanu", "Pinder"),
            ("Sam", "Froling"),
            ("Jack", "White"),
            ("Mitch", "Creek"),
            ("Nathan", "Sobey"),
            ("Chris", "Goulding"),
            ("Daniel", "Johnson"),
            ("Todd", "Blanchfield"),
            ("Cameron", "Gliddon"),
            ("Jason", "Cadee"),
            ("Brad", "Newley"),
            ("David", "Barlow"),
            ("Adam", "Gibson"),
            ("Peter", "Crawford"),
            ("Shawn", "Redhage"),
            ("Luke", "Schenscher"),
            ("Mark", "Worthington"),
            ("Brad", "Williamson"),
            ("CJ", "Bruton"),
            ("Sam", "Mackinnon"),
            ("Andrew", "Gaze"),
            ("Shane", "Heal"),
            ("Luc", "Longley"),
            ("Andrew", "Vlahov"),
            ("Mark", "Bradtke"),
            ("Andrew", "Gaze"),
            ("Shane", "Heal"),
            ("Luc", "Longley"),
            ("Andrew", "Vlahov"),
            ("Mark", "Bradtke"),
            ("Andrew", "Gaze"),
            ("Shane", "Heal"),
            ("Luc", "Longley"),
            ("Andrew", "Vlahov"),
            ("Mark", "Bradtke"),
        ]

        # Combine all names and shuffle
        all_names = serbian_names + us_names + brazilian_names + australian_names
        random.shuffle(all_names)
        name_index = 0
        
        # Track used usernames to ensure uniqueness
        used_usernames = set()

        all_teams = []
        for i, team_name in enumerate(nbb_teams_data):
            # Create team
            team = Team.objects.create(
                name=team_name,
                competition=nbb_competition,
                created_by=superuser,
            )

            # Create coach
            if name_index < len(all_names):
                first_name, last_name = all_names[name_index]
                name_index += 1
                base_username = f"{first_name.lower()}.{last_name.lower()}"
            else:
                # Fallback names if we run out
                first_name = f"Coach{i+1}"
                last_name = f"Team{i+1}"
                base_username = f"coach{i+1}.team{i+1}"
            
            # Ensure unique username
            username = base_username
            counter = 1
            while username in used_usernames:
                username = f"{base_username}{counter}"
                counter += 1
            used_usernames.add(username)

            coach = User.objects.create_user(
                username=username,
                password="password",
                first_name=first_name,
                last_name=last_name,
                role=User.Role.COACH,
                coach_type=User.CoachType.HEAD_COACH,
            )
            team.coaches.add(coach)

            # Create 20 players with unique numbers per team
            team_players = []
            used_numbers = set()  # Track used jersey numbers for this team

            for j in range(20):
                if name_index < len(all_names):
                    first_name, last_name = all_names[name_index]
                    name_index += 1
                    base_username = f"{first_name.lower()}.{last_name.lower()}"
                else:
                    # Fallback names if we run out - ensure unique usernames
                    player_num = (i * 20) + j + 1
                    first_name = f"Player{player_num}"
                    last_name = f"Team{i+1}"
                    base_username = f"player{player_num}.team{i+1}"

                # Ensure unique username
                username = base_username
                counter = 1
                while username in used_usernames:
                    username = f"{base_username}{counter}"
                    counter += 1
                used_usernames.add(username)

                # Generate unique jersey number for this team
                while True:
                    jersey_number = random.randint(0, 99)
                    if jersey_number not in used_numbers:
                        used_numbers.add(jersey_number)
                        break

                player = User.objects.create_user(
                    username=username,
                    password="password",
                    first_name=first_name,
                    last_name=last_name,
                    role=User.Role.PLAYER,
                    jersey_number=jersey_number,
                )
                team_players.append(player)
            team.players.set(team_players)
            all_teams.append(team)
            self.stdout.write(
                f"  - Created team: {team.name} with 1 coach and 20 players."
            )

        # --- 4.5. CREATE SPECIFIC FORTALEZA COACHES ---
        self.stdout.write("Creating specific Fortaleza coaches...")

        # Find Fortaleza team
        fortaleza_team = None
        for team in all_teams:
            if "Fortaleza" in team.name:
                fortaleza_team = team
                break

        if fortaleza_team:
            # Create Vladimir Dosenovic (Assistant Coach)
            vladimir = User.objects.create_user(
                username="vladdos",
                password="20pogodi",
                first_name="Vladimir",
                last_name="Dosenovic",
                role=User.Role.COACH,
                coach_type=User.CoachType.ASSISTANT_COACH,
            )
            fortaleza_team.coaches.add(vladimir)
            self.stdout.write(
                "  - Created Vladimir Dosenovic (Assistant Coach) for Fortaleza"
            )

            # Create Jelena Todorovic (Head Coach)
            jelena = User.objects.create_user(
                username="jelena",
                password="20pogodi",
                first_name="Jelena",
                last_name="Todorovic",
                role=User.Role.COACH,
                coach_type=User.CoachType.HEAD_COACH,
            )
            fortaleza_team.coaches.add(jelena)
            self.stdout.write("  - Created Jelena Todorovic (Head Coach) for Fortaleza")
        else:
            self.stdout.write(
                self.style.ERROR("Fortaleza team not found for specific coaches!")
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
            "..",
            "data",
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

        # Create sample games
        self.stdout.write("Creating 50 sample games (20 Fortaleza games)...")

        # Fortaleza team should already be found from the coaches section
        if not fortaleza_team:
            self.stdout.write(self.style.ERROR("Fortaleza team not found!"))
            return

        games = []

        # Create 20 Fortaleza games
        for i in range(20):
            # Fortaleza plays against different teams
            opponent = random.choice(
                [team for team in all_teams if team != fortaleza_team]
            )

            # Randomly decide if Fortaleza is home or away
            if random.choice([True, False]):
                home_team = fortaleza_team
                away_team = opponent
            else:
                home_team = opponent
                away_team = fortaleza_team

            # Random scores
            home_score = random.randint(70, 120)
            away_score = random.randint(70, 120)

            # Random game date in the last 6 months
            game_date = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(1, 180)
            )

            game = Game.objects.create(
                competition=nbb_competition,
                home_team=home_team,
                away_team=away_team,
                game_date=game_date,
                home_team_score=home_score,
                away_team_score=away_score,
                created_by=superuser,
            )
            games.append(game)

        # Create 30 additional games
        for i in range(30):
            # Random teams
            home_team = random.choice(all_teams)
            away_team = random.choice([team for team in all_teams if team != home_team])

            # Random scores
            home_score = random.randint(70, 120)
            away_score = random.randint(70, 120)

            # Random game date in the last 6 months
            game_date = datetime.datetime.now() - datetime.timedelta(
                days=random.randint(1, 180)
            )

            game = Game.objects.create(
                competition=nbb_competition,
                home_team=home_team,
                away_team=away_team,
                game_date=game_date,
                home_team_score=home_score,
                away_team_score=away_score,
                created_by=superuser,
            )
            games.append(game)

        # Load play definitions for sequence generation
        self.stdout.write("Loading play definitions for sequence generation...")
        plays_by_category = self.load_play_definitions()

        # Create possessions with realistic sequences
        self.stdout.write("Creating possessions with realistic sequences...")

        # Get all possible values for other fields
        outcomes = [choice[0] for choice in Possession.OutcomeChoices.choices]
        offensive_sets = [
            choice[0] for choice in Possession.OffensiveSetChoices.choices
        ]
        pnr_types = [choice[0] for choice in Possession.PnRTypeChoices.choices]
        pnr_results = [choice[0] for choice in Possession.PnRResultChoices.choices]
        defensive_sets = [
            choice[0] for choice in Possession.DefensiveSetChoices.choices
        ]
        defensive_pnr = [choice[0] for choice in Possession.DefensivePnRChoices.choices]
        shoot_qualities = [
            choice[0] for choice in Possession.ShootQualityChoices.choices
        ]
        time_ranges = [choice[0] for choice in Possession.TimeRangeChoices.choices]

        for game in games:
            for i in range(
                random.randint(100, 130)
            ):  # Create a random number of possessions (100-130 per game)
                possession_team = random.choice([game.home_team, game.away_team])
                opponent_team = (
                    game.away_team
                    if possession_team == game.home_team
                    else game.home_team
                )
                quarter = random.randint(1, 4)

                # Determine if this is an offensive or defensive possession
                is_offensive_possession = random.choice([True, False])

                # Generate sequences using play definitions
                if is_offensive_possession:
                    offensive_sequence = self.generate_offensive_sequence(
                        plays_by_category
                    )
                    defensive_sequence = ""
                else:
                    offensive_sequence = ""
                    defensive_sequence = self.generate_defensive_sequence(
                        plays_by_category
                    )

                Possession.objects.create(
                    game=game,
                    team=possession_team,
                    opponent=opponent_team,
                    quarter=quarter,
                    start_time_in_game=f"{random.randint(0,11):02}:{random.randint(0,59):02}",
                    duration_seconds=random.randint(5, 24),
                    outcome=random.choice(outcomes),
                    points_scored=random.randint(0, 3),
                    offensive_set=random.choice(offensive_sets),
                    pnr_type=random.choice(pnr_types),
                    pnr_result=random.choice(pnr_results),
                    has_paint_touch=random.choice([True, False]),
                    has_kick_out=random.choice([True, False]),
                    has_extra_pass=random.choice([True, False]),
                    number_of_passes=random.randint(1, 5),
                    is_offensive_rebound=random.choice([True, False]),
                    offensive_rebound_count=random.randint(0, 3),
                    defensive_set=random.choice(defensive_sets),
                    defensive_pnr=random.choice(defensive_pnr),
                    box_out_count=random.randint(0, 4),
                    offensive_rebounds_allowed=random.randint(0, 2),
                    shoot_time=random.randint(5, 20),
                    shoot_quality=random.choice(shoot_qualities),
                    time_range=random.choice(time_ranges),
                    after_timeout=random.choice([True, False]),
                    offensive_sequence=offensive_sequence,
                    defensive_sequence=defensive_sequence,
                    notes=f"Sample possession {i+1}",
                    created_by=superuser,
                )

        self.stdout.write(self.style.SUCCESS("--- Database Population Complete! ---"))
