# Basketball Analytics App

This is the frontend application for the Basketball Analytics platform, built with Flutter. It provides a responsive UI for web, tablet, and mobile that allows coaches and players to manage their teams, analyze games, and log detailed possession data.

## Features

- **Cross-Platform:** A single codebase supports Web, Android, and iOS.
- **Responsive UI:** Features a persistent sidebar for wide screens (desktop/tablet) and a standard drawer/bottom navigation for mobile.
- **Role-Based Dashboards:** The user interface adapts to show relevant tools for Admins, Coaches, and Players.
- **State Management:** Uses `flutter_bloc` (Cubit) for predictable and scalable state management.
- **Persistent State:** User sessions and theme preferences are saved locally, surviving page refreshes and app restarts.
- **Declarative Routing:** Uses `go_router` for a robust, URL-based navigation system.
- **Full Data Management:** Provides interfaces for all CRUD (Create, Read, Update, Delete) operations exposed by the backend API.
- **Light & Dark Themes:** A complete, user-selectable theme system.

---

## Getting Started

### Prerequisites

- Flutter SDK (version 3.x or higher)
- An IDE like VS Code or Android Studio (with Flutter plugins)
- A web browser (like Chrome) for web development
- An Android Emulator or iOS Simulator for mobile development

### Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone <your-repository-url>
    cd <repository-name>/frontend/flutter_app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure the Backend API URL:**
    - Open the file `lib/core/api/api_client.dart`.
    - Change the `baseUrl` constant to match the address of your running Django backend.
      - For a local web build, this is typically `http://127.0.0.1:8000/api`.
      - For the Android Emulator, this must be `http://10.0.2.2:8000/api`.

4.  **Run the application:**
    - **For Web:**
      ```bash
      flutter run -d chrome
      ```
    - **For Mobile (with an open emulator/simulator):**
      ```bash
      flutter run
      ```

---

## Project Structure

The project follows a feature-first architecture, which keeps code organized and scalable.

-   `lib/core/`: Contains shared code used by all features.
    -   `api/`: API client configuration.
    -   `navigation/`: `GoRouter` setup and main scaffold widgets.
    -   `theme/`: The central `AppTheme` and `ThemeCubit`.
    -   `widgets/`: Reusable widgets like the `UserProfileAppBar`.
-   `lib/features/`: Each subdirectory is a self-contained feature.
    -   `authentication/`: Login, user models, repositories, and state.
    -   `dashboard/`: The main dashboard screen.
    -   `teams/`: Team list, detail, and roster management.
    -   `games/`: Game list and detail/analysis screens.
    -   `plays/`: Playbook hub, editor, and viewer.
    -   `possessions/`: The possession logging screen.
    -   `competitions/`: Competition models and state.
-   `main.dart`: The entry point of the application, responsible for initializing dependencies (`GetIt`) and providers (`MultiBlocProvider`).