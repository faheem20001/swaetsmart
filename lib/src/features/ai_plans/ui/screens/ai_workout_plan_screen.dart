import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AIWorkoutPlanScreen extends StatelessWidget {
  const AIWorkoutPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Personalized Workout Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Today: Full Body Strength', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            _buildExerciseSection('Warm-up', '100% Complete'),
            _buildExerciseSection('Main Set: Upper Body', '50% Complete'),
            _buildExerciseSection('Main Set: Lower Body', '0% Complete'),
            _buildExerciseSection('Cool Down', '0% Complete'),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Workout'),
              onPressed: () => GoRouter.of(context).go('/live_ai_workout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSection(String title, String progress) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(progress),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}