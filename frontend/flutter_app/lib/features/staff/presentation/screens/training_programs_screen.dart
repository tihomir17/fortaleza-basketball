// lib/features/staff/presentation/screens/training_programs_screen.dart
import 'package:flutter/material.dart';

class TrainingProgramsScreen extends StatelessWidget {
  const TrainingProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Programs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement add training program functionality
            },
            tooltip: 'Add Training Program',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Training Programs',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This feature will be implemented to create and manage strength & conditioning programs, workout plans, and training schedules.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
