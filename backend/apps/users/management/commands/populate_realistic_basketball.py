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
        parser.add_argument(
            "--games-per-season",
            type=int,
            default=None,
            help="Number of games per season (default: auto-calculated based on teams)",
        )
        parser.add_argument(
            "--teams",
            type=int,
            default=None,
            help="Number of teams to create (default: 12)",
        )
        parser.add_argument(
            "--possessions-per-game",
            type=int,
            default=None,
            help="Average number of possessions per game (default: 150-200)",
        )
        parser.add_argument(
            "--quick",
            action="store_true",
            help="Quick mode: fewer games and possessions for faster generation",
        )
        parser.add_argument(
            "--full",
            action="store_true",
            help="Full mode: maximum games and possessions for complete dataset",
        )
        parser.add_argument(
            "--skip-clear",
            action="store_true",
            help="Skip clearing existing data (add to existing data instead)",
        )

    def handle(self, *args, **options):
        # Process command line options
        self.process_options(options)
        
        if options["clear_existing"] and not options["skip_clear"]:
            self.stdout.write("Clearing existing data...")

            # Use Django's CASCADE deletion to handle foreign key constraints properly
            from django.db import transaction, connection
            
            with transaction.atomic():
                # Use raw SQL for much faster bulk deletion
                with connection.cursor() as cursor:
                    # Get counts before deletion
                    cursor.execute("SELECT COUNT(*) FROM possessions_possession")
                    possession_count = cursor.fetchone()[0]
                    
                    cursor.execute("SELECT COUNT(*) FROM games_gameroster")
                    roster_count = cursor.fetchone()[0]
                    
                    cursor.execute("SELECT COUNT(*) FROM games_game")
                    game_count = cursor.fetchone()[0]
                    
                    cursor.execute("SELECT COUNT(*) FROM teams_team")
                    team_count = cursor.fetchone()[0]
                    
                    cursor.execute("SELECT COUNT(*) FROM users_user WHERE is_superuser = false")
                    user_count = cursor.fetchone()[0]
                
                # Fast bulk deletion using raw SQL - order matters for foreign keys
                with connection.cursor() as cursor:
                    # Clear ManyToMany relationship tables first
                    cursor.execute("DELETE FROM possessions_possession_players_on_court")
                    cursor.execute("DELETE FROM possessions_possession_defensive_players_on_court")
                    cursor.execute("DELETE FROM possessions_possession_offensive_rebound_players")
                    cursor.execute("DELETE FROM games_gameroster_players")
                    cursor.execute("DELETE FROM games_gameroster_starting_five")
                    self.stdout.write("✓ Cleared possession and roster ManyToMany relationships")
                    
                    # Clear possessions (has foreign keys to games and rosters)
                    if possession_count > 0:
                        cursor.execute("DELETE FROM possessions_possession")
                        self.stdout.write(f"✓ Cleared {possession_count} possessions")

                    # Clear game rosters (has foreign keys to games and teams)
                    if roster_count > 0:
                        cursor.execute("DELETE FROM games_gameroster")
                        self.stdout.write(f"✓ Cleared {roster_count} game rosters")

                    # Clear games (has foreign keys to teams)
                    if game_count > 0:
                        cursor.execute("DELETE FROM games_game")
                        self.stdout.write(f"✓ Cleared {game_count} games")

                    # Clear team ManyToMany relationships
                    cursor.execute("DELETE FROM teams_team_players")
                    cursor.execute("DELETE FROM teams_team_coaches")
                    cursor.execute("DELETE FROM teams_team_staff")
                    self.stdout.write("✓ Team relationships cleared")

                    # Clear play definitions (has foreign key to teams)
                    cursor.execute("DELETE FROM plays_playdefinition")
                    self.stdout.write("✓ Cleared play definitions")

                    # Clear teams
                    if team_count > 0:
                        cursor.execute("DELETE FROM teams_team")
                        self.stdout.write(f"✓ Cleared {team_count} teams")

                    # Clear non-admin users
                    if user_count > 0:
                        cursor.execute("DELETE FROM users_user WHERE is_superuser = false")
                        self.stdout.write(f"✓ Cleared {user_count} non-admin users")

            self.stdout.write("All existing data cleared successfully")
        elif options["skip_clear"]:
            self.stdout.write("Skipping data clearing - will add to existing data")
        else:
            self.stdout.write("Checking for existing data...")
            existing_teams = Team.objects.count()
            existing_games = Game.objects.count()
            if existing_teams > 0 or existing_games > 0:
                self.stdout.write(
                    self.style.WARNING(
                        f"Found existing data: {existing_teams} teams, {existing_games} games. "
                        "Use --clear-existing to remove all data first, or --skip-clear to add to existing data."
                    )
                )
                return

        # Verify database is empty BEFORE creating any data (unless skip-clear is used)
        if not options["skip_clear"]:
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

        self.stdout.write("Creating staff members for each team...")
        staff_members = self.create_realistic_staff(teams, admin_user)

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

    def process_options(self, options):
        """Process and validate command line options"""
        # Set default values based on mode
        if options["quick"]:
            self.num_teams = options.get("teams", 6)
            self.games_per_season = options.get("games_per_season", 15)  # 6 teams = 15 games each
            self.possessions_per_game = options.get("possessions_per_game", 100)
            self.stdout.write(self.style.WARNING("Quick mode: Generating minimal dataset for fast testing"))
        elif options["full"]:
            self.num_teams = options.get("teams", 16)
            self.games_per_season = options.get("games_per_season", 240)  # 16 teams = 240 games each
            self.possessions_per_game = options.get("possessions_per_game", 200)
            self.stdout.write(self.style.WARNING("Full mode: Generating complete dataset (this will take a while)"))
        else:
            # Normal mode
            self.num_teams = options.get("teams", 12)
            self.games_per_season = options.get("games_per_season", None)  # Auto-calculate
            self.possessions_per_game = options.get("possessions_per_game", None)  # Auto-calculate
        
        # Store other options
        self.seasons = options.get("seasons", 2)
        
        # Display configuration
        self.stdout.write(f"Configuration:")
        self.stdout.write(f"  - Teams: {self.num_teams}")
        self.stdout.write(f"  - Seasons: {self.seasons}")
        if self.games_per_season:
            self.stdout.write(f"  - Games per season: {self.games_per_season}")
        else:
            self.stdout.write(f"  - Games per season: Auto-calculated (each team plays every other team twice)")
        if self.possessions_per_game:
            self.stdout.write(f"  - Possessions per game: {self.possessions_per_game}")
        else:
            self.stdout.write(f"  - Possessions per game: Auto-calculated (150-200 range)")

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
            "league_level": "Professional",
        }

        for i in range(2):  # 2024-2025 and 2025-2026
            season_year = current_year - 1 + i
            season_name = f"Temporada {season_year}-{season_year + 1}"

            competition, created = Competition.objects.get_or_create(
                name=season_name, defaults={"created_by": admin_user, **brazil_rules}
            )

            if created:
                self.stdout.write(
                    f"Created competition: {competition.name} with Brazilian rules"
                )
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

        # Limit teams based on configuration
        teams_to_create = team_data[:self.num_teams]
        
        for team_info in teams_to_create:
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
            teams_for_this_competition = teams_per_competition + (
                1 if i < remainder else 0
            )

            # Assign teams to this competition
            for j in range(teams_for_this_competition):
                if team_index < len(teams):
                    team = teams[team_index]
                    team.competition = competition
                    team.save()
                    team_index += 1

            self.stdout.write(
                f"  - Assigned {teams_for_this_competition} teams to {competition.name}"
            )

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
            "C": 4,  # Centers (maximum 4)
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

            self.stdout.write(
                f"Created {team.players.count()} players for {team.name} with proper position distribution"
            )

        return players

    def create_realistic_staff(self, teams, admin_user):
        """Create staff members for each team (Physio, S&C, Management)"""
        staff_members = []
        
        # Staff types to create for each team
        staff_types = [
            User.StaffType.PHYSIO,
            User.StaffType.STRENGTH_CONDITIONING,
            User.StaffType.MANAGEMENT,
        ]
        
        for team in teams:
            team_staff = []
            
            for staff_type in staff_types:
                staff_member = self.create_staff_member(team, staff_type, admin_user)
                team_staff.append(staff_member)
                # Add staff member to team
                team.staff.add(staff_member)  # Staff are stored in staff relationship
            
            staff_members.extend(team_staff)
            
            self.stdout.write(
                f"Created {len(team_staff)} staff members for {team.name}"
            )
        
        return staff_members

    def create_staff_member(self, team, staff_type, admin_user):
        """Create a single staff member with realistic characteristics"""
        # Brazilian staff names
        first_names = [
            "Carlos", "Ana", "Roberto", "Maria", "João", "Fernanda", "Pedro", "Juliana",
            "Rafael", "Camila", "Diego", "Patricia", "Lucas", "Beatriz", "André", "Larissa",
            "Felipe", "Gabriela", "Marcelo", "Isabela", "Ricardo", "Amanda", "Thiago", "Natália",
            "Bruno", "Carolina", "Eduardo", "Mariana", "Leonardo", "Vanessa", "Rodrigo", "Tatiana"
        ]
        
        last_names = [
            "Silva", "Santos", "Oliveira", "Souza", "Rodrigues", "Ferreira", "Almeida", "Pereira",
            "Lima", "Gomes", "Costa", "Ribeiro", "Carvalho", "Alves", "Pinto", "Cavalcanti",
            "Dias", "Castro", "Campos", "Cardoso", "Correia", "Cunha", "Dantas", "Duarte",
            "Farias", "Fernandes", "Freitas", "Gonçalves", "Machado", "Mendes", "Nascimento", "Pires"
        ]
        
        # International staff names (common in Brazilian basketball)
        international_first_names = [
            "Michael", "Sarah", "David", "Lisa", "James", "Jennifer", "Robert", "Michelle",
            "John", "Amanda", "William", "Jessica", "Richard", "Ashley", "Charles", "Emily",
            "Thomas", "Samantha", "Christopher", "Stephanie", "Daniel", "Nicole", "Matthew", "Elizabeth"
        ]
        
        international_last_names = [
            "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez",
            "Martinez", "Anderson", "Taylor", "Thomas", "Hernandez", "Moore", "Martin", "Lee",
            "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis"
        ]
        
        # 60% Brazilian, 40% International for staff
        if random.random() < 0.6:
            first_name = random.choice(first_names)
            last_name = random.choice(last_names)
        else:
            first_name = random.choice(international_first_names)
            last_name = random.choice(international_last_names)
        
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
            role=User.Role.STAFF,
            staff_type=staff_type,
        )
        
        # Set team
        user.team = team
        user.save()
        
        # Log creation
        staff_type_display = user.get_staff_type_display()
        self.stdout.write(
            f"  - Created {staff_type_display}: {first_name} {last_name} for {team.name}"
        )
        
        return user

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
        base_email = (
            f"{username}@{team.name.lower().replace(' ', '').replace('.', '')}.com"
        )
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
        
        # Calculate how many games to generate
        if self.games_per_season:
            # Use configured number of games
            total_games_needed = self.games_per_season
            self.stdout.write(f"Generating {total_games_needed} games for regular season...")
        else:
            # Auto-calculate: each team plays every other team twice (home and away)
            total_games_needed = len(teams) * (len(teams) - 1)
            self.stdout.write(f"Auto-calculating: {len(teams)} teams = {total_games_needed} games (each team plays every other team twice)")

        games_generated = 0
        
        # Each team plays every other team twice (home and away)
        for i, home_team in enumerate(teams):
            for j, away_team in enumerate(teams):
                if i != j and games_generated < total_games_needed:  # Don't play against yourself
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
                    games_generated += 1
                    
                    if games_generated >= total_games_needed:
                        break

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
        # Make timezone-aware
        from django.utils import timezone
        if timezone.is_naive(game_datetime):
            game_datetime = timezone.make_aware(game_datetime)

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
            "C": 2,  # Centers
        }

        # Home team roster
        home_roster = GameRoster.objects.create(game=game, team=game.home_team)
        home_roster_players = self.select_players_by_position(
            game.home_team, game_roster_distribution
        )
        home_roster.players.set(home_roster_players)
        home_roster.starting_five.set(self.select_starting_five(home_roster_players))

        # Away team roster
        away_roster = GameRoster.objects.create(game=game, team=game.away_team)
        away_roster_players = self.select_players_by_position(
            game.away_team, game_roster_distribution
        )
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
                    fillers = random.sample(
                        other_players, min(remaining_slots, len(other_players))
                    )
                    selected_players.extend(fillers)

        # Ensure we have exactly 12 players
        if len(selected_players) > 12:
            selected_players = random.sample(selected_players, 12)
        elif len(selected_players) < 12:
            # Fill remaining slots with any available players
            all_players = list(team.players.all())
            remaining = [p for p in all_players if p not in selected_players]
            if remaining:
                fillers = random.sample(
                    remaining, min(12 - len(selected_players), len(remaining))
                )
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
                if current_leader != "home":
                    if current_leader is not None:
                        lead_changes += 1
                    current_leader = "home"
            elif away_score > home_score:
                if current_leader != "away":
                    if current_leader is not None:
                        lead_changes += 1
                    current_leader = "away"

            score_progression.append(
                {
                    "possession": i,
                    "home_score": home_score,
                    "away_score": away_score,
                    "leader": current_leader,
                }
            )

        # Determine game characteristics
        final_margin = abs(home_score - away_score)
        is_close_game = final_margin <= 10
        is_blowout = final_margin >= 20

        # Simulate clutch situations (last 2 minutes of close games)
        clutch_situations = 0
        if is_close_game:
            # Last 2 minutes = last ~8-10 possessions
            clutch_possessions = possessions[-min(10, len(possessions)) :]
            clutch_situations = len(
                [p for p in clutch_possessions if p.points_scored > 0]
            )

        # Store game flow data
        game.lead_changes = lead_changes
        game.is_close_game = is_close_game
        game.is_blowout = is_blowout
        game.clutch_situations = clutch_situations
        game.save()

        return {
            "lead_changes": lead_changes,
            "is_close_game": is_close_game,
            "is_blowout": is_blowout,
            "clutch_situations": clutch_situations,
            "final_margin": final_margin,
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
                special_scenarios.append("buzzer_beater")
                self.stdout.write(
                    f"  - Buzzer beater by {buzzer_beater.team.team.name}!"
                )

        # Technical fouls (5% chance per game)
        if random.random() < 0.05:
            # Select a random player for technical foul
            all_players = list(game.home_team.players.all()) + list(
                game.away_team.players.all()
            )
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
                    technical_foul_player=tech_foul_player,
                )
                special_scenarios.append("technical_foul")
                self.stdout.write(
                    f"  - Technical foul on {tech_foul_player.first_name} {tech_foul_player.last_name}"
                )

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
                is_coach_challenge=True,
            )
            special_scenarios.append("coach_challenge")
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
                        "player": player,
                        "team": team,
                        "injury_duration": injury_duration,
                        "games_missed": 0,
                    }
                    injured_players.append(injury_info)

                    self.stdout.write(
                        f"  - {player.first_name} {player.last_name} ({team.name}) injured for {injury_duration} games"
                    )

        self.stdout.write(f"✓ Simulated injuries for {len(injured_players)} players")
        return injured_players

    def is_player_available(self, player, game_date, injured_players):
        """Check if a player is available for a specific game"""
        for injury in injured_players:
            if (
                injury["player"] == player
                and injury["games_missed"] < injury["injury_duration"]
            ):
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

        # Realistic possession count: use configured value or default range
        if self.possessions_per_game:
            # Use configured number with some variation
            variation = int(self.possessions_per_game * 0.1)  # 10% variation
            total_possessions = random.randint(
                self.possessions_per_game - variation,
                self.possessions_per_game + variation
            )
        else:
            # Default range: 85-110 per team, so 170-220 total
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
                    team=default_team, play_type="OFFENSIVE"
                ).values_list("name", flat=True)

                if offensive_plays.exists():
                    return random.choice(list(offensive_plays))

            # Fallback to common offensive plays from the JSON (excluding Control)
            fallback_plays = [
                "Set 1", "Set 2", "Set 3", "Set 4", "Set 5", "Set 6", "Set 7", "Set 8", "Set 9", "Set 10",
                "Set 11", "Set 12", "Set 13", "Set 14", "Set 15", "Set 16", "Set 17", "Set 18", "Set 19", "Set 20",
                "FastBreak", "Transit", "<14s", "BoB 1", "BoB 2", "SoB 1", "SoB 2", "Special 1", "Special 2", "ATO Spec",
                "PnR", "Score", "Big Guy", "3rd Guy", "ISO", "HighPost", "LowPost", "Attack CloseOut", 
                "After Kick Out", "After Ext Pass", "Cuts", "After Off Reb", "After HandOff", "After OffScreen"
            ]
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
                    team=default_team, play_type="DEFENSIVE"
                ).values_list("name", flat=True)

                if defensive_plays.exists():
                    return random.choice(list(defensive_plays))

            # Fallback to common defensive plays from the JSON (excluding Control)
            fallback_plays = [
                "SWITCH", "DROP", "HEDGE", "TRAP", "ICE", "FLAT", "WEAK",
                "2-3", "3-2", "1-3-1", "1-2-2", "zone",
                "Full court press", "3/4 court press", "Half court press", "ISO"
            ]
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
        """Load play definitions from JSON file, excluding Control category"""
        self.stdout.write("Loading play definitions from JSON file...")

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
                "Offense",
                "Defense",
                "Transition",
                "Set Plays",
                "Zone Defense",
            ]

            for cat_name in basic_categories:
                PlayCategory.objects.get_or_create(name=cat_name)

            self.stdout.write("✓ Created basic play categories")
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

        except FileNotFoundError:
            self.stdout.write(
                self.style.ERROR(f"Play definitions file not found at: {json_path}")
            )
            self.stdout.write("Creating basic play categories instead...")

            # Create basic play categories as fallback
            basic_categories = [
                "Offense",
                "Defense",
                "Transition",
                "Set Plays",
                "Zone Defense",
            ]

            for cat_name in basic_categories:
                PlayCategory.objects.get_or_create(name=cat_name)

            self.stdout.write("✓ Created basic play categories")

        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error loading play definitions: {e}"))
            self.stdout.write("Creating basic play categories instead...")

            # Create basic play categories as fallback
            basic_categories = [
                "Offense",
                "Defense",
                "Transition",
                "Set Plays",
                "Zone Defense",
            ]

            for cat_name in basic_categories:
                PlayCategory.objects.get_or_create(name=cat_name)

            self.stdout.write("✓ Created basic play categories")

    def generate_offensive_sequence(self, offensive_play, outcome):
        """Generate a realistic offensive sequence based on the play from JSON data"""
        # Get the play definition from the database to access subcategory
        try:
            from apps.teams.models import Team
            from apps.plays.models import PlayDefinition
            
            default_team = Team.objects.filter(name="Default Play Templates").first()
            if default_team:
                play_def = PlayDefinition.objects.filter(
                    team=default_team, 
                    name=offensive_play,
                    play_type="OFFENSIVE"
                ).first()
                
                if play_def and play_def.subcategory:
                    # Generate sequence based on subcategory from JSON
                    subcategory = play_def.subcategory.lower()
                    
                    if subcategory == "set":
                        return f"Set play {offensive_play} → Screen action → Shot attempt"
                    elif subcategory == "transition":
                        return f"Transition play {offensive_play} → Fast break → Shot attempt"
                    elif subcategory == "left":
                        return f"Left side play {offensive_play} → Ball movement → Shot attempt"
                    elif subcategory == "right":
                        return f"Right side play {offensive_play} → Ball movement → Shot attempt"
                    else:
                        return f"Offensive play {offensive_play} → Ball movement → Shot attempt"
        except Exception:
            pass
        
        # Fallback: generate sequence based on play name
        if "Set" in offensive_play:
            return f"Set play {offensive_play} → Screen action → Shot attempt"
        elif "FastBreak" in offensive_play or "Transit" in offensive_play:
            return f"Transition play {offensive_play} → Fast break → Shot attempt"
        elif "BoB" in offensive_play or "SoB" in offensive_play:
            return f"Out of bounds play {offensive_play} → Entry pass → Shot attempt"
        elif "Special" in offensive_play or "ATO" in offensive_play:
            return f"Special play {offensive_play} → Screen action → Shot attempt"
        elif offensive_play in ["PnR", "ISO", "HighPost", "LowPost"]:
            return f"Half court play {offensive_play} → Ball movement → Shot attempt"
        elif offensive_play.startswith("After"):
            return f"Follow-up play {offensive_play} → Ball movement → Shot attempt"
        else:
            base_sequence = f"Offensive play {offensive_play} → Ball movement → Shot attempt"

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
        """Generate a realistic defensive sequence based on the play from JSON data"""
        # Get the play definition from the database to access subcategory
        try:
            from apps.teams.models import Team
            from apps.plays.models import PlayDefinition
            
            default_team = Team.objects.filter(name="Default Play Templates").first()
            if default_team:
                play_def = PlayDefinition.objects.filter(
                    team=default_team, 
                    name=defensive_play,
                    play_type="DEFENSIVE"
                ).first()
                
                if play_def and play_def.subcategory:
                    # Generate sequence based on subcategory from JSON
                    subcategory = play_def.subcategory.lower()
                    
                    if subcategory == "pnr":
                        return f"Pick and roll defense {defensive_play} → Contest shot → Box out"
                    elif subcategory == "zone":
                        return f"Zone defense {defensive_play} → Collapse on penetration → Contest shot"
                    elif subcategory == "zone press":
                        return f"Press defense {defensive_play} → Trap ball handler → Force turnover"
                    elif subcategory == "other":
                        return f"Defensive play {defensive_play} → Contest shot → Box out"
                    else:
                        return f"Defensive play {defensive_play} → Contest shot → Box out"
        except Exception:
            pass
        
        # Fallback: generate sequence based on play name
        if defensive_play in ["SWITCH", "DROP", "HEDGE", "TRAP", "ICE", "FLAT", "WEAK"]:
            return f"Pick and roll defense {defensive_play} → Contest shot → Box out"
        elif defensive_play in ["2-3", "3-2", "1-3-1", "1-2-2", "zone"]:
            return f"Zone defense {defensive_play} → Collapse on penetration → Contest shot"
        elif "press" in defensive_play.lower():
            return f"Press defense {defensive_play} → Trap ball handler → Force turnover"
        elif defensive_play == "ISO":
            return f"Isolation defense {defensive_play} → Contest shot → Box out"
        else:
            base_sequence = f"Defensive play {defensive_play} → Contest shot → Box out"

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
