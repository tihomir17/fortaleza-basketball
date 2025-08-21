// lib/core/navigation/coach_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/widgets/coach_sidebar.dart';

class CoachScaffold extends StatelessWidget {
  final Widget child;
  const CoachScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // WIDE SCREEN (Web/Tablet)
        if (constraints.maxWidth > 768) {
          return Scaffold(
            body: Row(
              children: [
                const CoachSidebar(), // The permanent sidebar
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: child), // The main content
              ],
            ),
          );
        }

        // NARROW SCREEN (Mobile)
        // The child screen is now responsible for its own AppBar and for
        // opening the drawer.
        return Scaffold(drawer: const CoachSidebar(), body: child);
      },
    );
  }
}
