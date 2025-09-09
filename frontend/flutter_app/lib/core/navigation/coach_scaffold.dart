// lib/core/navigation/coach_scaffold.dart
import 'package:flutter/material.dart';
import 'package:fortaleza_basketball_analytics/core/widgets/coach_sidebar.dart';
import 'package:fortaleza_basketball_analytics/core/widgets/mobile_menu_button.dart';
import 'package:fortaleza_basketball_analytics/main.dart';

class CoachScaffold extends StatelessWidget {
  final Widget child;
  const CoachScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    logger.d('CoachScaffold: Building scaffold.');
    // ValueListenableBuilder listens to our global notifier and rebuilds when it changes.
    return ValueListenableBuilder<bool>(
      valueListenable: isSidebarVisible,
      builder: (context, sidebarVisible, _) {
        logger.d('CoachScaffold: Sidebar visibility changed to $sidebarVisible.');
        // Use LayoutBuilder to handle responsive design (mobile vs. web)
        return LayoutBuilder(
          builder: (context, constraints) {
            logger.d('CoachScaffold: Layout rebuilt. Max width: ${constraints.maxWidth}');
            // --- WIDE SCREEN (Web/Tablet) ---
            // Match JavaScript logic: treat anything under 1024px as mobile
            if (constraints.maxWidth > 1024) {
              logger.d('CoachScaffold: Using desktop sidebar layout (width: ${constraints.maxWidth})');
              return Scaffold(
                body: Stack(
                  // Use a Stack to overlay the button
                  children: [
                    // The main content is at the bottom of the stack
                    Row(
                      children: [
                        // Conditionally show the sidebar based on the notifier's value
                        if (sidebarVisible) const CoachSidebar(),

                        // Use an AnimatedContainer for a smooth collapse/expand animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: sidebarVisible ? 1 : 0,
                          child: const VerticalDivider(width: 1, thickness: 1),
                        ),
                        Expanded(child: child),
                      ],
                    ),

                    // Floating toggle button removed - now handled by UserProfileAppBar
                  ],
                ),
              );
            }

            // --- NARROW SCREEN (Mobile) ---
            // The mobile drawer experience with proper configuration
            logger.d('CoachScaffold: Using mobile drawer layout (width: ${constraints.maxWidth})');
            return Scaffold(
              drawer: const CoachSidebar(),
              drawerEnableOpenDragGesture: true, // Enable swipe to open
              drawerEdgeDragWidth: 20, // Wider drag area for easier opening
              body: Stack(
                children: [
                  child,
                  // Working mobile menu button positioned in top-left corner
                  Positioned(
                    top: 16,
                    left: 16,
                    child: const MobileMenuLargeButton(
                      tooltip: 'Open Menu',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
