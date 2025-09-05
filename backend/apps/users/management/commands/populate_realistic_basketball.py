from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.teams.models import Team
from apps.games.models import Game, GameRoster
from apps.competitions.models import Competition
from apps.possessions.models import Possession
from apps.users.models import User
from apps.plays.models import PlayCategory, PlayDefinition
from datetime import date, time, timedelta, datetime
import random
import math
import os
import json

User = get_user_model()


class Command(BaseCommand):
    help = "Populate database with ultra-realistic Brazilian basketball data including storylines"

    def add_arguments(self, parser):
        parser.add_argument(
            "--clear-existing",
            action="store_true",
            help="Clear existing data before populating",
        )
        parser.add_argument(
            "--seasons",
            type=int,
            default=2,
            help="Number of seasons to generate (default: 2 for 2024-2025 and 2025-2026)",
        )

    def handle(self, *args, **options):
        if options["clear_existing"]:
            self.stdout.write("Clearing existing data...")

            # Clear in proper order to avoid foreign key constraints
            Possession.objects.all().delete()
            self.stdout.write("✓ Possessions cleared")

            GameRoster.objects.all().delete()
            self.stdout.write("✓ Game rosters cleared")

            Game.objects.all().delete()
            self.stdout.write("✓ Games cleared")

            # Clear team players first
            for team in Team.objects.all():
                team.players.clear()
            self.stdout.write("✓ Team players cleared")

            Team.objects.all().delete()
            self.stdout.write("✓ Teams cleared")

            User.objects.filter(is_superuser=False).delete()
            self.stdout.write("✓ Non-admin users cleared")

            self.stdout.write("All existing data cleared successfully")
        else:
            self.stdout.write("Checking for existing data...")
            existing_teams = Team.objects.count()
            existing_games = Game.objects.count()
            if existing_teams > 0 or existing_games > 0:
                self.stdout.write(
                    self.style.WARNING(
                        f"Found existing data: {existing_teams} teams, {existing_games} games. "
                        "Use --clear-existing to remove all data first."
                    )
                )
                return

        # Verify database is empty BEFORE creating any data
        self.verify_database_empty()

        self.stdout.write("Creating admin user...")
        admin_user = self.create_admin_user()

        self.stdout.write("Loading play definitions...")
        self.load_play_definitions(admin_user)

        self.stdout.write("Creating competitions for multiple seasons...")
        competitions = self.create_seasons(admin_user)

        self.stdout.write("Creating teams with Brazilian basketball characteristics...")
        teams = self.create_realistic_teams(admin_user)

        self.stdout.write("Assigning teams to competitions...")
        self.assign_teams_to_competitions(teams, competitions)

        self.stdout.write("Creating specific coaches for Fortaleza...")
        self.create_fortaleza_coaches(teams, admin_user)

        self.stdout.write(
            "Creating players with realistic Brazilian basketball profiles..."
        )
        players = self.create_realistic_players(teams, admin_user)

        self.stdout.write("Simulating player injuries...")
        injured_players = self.simulate_injuries(teams, admin_user)

        self.stdout.write("Generating season storylines and rivalries...")
        self.create_storylines(teams)

        for competition in competitions:
            self.stdout.write(f"Generating season {competition.name}...")
            self.generate_season(teams, competition, admin_user, competition.name)

        self.stdout.write(
            self.style.SUCCESS(
                "Ultra-realistic basketball database populated successfully!"
            )
        )

    def create_admin_user(self):
        """Create an admin user for creating teams and games"""
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
        if created:
            admin_user.set_password("password123")
            admin_user.save()
            self.stdout.write("Created admin user: admin")
        else:
            self.stdout.write("Admin user already exists")
        return admin_user

    def verify_database_empty(self):
        """Verify that the database is empty before proceeding"""
        team_count = Team.objects.count()
        user_count = User.objects.filter(is_superuser=False).count()
        game_count = Game.objects.count()
        possession_count = Possession.objects.count()

        if team_count > 0 or user_count > 0 or game_count > 0 or possession_count > 0:
            self.stdout.write(
                self.style.ERROR(
                    f"Database not empty: {team_count} teams, {user_count} users, "
                    f"{game_count} games, {possession_count} possessions. "
                    "Use --clear-existing to clear all data first."
                )
            )
            raise Exception(
                "Database must be empty to proceed. Use --clear-existing flag."
            )

    def create_seasons(self, admin_user):
        """Create competitions for multiple seasons with basketball-specific rules"""
        seasons = {}
        current_year = date.today().year

        # Brazilian basketball rules
        brazil_rules = {
            "quarter_length_minutes": 10,
            "overtime_length_minutes": 5,
            "shot_clock_seconds": 24,
            "personal_foul_limit": 5,
            "team_fouls_for_bonus": 5,
            "country": "Brazil",
            "league_level": "Professional"
        }

        for i in range(2):  # 2024-2025 and 2025-2026
            season_year = current_year - 1 + i
            season_name = f"Temporada {season_year}-{season_year + 1}"

            competition, created = Competition.objects.get_or_create(
                name=season_name, 
                defaults={
                    "created_by": admin_user,
                    **brazil_rules
                }
            )

            if created:
                self.stdout.write(f"Created competition: {competition.name} with Brazilian rules")
            else:
                self.stdout.write(f"Using existing competition: {competition.name}")

            seasons[season_year] = competition

        return list(seasons.values())

    def create_realistic_teams(self, admin_user):
        """Create teams with realistic Brazilian basketball characteristics"""
        teams = []

        # Real Brazilian basketball teams with characteristics
        team_data = [
            {
                "name": "Fortaleza",
                "style": "balanced",
                "strength": "balanced",
                "home_court_advantage": 0.10,
                "fan_base": "medium",
                "budget": "medium",
            },
            {
                "name": "Flamengo Basquete",
                "style": "fast_paced",
                "strength": "offensive",
                "home_court_advantage": 0.15,
                "fan_base": "large",
                "budget": "high",
            },
            {
                "name": "Franca Basquete",
                "style": "defensive",
                "strength": "defensive",
                "home_court_advantage": 0.12,
                "fan_base": "medium",
                "budget": "medium",
            },
            {
                "name": "São Paulo F.C.",
                "style": "balanced",
                "strength": "balanced",
                "home_court_advantage": 0.10,
                "fan_base": "large",
                "budget": "high",
            },
            {
                "name": "Minas Tênis Clube",
                "style": "defensive",
                "strength": "defensive",
                "home_court_advantage": 0.08,
                "fan_base": "medium",
                "budget": "medium",
            },
            {
                "name": "Pinheiros",
                "style": "fast_paced",
                "strength": "offensive",
                "home_court_advantage": 0.05,
                "fan_base": "small",
                "budget": "low",
            },
            {
                "name": "Bauru Basket",
                "style": "balanced",
                "strength": "balanced",
                "home_court_advantage": 0.06,
                "fan_base": "small",
                "budget": "low",
            },
            {
                "name": "Mogi das Cruzes",
                "style": "defensive",
                "strength": "defensive",
                "home_court_advantage": 0.04,
                "fan_base": "small",
                "budget": "low",
            },
            {
                "name": "Limeira",
                "style": "fast_paced",
                "strength": "offensive",
                "home_court_advantage": 0.03,
                "fan_base": "small",
                "budget": "low",
            },
        ]

        for team_info in team_data:
            team, created = Team.objects.get_or_create(
                name=team_info["name"], defaults={"created_by": admin_user}
            )

            if created:
                self.stdout.write(
                    f"Created new team: {team.name} ({team_info['style']} style)"
                )
            else:
                self.stdout.write(f"Using existing team: {team.name}")

            # Store team characteristics for later use (these are not database fields, just for logic)
            team.style = team_info["style"]
            team.strength = team_info["strength"]
            team.home_court_advantage = team_info["home_court_advantage"]
            team.fan_base = team_info["fan_base"]
            team.budget = team_info["budget"]

            teams.append(team)

        return teams

    def assign_teams_to_competitions(self, teams, competitions):
        """Assign teams to competitions (distribute evenly)"""
        teams_per_competition = len(teams) // len(competitions)
        remainder = len(teams) % len(competitions)
        
        team_index = 0
        for i, competition in enumerate(competitions):
            # Calculate how many teams this competition gets
            teams_for_this_competition = teams_per_competition + (1 if i < remainder else 0)
            
            # Assign teams to this competition
            for j in range(teams_for_this_competition):
                if team_index < len(teams):
                    team = teams[team_index]
                    team.competition = competition
                    team.save()
                    team_index += 1
            
            self.stdout.write(f"  - Assigned {teams_for_this_competition} teams to {competition.name}")

    def create_fortaleza_coaches(self, teams, admin_user):
        """Create specific coaches for Fortaleza team"""
        fortaleza_team = None
        
        # Find Fortaleza team
        for team in teams:
            if team.name == "Fortaleza":
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

    def create_realistic_players(self, teams, admin_user):
        """Create players with realistic Brazilian basketball profiles following position distribution rules"""
        players = []
        
        # Position distribution rules for team roster (20 players)
        position_distribution = {
            "PG": 4,  # Point Guards
            "SG": 4,  # Shooting Guards  
            "SF": 4,  # Small Forwards
            "PF": 4,  # Power Forwards
            "C": 4,   # Centers (maximum 4)
        }

        for team in teams:
            team_players = []
            
            # Create players according to position distribution
            for position, count in position_distribution.items():
                for i in range(count):
                    player = self.create_realistic_player(team, position, i, admin_user)
                    team_players.append(player)
                    # Add player to team
                    team.players.add(player)
            
            # Shuffle the players to randomize their order
            random.shuffle(team_players)
            players.extend(team_players)

            self.stdout.write(f"Created {team.players.count()} players for {team.name} with proper position distribution")
        
        return players

    def create_realistic_player(self, team, position, player_index, admin_user):
        """Create a single player with realistic Brazilian basketball characteristics"""
        # Brazilian basketball player names (mix of Brazilian and international)
        first_names = [
            "João",
            "Pedro",
            "Lucas",
            "Gabriel",
            "Rafael",
            "Thiago",
            "Bruno",
            "André",
            "Carlos",
            "Diego",
            "Felipe",
            "Marcelo",
            "Ricardo",
            "Fernando",
            "Alexandre",
            "Marcos",
            "Paulo",
            "Roberto",
            "Daniel",
            "Eduardo",
            "Leonardo",
            "Rodrigo",
            "Anderson",
            "Varejão",
            "Nenê",
            "Barbosa",
            "Splitter",
            "Huertas",
            "Garcia",
        ]

        last_names = [
            "Silva",
            "Santos",
            "Oliveira",
            "Souza",
            "Rodrigues",
            "Ferreira",
            "Almeida",
            "Pereira",
            "Lima",
            "Gomes",
            "Costa",
            "Ribeiro",
            "Carvalho",
            "Alves",
            "Pinto",
            "Cavalcanti",
            "Dias",
            "Castro",
            "Campos",
            "Cardoso",
            "Correia",
            "Cunha",
            "Dantas",
            "Duarte",
            "Farias",
            "Fernandes",
            "Freitas",
            "Gonçalves",
        ]

        # International players (common in Brazilian basketball)
        international_names = [
            "Johnson",
            "Williams",
            "Brown",
            "Jones",
            "Garcia",
            "Miller",
            "Davis",
            "Rodriguez",
            "Martinez",
            "Anderson",
            "Taylor",
            "Thomas",
            "Hernandez",
            "Moore",
            "Martin",
            "Lee",
            "Perez",
            "Thompson",
            "White",
            "Harris",
        ]

        # 70% Brazilian, 30% International
        if random.random() < 0.7:
            first_name = random.choice(first_names)
            last_name = random.choice(last_names)
        else:
            first_name = random.choice(international_names)
            last_name = random.choice(international_names)

        # Generate unique username
        base_username = f"{first_name.lower()}.{last_name.lower()}"
        username = base_username
        counter = 1
        
        # Ensure username uniqueness
        while User.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1

        # Generate unique email
        base_email = f"{username}@{team.name.lower().replace(' ', '').replace('.', '')}.com"
        email = base_email
        email_counter = 1
        
        # Ensure email uniqueness
        while User.objects.filter(email=email).exists():
            email = f"{username}{email_counter}@{team.name.lower().replace(' ', '').replace('.', '')}.com"
            email_counter += 1

        # Create user
        user = User.objects.create_user(
            username=username,
            first_name=first_name,
            last_name=last_name,
            email=email,
            password="password123",
        )

        # Set player characteristics based on position and team style
        user.position = position
        user.team = team
        user.jersey_number = random.randint(1, 99)

        # Player skill ratings (1-100 scale)
        user.overall_rating = self.calculate_player_rating(
            position, team.style, player_index
        )
        user.three_point_rating = self.calculate_three_point_rating(
            position, team.style
        )
        user.defense_rating = self.calculate_defense_rating(position, team.strength)
        user.passing_rating = self.calculate_passing_rating(position)
        user.rebounding_rating = self.calculate_rebounding_rating(position)

        user.save()

        return user

    def calculate_player_rating(self, position, team_style, player_index):
        """Calculate overall player rating based on position and team style"""
        base_rating = 65  # Base rating for all players

        # Position bonuses
        position_bonuses = {
            "PG": 5,  # Point guards get slight bonus
            "SG": 3,  # Shooting guards
            "SF": 2,  # Small forwards
            "PF": 1,  # Power forwards
            "C": 0,  # Centers
        }

        # Team style bonuses
        style_bonuses = {"fast_paced": 3, "defensive": 2, "balanced": 1}

        # Player index affects rating (first 12 players are better)
        if player_index < 12:
            player_bonus = random.randint(5, 15)
        else:
            player_bonus = random.randint(-5, 5)

        total_rating = (
            base_rating
            + position_bonuses[position]
            + style_bonuses[team_style]
            + player_bonus
        )

        # Ensure rating is within 50-95 range
        return max(50, min(95, total_rating))

    def calculate_three_point_rating(self, position, team_style):
        """Calculate three-point shooting rating"""
        base_rating = 60

        # Position bonuses for 3PT
        position_bonuses = {"PG": 10, "SG": 15, "SF": 8, "PF": 2, "C": -5}

        # Team style affects 3PT emphasis
        style_bonuses = {"fast_paced": 8, "defensive": 2, "balanced": 5}

        total_rating = (
            base_rating
            + position_bonuses[position]
            + style_bonuses[team_style]
            + random.randint(-10, 10)
        )
        return max(30, min(95, total_rating))

    def calculate_defense_rating(self, position, team_strength):
        """Calculate defensive rating"""
        base_rating = 65

        # Position bonuses for defense
        position_bonuses = {"PG": 5, "SG": 3, "SF": 8, "PF": 10, "C": 15}

        # Team strength affects defense
        strength_bonuses = {"defensive": 15, "balanced": 8, "offensive": 2}

        total_rating = (
            base_rating
            + position_bonuses[position]
            + strength_bonuses[team_strength]
            + random.randint(-8, 8)
        )
        return max(40, min(95, total_rating))

    def calculate_passing_rating(self, position):
        """Calculate passing rating"""
        base_rating = 60

        position_bonuses = {"PG": 20, "SG": 10, "SF": 5, "PF": 3, "C": 8}

        total_rating = base_rating + position_bonuses[position] + random.randint(-5, 5)
        return max(40, min(95, total_rating))

    def calculate_rebounding_rating(self, position):
        """Calculate rebounding rating"""
        base_rating = 60

        position_bonuses = {"PG": -5, "SG": -3, "SF": 5, "PF": 15, "C": 20}

        total_rating = base_rating + position_bonuses[position] + random.randint(-5, 5)
        return max(40, min(95, total_rating))

    def create_storylines(self, teams):
        """Create realistic storylines and rivalries between teams"""
        self.stdout.write("Creating team rivalries and storylines...")

        # Major rivalries (based on real Brazilian basketball)
        rivalries = [
            (
                "Flamengo Basquete",
                "São Paulo F.C.",
                "Classic rivalry - biggest clubs in Brazil",
            ),
            ("Franca Basquete", "Bauru Basket", "São Paulo state rivalry"),
            ("Minas Tênis Clube", "Pinheiros", "Regional rivalry"),
            ("Flamengo Basquete", "Franca Basquete", "Recent championship rivalry"),
        ]

        for team1_name, team2_name, description in rivalries:
            team1 = next((t for t in teams if t.name == team1_name), None)
            team2 = next((t for t in teams if t.name == team2_name), None)

            if team1 and team2:
                # Store rivalry information
                team1.rival_team = team2
                team2.rival_team = team1
                self.stdout.write(
                    f"Created rivalry: {team1_name} vs {team2_name} - {description}"
                )

    def generate_season(self, teams, competition, admin_user, season_year):
        """Generate a complete season with realistic scheduling and outcomes"""
        self.stdout.write(f"Generating season {season_year}...")

        # Generate regular season games
        regular_season_games = self.generate_regular_season(
            teams, competition, admin_user, season_year
        )

        # Generate playoff games
        playoff_games = self.generate_playoffs(
            teams, competition, admin_user, season_year
        )

        # Generate possessions for all games
        all_games = regular_season_games + playoff_games
        self.generate_realistic_possessions(all_games, admin_user)

        self.stdout.write(
            f"Season {season_year} complete: {len(all_games)} games generated"
        )

    def generate_regular_season(self, teams, competition, admin_user, season_year):
        """Generate regular season with realistic scheduling"""
        games = []

        # Each team plays every other team twice (home and away)
        for i, home_team in enumerate(teams):
            for j, away_team in enumerate(teams):
                if i != j:  # Don't play against yourself
                    # Home game
                    home_game = self.create_realistic_game(
                        home_team,
                        away_team,
                        competition,
                        admin_user,
                        season_year,
                        "regular",
                    )
                    games.append(home_game)

                    # Away game (later in season)
                    away_game = self.create_realistic_game(
                        away_team,
                        home_team,
                        competition,
                        admin_user,
                        season_year,
                        "regular",
                    )
                    games.append(away_game)

        self.stdout.write(f"Generated {len(games)} regular season games")
        return games

    def create_realistic_game(
        self, home_team, away_team, competition, admin_user, season_year, game_type
    ):
        """Create a realistic game with proper scheduling"""
        # Season scheduling logic
        if season_year == 2024:
            base_date = date(2024, 10, 15)  # Season starts October 2024
        else:  # 2025
            base_date = date(2025, 10, 15)  # Season starts October 2025

        # Add some randomness to game dates
        days_offset = random.randint(0, 180)  # 6 month season
        game_date = base_date + timedelta(days=days_offset)

        # Game time (most games in evening)
        if random.random() < 0.8:
            game_time = time(19, 30)  # 7:30 PM
        else:
            game_time = time(20, 0)  # 8:00 PM

        game_datetime = datetime.combine(game_date, game_time)

        # Create game
        game = Game.objects.create(
            home_team=home_team,
            away_team=away_team,
            competition=competition,
            game_date=game_datetime,
            home_team_score=0,
            away_team_score=0,
            quarter=1,
            created_by=admin_user,
        )

        # Create rosters for this game
        self.create_game_rosters(game)

        return game

    def create_game_rosters(self, game):
        """Create 12-player rosters for each team in the game following position distribution rules"""
        # Position distribution for game roster (12 players)
        game_roster_distribution = {
            "PG": 2,  # Point Guards
            "SG": 2,  # Shooting Guards
            "SF": 3,  # Small Forwards
            "PF": 3,  # Power Forwards
            "C": 2,   # Centers
        }

        # Home team roster
        home_roster = GameRoster.objects.create(game=game, team=game.home_team)
        home_roster_players = self.select_players_by_position(game.home_team, game_roster_distribution)
        home_roster.players.set(home_roster_players)
        home_roster.starting_five.set(self.select_starting_five(home_roster_players))

        # Away team roster
        away_roster = GameRoster.objects.create(game=game, team=game.away_team)
        away_roster_players = self.select_players_by_position(game.away_team, game_roster_distribution)
        away_roster.players.set(away_roster_players)
        away_roster.starting_five.set(self.select_starting_five(away_roster_players))

    def select_players_by_position(self, team, position_distribution):
        """Select players for game roster following position distribution rules"""
        selected_players = []
        
        for position, count in position_distribution.items():
            # Get players of this position from the team
            position_players = list(team.players.filter(position=position))
            
            if len(position_players) >= count:
                # Randomly select the required number of players
                selected = random.sample(position_players, count)
                selected_players.extend(selected)
            else:
                # If not enough players of this position, take all available
                selected_players.extend(position_players)
                # Fill remaining slots with players from other positions
                remaining_slots = count - len(position_players)
                other_players = list(team.players.exclude(position=position))
                if other_players:
                    fillers = random.sample(other_players, min(remaining_slots, len(other_players)))
                    selected_players.extend(fillers)
        
        # Ensure we have exactly 12 players
        if len(selected_players) > 12:
            selected_players = random.sample(selected_players, 12)
        elif len(selected_players) < 12:
            # Fill remaining slots with any available players
            all_players = list(team.players.all())
            remaining = [p for p in all_players if p not in selected_players]
            if remaining:
                fillers = random.sample(remaining, min(12 - len(selected_players), len(remaining)))
                selected_players.extend(fillers)
        
        return selected_players[:12]

    def select_starting_five(self, roster_players):
        """Select starting five players (1 PG, 1 SG, 1 SF, 1 PF, 1 C)"""
        starting_five = []
        required_positions = ["PG", "SG", "SF", "PF", "C"]
        
        for position in required_positions:
            position_players = [p for p in roster_players if p.position == position]
            if position_players:
                starting_five.append(random.choice(position_players))
        
        # If we don't have all positions, fill with available players
        if len(starting_five) < 5:
            remaining_players = [p for p in roster_players if p not in starting_five]
            while len(starting_five) < 5 and remaining_players:
                starting_five.append(remaining_players.pop(0))
        
        return starting_five[:5]

    def simulate_game_flow(self, game, possessions):
        """Simulate realistic game flow including lead changes, close games, and clutch situations"""
        # Calculate lead changes throughout the game
        lead_changes = 0
        current_leader = None
        home_score = 0
        away_score = 0
        
        # Track scores throughout the game
        score_progression = []
        
        for i, possession in enumerate(possessions):
            if possession.team.team == game.home_team:
                home_score += possession.points_scored
            else:
                away_score += possession.points_scored
            
            # Check for lead change
            if home_score > away_score:
                if current_leader != 'home':
                    if current_leader is not None:
                        lead_changes += 1
                    current_leader = 'home'
            elif away_score > home_score:
                if current_leader != 'away':
                    if current_leader is not None:
                        lead_changes += 1
                    current_leader = 'away'
            
            score_progression.append({
                'possession': i,
                'home_score': home_score,
                'away_score': away_score,
                'leader': current_leader
            })
        
        # Determine game characteristics
        final_margin = abs(home_score - away_score)
        is_close_game = final_margin <= 10
        is_blowout = final_margin >= 20
        
        # Simulate clutch situations (last 2 minutes of close games)
        clutch_situations = 0
        if is_close_game:
            # Last 2 minutes = last ~8-10 possessions
            clutch_possessions = possessions[-min(10, len(possessions)):]
            clutch_situations = len([p for p in clutch_possessions if p.points_scored > 0])
        
        # Store game flow data
        game.lead_changes = lead_changes
        game.is_close_game = is_close_game
        game.is_blowout = is_blowout
        game.clutch_situations = clutch_situations
        game.save()
        
        return {
            'lead_changes': lead_changes,
            'is_close_game': is_close_game,
            'is_blowout': is_blowout,
            'clutch_situations': clutch_situations,
            'final_margin': final_margin
        }

    def add_special_scenarios(self, game, possessions):
        """Add special basketball scenarios like buzzer beaters, technical fouls, and coach challenges"""
        special_scenarios = []
        
        # Buzzer beaters (game-winning shots in close games)
        if game.is_close_game and random.random() < 0.15:  # 15% chance
            # Find the last possession that scored
            scoring_possessions = [p for p in possessions if p.points_scored > 0]
            if scoring_possessions:
                buzzer_beater = scoring_possessions[-1]
                buzzer_beater.is_buzzer_beater = True
                buzzer_beater.save()
                special_scenarios.append('buzzer_beater')
                self.stdout.write(f"  - Buzzer beater by {buzzer_beater.team.team.name}!")
        
        # Technical fouls (5% chance per game)
        if random.random() < 0.05:
            # Select a random player for technical foul
            all_players = list(game.home_team.players.all()) + list(game.away_team.players.all())
            if all_players:
                tech_foul_player = random.choice(all_players)
                # Get the correct game rosters
                home_roster = GameRoster.objects.get(game=game, team=game.home_team)
                away_roster = GameRoster.objects.get(game=game, team=game.away_team)
                
                # Determine which roster the player belongs to
                if tech_foul_player in game.home_team.players.all():
                    player_roster = home_roster
                    opponent_roster = away_roster
                else:
                    player_roster = away_roster
                    opponent_roster = home_roster
                
                # Create technical foul possession
                tech_foul_possession = Possession.objects.create(
                    game=game,
                    team=player_roster,
                    opponent=opponent_roster,
                    quarter=random.randint(1, 4),
                    outcome="TECHNICAL_FOUL",
                    points_scored=0,
                    duration_seconds=0,
                    offensive_set="Technical Foul",
                    defensive_set="Technical Foul",
                    start_time_in_game="00:00",
                    created_by=game.created_by,
                    is_technical_foul=True,
                    technical_foul_player=tech_foul_player
                )
                special_scenarios.append('technical_foul')
                self.stdout.write(f"  - Technical foul on {tech_foul_player.first_name} {tech_foul_player.last_name}")
        
        # Coach's challenges (3% chance per game)
        if random.random() < 0.03:
            # Get the correct game rosters
            home_roster = GameRoster.objects.get(game=game, team=game.home_team)
            away_roster = GameRoster.objects.get(game=game, team=game.away_team)
            
            # Randomly choose which team challenges
            if random.choice([True, False]):
                challenge_roster = home_roster
                opponent_roster = away_roster
                challenge_team_name = game.home_team.name
            else:
                challenge_roster = away_roster
                opponent_roster = home_roster
                challenge_team_name = game.away_team.name
            
            # Create coach challenge possession
            challenge_possession = Possession.objects.create(
                game=game,
                team=challenge_roster,
                opponent=opponent_roster,
                quarter=random.randint(1, 4),
                outcome="COACH_CHALLENGE",
                points_scored=0,
                duration_seconds=0,
                offensive_set="Coach Challenge",
                defensive_set="Coach Challenge",
                start_time_in_game="00:00",
                created_by=game.created_by,
                is_coach_challenge=True
            )
            special_scenarios.append('coach_challenge')
            self.stdout.write(f"  - Coach challenge by {challenge_team_name}")
        
        return special_scenarios

    def simulate_injuries(self, teams, admin_user):
        """Simulate injuries for players, making them unavailable for some games"""
        injured_players = []
        
        for team in teams:
            # 10-20% chance of injury per player per season
            for player in team.players.all():
                if random.random() < random.uniform(0.10, 0.20):
                    # Simulate injury duration (1-10 games)
                    injury_duration = random.randint(1, 10)
                    
                    # Mark player as injured for specific games
                    injury_info = {
                        'player': player,
                        'team': team,
                        'injury_duration': injury_duration,
                        'games_missed': 0
                    }
                    injured_players.append(injury_info)
                    
                    self.stdout.write(f"  - {player.first_name} {player.last_name} ({team.name}) injured for {injury_duration} games")
        
        self.stdout.write(f"✓ Simulated injuries for {len(injured_players)} players")
        return injured_players

    def is_player_available(self, player, game_date, injured_players):
        """Check if a player is available for a specific game"""
        for injury in injured_players:
            if injury['player'] == player and injury['games_missed'] < injury['injury_duration']:
                return False
        return True

    def generate_playoffs(self, teams, competition, admin_user, season_year):
        """Generate playoff games with realistic bracket"""
        self.stdout.write("Generating playoff games...")

        # Top 8 teams make playoffs
        playoff_teams = teams[:8]
        playoff_games = []

        # Quarterfinals
        quarterfinal_games = self.generate_playoff_round(
            playoff_teams, competition, admin_user, season_year, "quarterfinal"
        )
        playoff_games.extend(quarterfinal_games)

        # Semifinals (winners of quarterfinals)
        semifinal_teams = self.simulate_playoff_winners(quarterfinal_games)
        semifinal_games = self.generate_playoff_round(
            semifinal_teams, competition, admin_user, season_year, "semifinal"
        )
        playoff_games.extend(semifinal_games)

        # Finals
        final_teams = self.simulate_playoff_winners(semifinal_games)
        final_games = self.generate_playoff_round(
            final_teams, competition, admin_user, season_year, "final"
        )
        playoff_games.extend(final_games)

        return playoff_games

    def generate_playoff_round(
        self, teams, competition, admin_user, season_year, round_name
    ):
        """Generate games for a specific playoff round"""
        games = []

        # Pair teams for this round
        for i in range(0, len(teams), 2):
            if i + 1 < len(teams):
                home_team = teams[i]
                away_team = teams[i + 1]

                # Best of 3 series
                for game_num in range(3):
                    game = self.create_realistic_game(
                        home_team,
                        away_team,
                        competition,
                        admin_user,
                        season_year,
                        round_name,
                    )
                    games.append(game)

        return games

    def simulate_playoff_winners(self, games):
        """Simulate winners of playoff games to advance to next round"""
        # This is a placeholder - in real implementation, you'd simulate actual game outcomes
        # For now, just return first 4 teams
        return list(set([game.home_team for game in games[:4]]))

    def generate_realistic_possessions(self, games, admin_user):
        """Generate realistic possessions for all games"""
        self.stdout.write("Generating realistic possessions for all games...")

        for game in games:
            self.stdout.write(
                f"Generating possessions for {game.home_team.name} vs {game.away_team.name}"
            )

            # Generate possessions for this game
            possessions = self.generate_game_possessions(game, admin_user)

            # Simulate game flow and special scenarios
            game_flow = self.simulate_game_flow(game, possessions)
            special_scenarios = self.add_special_scenarios(game, possessions)

            # Update game scores based on possessions
            self.update_game_scores(game, possessions)

            self.stdout.write(f"Generated {len(possessions)} possessions for {game}")

    def generate_game_possessions(self, game, admin_user):
        """Generate realistic possessions for a single game"""
        possessions = []

        # Realistic possession count: 85-110 per team, so 170-220 total
        total_possessions = random.randint(170, 220)

        # Game quarters (4 quarters + potential overtime)
        quarters = [1, 2, 3, 4]
        if random.random() < 0.1:  # 10% chance of overtime
            quarters.append(5)

        current_possession = 0
        home_score = 0
        away_score = 0

        for quarter in quarters:
            quarter_possessions = total_possessions // len(quarters)

            for _ in range(quarter_possessions):
                if current_possession >= total_possessions:
                    break

                # Determine which team has possession
                home_team = game.home_team
                away_team = game.away_team

                # Home team gets slight advantage
                if random.random() < 0.52:
                    offensive_team = home_team
                    defensive_team = away_team
                else:
                    offensive_team = away_team
                    defensive_team = home_team

                # Generate possession outcome
                possession = self.create_realistic_possession(
                    game,
                    offensive_team,
                    defensive_team,
                    quarter,
                    current_possession,
                    admin_user,
                )

                possessions.append(possession)

                # Update scores
                if offensive_team == home_team:
                    home_score += possession.points_scored
                else:
                    away_score += possession.points_scored

                current_possession += 1

        return possessions

    def create_realistic_possession(
        self, game, offensive_team, defensive_team, quarter, possession_num, admin_user
    ):
        """Create a single realistic possession"""
        # Get rosters for this game
        home_roster = GameRoster.objects.get(game=game, team=game.home_team)
        away_roster = GameRoster.objects.get(game=game, team=game.away_team)

        # Select players on court (5 from each team)
        home_players = list(home_roster.starting_five.all())
        away_players = list(away_roster.starting_five.all())

        # Add some bench players randomly
        if random.random() < 0.3:  # 30% chance of bench player
            bench_players = list(
                home_roster.players.exclude(id__in=[p.id for p in home_players])
            )
            if bench_players:
                home_players[random.randint(0, 4)] = random.choice(bench_players)

        if random.random() < 0.3:
            bench_players = list(
                away_roster.players.exclude(id__in=[p.id for p in away_players])
            )
            if bench_players:
                away_players[random.randint(0, 4)] = random.choice(bench_players)

        # Determine possession outcome based on realistic basketball probabilities
        outcome = self.determine_possession_outcome(offensive_team, defensive_team)

        # Select realistic plays from the loaded play definitions
        offensive_play = self.select_realistic_offensive_play()
        defensive_play = self.select_realistic_defensive_play()

        # Generate realistic sequences
        offensive_sequence = self.generate_offensive_sequence(offensive_play, outcome)
        defensive_sequence = self.generate_defensive_sequence(defensive_play, outcome)

        # Create possession
        possession = Possession.objects.create(
            game=game,
            team=home_roster if offensive_team == game.home_team else away_roster,
            opponent=away_roster if offensive_team == game.home_team else home_roster,
            quarter=quarter,
            outcome=outcome,
            points_scored=self.calculate_points_scored(outcome),
            duration_seconds=random.randint(15, 25),  # 15-25 second possessions
            offensive_set=offensive_play,
            defensive_set=defensive_play,
            offensive_sequence=offensive_sequence,
            defensive_sequence=defensive_sequence,
            start_time_in_game=f"{random.randint(0, 9)}:{random.randint(0, 59):02d}",
            created_by=admin_user,
        )

        # Set players on court
        if offensive_team == game.home_team:
            possession.players_on_court.set(home_players)
            possession.defensive_players_on_court.set(away_players)
        else:
            possession.players_on_court.set(away_players)
            possession.defensive_players_on_court.set(home_players)

        return possession

    def determine_possession_outcome(self, offensive_team, defensive_team):
        """Determine realistic possession outcome based on team strengths and basketball statistics"""
        # Base probabilities based on realistic basketball statistics
        # 2PT %: 40-60%, 3PT %: 30-50%, FT %: 60-100%
        
        # Determine if this is a 2PT, 3PT, or free throw attempt
        shot_type_rand = random.random()
        
        if shot_type_rand < 0.65:  # 65% chance of 2PT attempt
            # 2PT shooting percentages: 40-60%
            base_2pt_percentage = random.uniform(0.40, 0.60)
            
            # Adjust based on team characteristics
            if offensive_team.strength == "offensive":
                base_2pt_percentage += 0.05
            elif defensive_team.strength == "defensive":
                base_2pt_percentage -= 0.05
            
            # Clamp to realistic range
            base_2pt_percentage = max(0.35, min(0.65, base_2pt_percentage))
            
            if random.random() < base_2pt_percentage:
                return "MADE_2PTS"
            else:
                return "MISSED_2PTS"
                
        elif shot_type_rand < 0.85:  # 20% chance of 3PT attempt
            # 3PT shooting percentages: 30-50%
            base_3pt_percentage = random.uniform(0.30, 0.50)
            
            # Adjust based on team characteristics
            if offensive_team.strength == "offensive":
                base_3pt_percentage += 0.03
            elif defensive_team.strength == "defensive":
                base_3pt_percentage -= 0.03
            
            # Clamp to realistic range
            base_3pt_percentage = max(0.25, min(0.55, base_3pt_percentage))
            
            if random.random() < base_3pt_percentage:
                return "MADE_3PTS"
            else:
                return "MISSED_3PTS"
                
        elif shot_type_rand < 0.95:  # 10% chance of free throw attempt
            # Free throw percentages: 60-100%
            ft_percentage = random.uniform(0.60, 1.00)
            
            if random.random() < ft_percentage:
                return "MADE_FTS"
            else:
                return "MISSED_FTS"
                
        else:  # 5% chance of turnover
            return "TURNOVER"

    def calculate_points_scored(self, outcome):
        """Calculate points scored based on outcome"""
        if outcome == "MADE_2PTS":
            return 2
        elif outcome == "MADE_3PTS":
            return 3
        elif outcome == "MADE_FTS":
            return 1
        else:
            return 0

    def select_realistic_offensive_play(self):
        """Select a realistic offensive play from the loaded play definitions"""
        try:
            # Get offensive plays from the default team
            default_team = Team.objects.filter(name="Default Play Templates").first()
            if default_team:
                offensive_plays = PlayDefinition.objects.filter(
                    team=default_team,
                    play_type="OFFENSIVE"
                ).values_list('name', flat=True)
                
                if offensive_plays.exists():
                    return random.choice(list(offensive_plays))
            
            # Fallback to common offensive plays from the JSON
            fallback_plays = ["Set 1", "Set 2", "FastBreak", "PnR", "ISO", "HighPost", "LowPost", "BoB 1", "SoB 1"]
            return random.choice(fallback_plays)
        except Exception:
            return "Set 1"  # Ultimate fallback

    def select_realistic_defensive_play(self):
        """Select a realistic defensive play from the loaded play definitions"""
        try:
            # Get defensive plays from the default team
            default_team = Team.objects.filter(name="Default Play Templates").first()
            if default_team:
                defensive_plays = PlayDefinition.objects.filter(
                    team=default_team,
                    play_type="DEFENSIVE"
                ).values_list('name', flat=True)
                
                if defensive_plays.exists():
                    return random.choice(list(defensive_plays))
            
            # Fallback to common defensive plays from the JSON
            fallback_plays = ["2-3", "3-2", "1-3-1", "1-2-2", "zone", "SWITCH", "DROP", "HEDGE"]
            return random.choice(fallback_plays)
        except Exception:
            return "2-3"  # Ultimate fallback

    def update_game_scores(self, game, possessions):
        """Update game scores based on generated possessions"""
        home_score = 0
        away_score = 0

        for possession in possessions:
            if possession.team.team == game.home_team:
                home_score += possession.points_scored
            else:
                away_score += possession.points_scored

        # Update game scores
        game.home_team_score = home_score
        game.away_team_score = away_score
        game.save()

        self.stdout.write(
            f"Updated {game}: {game.home_team.name} {home_score} - {away_score} {game.away_team.name}"
        )

    def load_play_definitions(self, admin_user):
        """Load generic play definitions from JSON fixture"""
        self.stdout.write("Loading generic play definitions...")
        
        # Create a default team for generic play templates
        default_team, _ = Team.objects.get_or_create(
            name="Default Play Templates",
            defaults={
                "created_by": admin_user,
                "competition": Competition.objects.first(),  # Use first available competition
            },
        )

        # Clear existing play definitions for the default team
        PlayCategory.objects.all().delete()
        PlayDefinition.objects.filter(team=default_team).delete()

        # Path to the JSON fixture file - try multiple locations
        possible_paths = [
            os.path.join(
                os.path.dirname(__file__),
                "..",
                "..",
                "..",
                "plays",
                "fixtures",
                "initial_play_definitions.json",
            ),
            os.path.join(
                os.path.dirname(__file__),
                "..",
                "..",
                "..",
                "..",
                "data",
                "initial_play_definitions.json",
            ),
        ]
        
        json_path = None
        for path in possible_paths:
            if os.path.exists(path):
                json_path = path
                break

        if not json_path:
            self.stdout.write(
                self.style.ERROR("No play definitions file found in expected locations")
            )
            self.stdout.write("Creating basic play categories instead...")
            
            # Create basic play categories as fallback
            basic_categories = [
                "Offense", "Defense", "Transition", "Set Plays", "Zone Defense"
            ]
            
            for cat_name in basic_categories:
                PlayCategory.objects.get_or_create(name=cat_name)
            
            self.stdout.write("✓ Created basic play categories")
            return

        self.stdout.write(f"Using play definitions from: {json_path}")
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            for category_data in data:
                category, _ = PlayCategory.objects.get_or_create(
                    name=category_data["category"]
                )
                
                for play_data in category_data["plays"]:
                    # Determine play type based on category
                    play_type = "NEUTRAL"  # Default
                    if "Defense" in category_data["category"]:
                        play_type = "DEFENSIVE"
                    elif "Offense" in category_data["category"]:
                        play_type = "OFFENSIVE"
                    elif category_data["category"] in ["Transition", "Set"]:
                        play_type = "OFFENSIVE"
                    elif category_data["category"] in ["Zone", "Press"]:
                        play_type = "DEFENSIVE"
                    elif category_data["category"] == "Control":
                        play_type = "NEUTRAL"
                    elif category_data["category"] == "Players":
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
                            "description": f"Generic {play_data['name']} play",
                        },
                    )
                    
                    if created:
                        self.stdout.write(f"  - Created play: {play_data['name']}")

            self.stdout.write(f"✓ Loaded {PlayDefinition.objects.count()} play definitions")
            
        except FileNotFoundError:
            self.stdout.write(
                self.style.ERROR(f"Play definitions file not found at: {json_path}")
            )
            self.stdout.write("Creating basic play categories instead...")
            
            # Create basic play categories as fallback
            basic_categories = [
                "Offense", "Defense", "Transition", "Set Plays", "Zone Defense"
            ]
            
            for cat_name in basic_categories:
                PlayCategory.objects.get_or_create(name=cat_name)
            
            self.stdout.write("✓ Created basic play categories")
            
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f"Error loading play definitions: {e}")
            )
            self.stdout.write("Creating basic play categories instead...")
            
            # Create basic play categories as fallback
            basic_categories = [
                "Offense", "Defense", "Transition", "Set Plays", "Zone Defense"
            ]
            
            for cat_name in basic_categories:
                PlayCategory.objects.get_or_create(name=cat_name)
            
            self.stdout.write("✓ Created basic play categories")


    def generate_offensive_sequence(self, offensive_play, outcome):
        """Generate a realistic offensive sequence based on the play and outcome"""
        sequences = {
            "PICK_AND_ROLL": [
                "Ball handler calls for screen → Big sets screen → Ball handler uses screen → Drive to basket",
                "Ball handler calls for screen → Big sets screen → Ball handler rejects screen → Pull-up jumper",
                "Ball handler calls for screen → Big sets screen → Ball handler uses screen → Kick out to shooter",
                "Ball handler calls for screen → Big sets screen → Ball handler uses screen → Pass to rolling big",
            ],
            "ISOLATION": [
                "Ball handler isolates → Dribble moves → Drive to basket",
                "Ball handler isolates → Dribble moves → Step-back jumper",
                "Ball handler isolates → Dribble moves → Crossover → Pull-up",
                "Ball handler isolates → Dribble moves → Spin move → Layup",
            ],
            "POST_UP": [
                "Entry pass to post → Post player backs down → Turnaround jumper",
                "Entry pass to post → Post player backs down → Drop step → Layup",
                "Entry pass to post → Post player backs down → Kick out to perimeter",
                "Entry pass to post → Post player backs down → Hook shot",
            ],
            "TRANSITION": [
                "Rebound → Outlet pass → Fast break → Layup",
                "Rebound → Outlet pass → Fast break → Pull-up three",
                "Steal → Fast break → Alley-oop",
                "Rebound → Outlet pass → Fast break → Kick ahead → Three-pointer",
            ],
            "HANDOFF": [
                "Guard hands off to cutter → Cutter drives to basket",
                "Guard hands off to cutter → Cutter pulls up for jumper",
                "Guard hands off to cutter → Cutter passes to open shooter",
                "Guard hands off to cutter → Cutter drives and kicks out",
            ],
        }
        
        # Get sequences for the play, or use generic ones
        play_sequences = sequences.get(offensive_play, [
            "Ball movement → Screen action → Shot attempt",
            "Entry pass → Off-ball movement → Shot attempt",
            "Dribble penetration → Kick out → Shot attempt",
            "Post entry → Kick out → Shot attempt",
        ])
        
        # Select a random sequence
        base_sequence = random.choice(play_sequences)
        
        # Add outcome-specific details
        if "MADE" in outcome:
            if "3PTS" in outcome:
                return f"{base_sequence} → Made 3-pointer"
            else:
                return f"{base_sequence} → Made 2-pointer"
        elif "MISSED" in outcome:
            if "3PTS" in outcome:
                return f"{base_sequence} → Missed 3-pointer"
            else:
                return f"{base_sequence} → Missed 2-pointer"
        elif outcome == "TURNOVER":
            return f"{base_sequence} → Turnover"
        elif outcome == "FOUL":
            return f"{base_sequence} → Foul drawn"
        else:
            return base_sequence

    def generate_defensive_sequence(self, defensive_play, outcome):
        """Generate a realistic defensive sequence based on the play and outcome"""
        sequences = {
            "MAN_TO_MAN": [
                "Man-to-man pressure → Contest shot → Box out",
                "Man-to-man pressure → Force turnover → Fast break",
                "Man-to-man pressure → Help defense → Recover",
                "Man-to-man pressure → Switch on screen → Contest",
            ],
            "ZONE": [
                "Zone defense → Collapse on penetration → Contest shot",
                "Zone defense → Trap ball handler → Force turnover",
                "Zone defense → Close out on shooter → Contest three",
                "Zone defense → Help and recover → Box out",
            ],
            "SWITCH": [
                "Switch on screen → Contest shot → Box out",
                "Switch on screen → Help defense → Recover",
                "Switch on screen → Force tough shot → Rebound",
                "Switch on screen → Trap ball handler → Steal",
            ],
            "ICE": [
                "Ice the pick and roll → Force baseline → Contest shot",
                "Ice the pick and roll → Trap ball handler → Turnover",
                "Ice the pick and roll → Help defense → Recover",
                "Ice the pick and roll → Force tough shot → Rebound",
            ],
            "TRAP": [
                "Trap ball handler → Force turnover → Fast break",
                "Trap ball handler → Force bad pass → Steal",
                "Trap ball handler → Help defense → Recover",
                "Trap ball handler → Force tough shot → Contest",
            ],
        }
        
        # Get sequences for the play, or use generic ones
        play_sequences = sequences.get(defensive_play, [
            "Defensive pressure → Contest shot → Box out",
            "Defensive pressure → Help defense → Recover",
            "Defensive pressure → Force turnover → Fast break",
            "Defensive pressure → Trap ball handler → Steal",
        ])
        
        # Select a random sequence
        base_sequence = random.choice(play_sequences)
        
        # Add outcome-specific details
        if "MADE" in outcome:
            return f"{base_sequence} → Shot made (defensive breakdown)"
        elif "MISSED" in outcome:
            return f"{base_sequence} → Shot missed (good defense)"
        elif outcome == "TURNOVER":
            return f"{base_sequence} → Forced turnover (excellent defense)"
        elif outcome == "FOUL":
            return f"{base_sequence} → Foul committed"
        else:
            return base_sequence
