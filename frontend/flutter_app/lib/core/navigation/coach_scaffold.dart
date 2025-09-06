// lib/core/navigation/coach_scaffold.dart
import 'package:flutter/material.dart';
import 'package:fortaleza_basketball_analytics/core/widgets/coach_sidebar.dart';
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
            if (constraints.maxWidth > 768) {
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

                    // --- THE NEW FLOATING TOGGLE BUTTON ---
                    Positioned(
                      left: sidebarVisible
                          ? 240
                          : 10, // Adjust position based on sidebar state
                      top: 20,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            onTap: () {
                              isSidebarVisible.value = !isSidebarVisible.value;
                              logger.i('CoachScaffold: Toggled sidebar visibility to ${isSidebarVisible.value}');
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                sidebarVisible
                                    ? Icons.arrow_back_ios_new
                                    : Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // --- NARROW SCREEN (Mobile) ---
            // The mobile drawer experience remains the same.
            return Scaffold(drawer: const CoachSidebar(), body: child);
          },
        );
      },
    );
  }
}
