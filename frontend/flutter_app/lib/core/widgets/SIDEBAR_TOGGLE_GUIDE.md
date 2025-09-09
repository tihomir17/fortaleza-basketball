# Sidebar Toggle Implementation Guide

This guide explains how to add sidebar toggle functionality to any screen in the app.

## Overview

The sidebar toggle functionality allows users to collapse/hide the Coach Menu sidebar on every screen. This is implemented using a global `ValueNotifier<bool> isSidebarVisible` that controls the sidebar visibility across the entire app.

## Components

### 1. SidebarToggleButton
A reusable widget that creates a toggle button for the sidebar.

**Usage:**
```dart
import 'package:fortaleza_basketball_analytics/core/widgets/sidebar_toggle_button.dart';

// Basic toggle button
SidebarToggleButton()

// Floating button
SidebarToggleButton(showAsFloatingButton: true)

// Custom styling
SidebarToggleButton(
  size: 48,
  backgroundColor: Colors.blue,
  iconColor: Colors.white,
)
```

### 2. SidebarToggleAppBarButton
A pre-configured button for use in AppBars.

**Usage:**
```dart
AppBar(
  leading: const SidebarToggleAppBarButton(),
  title: Text('My Screen'),
)
```

### 3. ScreenWithSidebarToggle
A wrapper that adds a floating sidebar toggle to any widget.

**Usage:**
```dart
ScreenWithSidebarToggle(
  child: YourScreenContent(),
)
```

### 4. ScaffoldWithSidebarToggle
A Scaffold wrapper that includes sidebar toggle functionality.

**Usage:**
```dart
ScaffoldWithSidebarToggle(
  appBar: AppBar(title: Text('My Screen')),
  body: YourScreenContent(),
)
```

## Implementation Methods

### Method 1: Screens with UserProfileAppBar (Automatic)
Screens that use `UserProfileAppBar` automatically get the sidebar toggle button in the AppBar's leading position.

**Screens that already have this:**
- Dashboard
- Calendar
- Games
- Live Tracking
- Scouting Reports
- Self Scouting
- Home

### Method 2: Screens with Custom AppBar
For screens that use their own AppBar, add the sidebar toggle as the leading widget:

```dart
AppBar(
  leading: const SidebarToggleAppBarButton(),
  title: Text('My Screen'),
  // ... other AppBar properties
)
```

### Method 3: Screens with Custom Scaffold
For screens that need their own Scaffold, use `ScaffoldWithSidebarToggle`:

```dart
ScaffoldWithSidebarToggle(
  appBar: AppBar(title: Text('My Screen')),
  body: YourScreenContent(),
)
```

### Method 4: Screens without AppBar
For screens without an AppBar, wrap the content with `ScreenWithSidebarToggle`:

```dart
ScreenWithSidebarToggle(
  child: YourScreenContent(),
)
```

## Quick Migration Guide

### For screens with custom AppBar:
1. Import the sidebar toggle button:
   ```dart
   import 'package:fortaleza_basketball_analytics/core/widgets/sidebar_toggle_button.dart';
   ```

2. Add the toggle button to your AppBar:
   ```dart
   AppBar(
     leading: const SidebarToggleAppBarButton(),
     // ... rest of your AppBar
   )
   ```

### For screens with custom Scaffold:
1. Import the scaffold wrapper:
   ```dart
   import 'package:fortaleza_basketball_analytics/core/widgets/screen_with_sidebar_toggle.dart';
   ```

2. Replace `Scaffold` with `ScaffoldWithSidebarToggle`:
   ```dart
   ScaffoldWithSidebarToggle(
     appBar: yourAppBar,
     body: yourBody,
   )
   ```

## Examples

### Example 1: Edit User Screen
```dart
// Before
return Scaffold(
  appBar: AppBar(title: Text('Edit User')),
  body: Form(...),
);

// After
return ScaffoldWithSidebarToggle(
  appBar: AppBar(title: Text('Edit User')),
  body: Form(...),
);
```

### Example 2: Custom AppBar Screen
```dart
// Before
AppBar(
  title: Text('My Screen'),
  actions: [IconButton(...)],
)

// After
AppBar(
  leading: const SidebarToggleAppBarButton(),
  title: Text('My Screen'),
  actions: [IconButton(...)],
)
```

### Example 3: Screen without AppBar
```dart
// Before
return Container(
  child: YourContent(),
);

// After
return ScreenWithSidebarToggle(
  child: Container(
    child: YourContent(),
  ),
);
```

## Testing

To test the sidebar toggle functionality:

1. Navigate to any screen
2. Look for the sidebar toggle button (hamburger menu icon)
3. Click the button to toggle sidebar visibility
4. Verify the sidebar collapses/expands smoothly
5. Check that the button icon changes appropriately

## Notes

- The sidebar toggle state is global and persists across screen navigation
- The toggle button automatically positions itself based on sidebar state
- On mobile devices, the sidebar appears as a drawer (standard Flutter behavior)
- The toggle button includes smooth animations for better UX
