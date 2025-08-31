# Basketball Analytics API

This is the backend API for the Basketball Analytics platform, built with Python, Django, and Django REST Framework. It provides all the necessary endpoints to manage competitions, games, teams, players, coaches, playbooks, and game possessions.

## Features

- **Role-Based Authentication:** JWT-based authentication for Superusers, Coaches, and Players.
- **Data Management:** Full CRUD (Create, Read, Update, Delete) APIs for all major data models.
- **Hierarchical Playbooks:** Create and manage complex, nested offensive and defensive plays.
- **Detailed Possession Logging:** Store granular, sequential data for post-game analysis.
- **Secure Permissions:** A robust permission system ensures users can only access and modify data for teams they are a member of.

---

## Getting Started

### Prerequisites

- Python 3.10+
- Pip (Python Package Installer)
- A virtual environment tool (like `venv` or `virtualenv`)

### Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone <your-repository-url>
    cd <repository-name>/backend
    ```

2.  **Create and activate a virtual environment:**
    - On macOS/Linux:
      ```bash
      python3 -m venv venv
      source venv/bin/activate
      ```
    - On Windows:
      ```bash
      python -m venv venv
      .\venv\Scripts\activate
      ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
    *(Note: If you don't have a `requirements.txt` file yet, you can create one with `pip freeze > requirements.txt`)*

4.  **Run database migrations:**
    This will create the `db.sqlite3` file and set up all the necessary database tables.
    ```bash
    python manage.py makemigrations
    python manage.py migrate
    ```

5.  **Create a superuser account:**
    This account will have full access to the Django Admin interface.
    ```bash
    python manage.py createsuperuser
    ```
    Follow the prompts to set a username, email, and password.

6.  **Run the development server:**
    ```bash
    python manage.py runserver
    ```
    The API will now be running at `http://127.0.0.1:8000/`.

---

## Project Structure

-   `basketball_analytics/`: Contains the main project settings and URL configuration.
-   `apps/`: A directory containing the individual Django apps, each with a specific responsibility:
    -   `users`: Manages user accounts, roles, and authentication.
    -   `competitions`: Manages league/competition data.
    -   `teams`: Manages team data and rosters.
    -   `games`: Manages individual game data.
    -   `plays`: Manages the hierarchical playbook definitions.
    -   `possessions`: Manages the logged possession data.
-   `manage.py`: The command-line utility for interacting with the Django project.

## API Endpoints

The API is browsable via Django REST Framework. The main endpoints are available under the `/api/` path:

-   `/api/auth/login/`: User login (obtains JWT).
-   `/api/auth/register/`: User registration.
-   `/api/auth/me/`: Get current user's details.
-   `/api/competitions/`
-   `/api/games/`
-   `/api/teams/`
-   `/api/users/`
-   `/api/plays/`
-   `/api/possessions/`

## Running Linters

To ensure code quality and consistency, we use `flake8` for linting and `black` for formatting.

1.  **Check for linting errors:**
    ```bash
    flake8 .
    ```

2.  **Automatically format the code:**
    ```bash
    black .
    ```

## Cleanup and Maintenance

### Automated Cleanup

The project includes a cleanup script that removes temporary files, cache files, and other generated content:

```bash
python cleanup.py
```

This script will remove:
- Python cache files (`__pycache__/`, `*.pyc`)
- Django temporary files (`db.sqlite3`, `db.sqlite3-journal`, `logs/`)
- Test cache files (`.pytest_cache/`, `coverage.xml`, `htmlcov/`)
- IDE files (`.vscode/`, `.idea/`)
- OS-specific files (`.DS_Store`, `Thumbs.db`)

### Manual Cleanup

If you prefer to clean up manually, you can:

1. **Remove Python cache:**
   ```bash
   find . -type d -name "__pycache__" -exec rm -rf {} +
   find . -name "*.pyc" -delete
   ```

2. **Remove database files:**
   ```bash
   rm -f db.sqlite3 db.sqlite3-journal
   ```

3. **Remove log files:**
   ```bash
   rm -rf logs/
   ```

4. **Remove test cache:**
   ```bash
   rm -rf .pytest_cache/ coverage.xml htmlcov/
   ```

### After Cleanup

After running the cleanup script, you'll need to:

1. **Recreate migrations:**
   ```bash
   python manage.py makemigrations
   ```

2. **Apply migrations:**
   ```bash
   python manage.py migrate
   ```

3. **Populate the database:**
   ```bash
   python manage.py populate_db
   ```

4. **Start the development server:**
   ```bash
   python manage.py runserver
   ```

## Git Ignore

The project includes a comprehensive `.gitignore` file that excludes:
- Python cache and compiled files
- Virtual environments
- Database files
- Log files
- IDE-specific files
- OS-generated files
- Test coverage reports
- Temporary files

This ensures that only source code and configuration files are tracked in version control.