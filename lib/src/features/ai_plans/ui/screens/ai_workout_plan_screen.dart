// src/features/ai_plans/ui/screens/ai_workout_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AIWorkoutPlanScreen extends StatelessWidget {
  const AIWorkoutPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A simple list of workout sections
    final List<Map<String, String>> sections = [
      {'title': 'Warm-up', 'progress': '100% Complete', 'id': 'warmup'},
      {'title': 'Main Set: Upper Body', 'progress': '50% Complete', 'id': 'upper_body'},
      {'title': 'Main Set: Lower Body', 'progress': '0% Complete', 'id': 'lower_body'},
      {'title': 'Cool Down', 'progress': '0% Complete', 'id': 'cool_down'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Your Personalized Workout Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Today: Full Body Strength', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),

            // Use Expanded and ListView for a scrollable list
            Expanded(
              child: ListView.builder(
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _buildExerciseSection(
                    context: context,
                    title: section['title']!,
                    progress: section['progress']!,
                    // Make the card tappable
                    onTap: () {
                      // Navigate to the new detail screen, passing the section title
                      context.push('/dashboard/workout_details/${section['id']!}');
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16), // Add space before the button

            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Workout'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                // --- FIX: Use the correct nested path and 'push' ---
                context.push('/dashboard/live_ai_workout');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Updated to include context and an onTap function
  Widget _buildExerciseSection({
    required BuildContext context,
    required String title,
    required String progress,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      // Use InkWell for the tap effect on the Card
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Match Card's default radius
        child: ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(progress),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}