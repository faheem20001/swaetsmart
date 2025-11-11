// src/features/workouts/ui/screens/workout_section_detail_screen.dart

import 'package:flutter/material.dart';

class WorkoutSectionDetailScreen extends StatelessWidget {
  // This 'sectionId' will be passed by GoRouter
  final String sectionId;

  const WorkoutSectionDetailScreen({
    super.key,
    required this.sectionId,
  });

  // Helper function to get dummy data based on the ID
  Map<String, dynamic> _getSectionData(String id) {
    final Map<String, Map<String, dynamic>> dummyData = {
      'warmup': {
        'title': 'Warm-up',
        'exercises': ['Jumping Jacks (2 min)', 'Arm Circles (1 min)', 'Leg Swings (1 min)'],
      },
      'upper_body': {
        'title': 'Main Set: Upper Body',
        'exercises': ['Push-ups (3 sets of 10)', 'Dumbbell Rows (3 sets of 12)', 'Overhead Press (3 sets of 10)'],
      },
      'lower_body': {
        'title': 'Main Set: Lower Body',
        'exercises': ['Squats (3 sets of 12)', 'Lunges (3 sets of 10 per leg)', 'Calf Raises (3 sets of 15)'],
      },
      'cool_down': {
        'title': 'Cool Down',
        'exercises': ['Quad Stretch (30 sec per side)', 'Hamstring Stretch (30 sec per side)', 'Child\'s Pose (1 min)'],
      }
    };
    // Return the specific section's data, or a default if not found
    return dummyData[id] ?? {'title': 'Unknown Section', 'exercises': []};
  }

  @override
  Widget build(BuildContext context) {
    final sectionData = _getSectionData(sectionId);
    final String title = sectionData['title'];
    final List<String> exercises = sectionData['exercises'];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(exercises[index]),
              subtitle: const Text('Tap to see instructions...'),
              onTap: () {
                // You could navigate even deeper here
              },
            ),
          );
        },
      ),
    );
  }
}