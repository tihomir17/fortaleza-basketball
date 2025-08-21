// lib/features/scouting/presentation/screens/scouting_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/widgets/user_profile_app_bar.dart';

class ScoutingReportsScreen extends StatelessWidget {
  const ScoutingReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserProfileAppBar(title: 'SCOUTING REPORTS'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 100,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                'Scouting Reports',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'This section will display opponent scouting materials and videos uploaded by the coaching staff.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
