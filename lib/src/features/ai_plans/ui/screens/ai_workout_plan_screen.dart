// src/features/ai_plans/ui/screens/ai_workout_plan_screen.dart

import 'package:flutter/material.dart';
import '../../../profile/services/user_service.dart';
import '../../../profile/models/user_fitness_model.dart';
import '../../../workouts/ui/screens/live_ai_workout_screen.dart';


class AIWorkoutPlanScreen extends StatefulWidget {
  const AIWorkoutPlanScreen({super.key});

  @override
  State<AIWorkoutPlanScreen> createState() => _AIWorkoutPlanScreenState();
}

class _AIWorkoutPlanScreenState extends State<AIWorkoutPlanScreen> {
  UserFitnessModel? _fitnessData;
  bool _loading = true;
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _userService.getUserFitnessData();
    setState(() {
      _fitnessData = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_fitnessData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("AI Workout Plan")),
        body: const Center(child: Text("Please add your fitness data in Profile first.")),
      );
    }

    final user = _fitnessData!;
    final bmi = user.bmi.toStringAsFixed(1);
    final bmr = user.bmr.toStringAsFixed(0);

    // 🧠 AI logic for simple recommendations
    String recommendation;
    if (user.bmi < 18.5) {
      recommendation = "You're underweight. Focus on strength training & calorie surplus.";
    } else if (user.bmi < 24.9) {
      recommendation = "You’re in a healthy range! Maintain with a mix of cardio and weights.";
    } else if (user.bmi < 29.9) {
      recommendation = "You’re slightly above ideal weight. Cardio & HIIT will help most.";
    } else {
      recommendation = "Obese range. Focus on low-impact cardio and calorie control.";
    }

    final List<Map<String, dynamic>> suggestions = [
      {
        "icon": Icons.directions_run,
        "title": "Cardio",
        "subtitle": "Boost endurance and heart health.",
        "details": "Try 20–30 minutes of brisk walking, cycling, or jogging.",
      },
      {
        "icon": Icons.fitness_center,
        "title": "Strength Training",
        "subtitle": "Increase muscle mass & metabolism.",
        "details": "Do 3 sets of squats, lunges, and pushups with moderate weights.",
      },
      {
        "icon": Icons.self_improvement,
        "title": "Stretch & Mobility",
        "subtitle": "Enhance recovery and flexibility.",
        "details": "Include yoga or light stretching for 15 minutes post workout.",
      },
      {
        "icon": Icons.local_fire_department,
        "title": "BMR Target",
        "subtitle": "Maintain calorie goal of ~$bmr kcal/day.",
        "details": "Your workouts should burn about 15–25% of this daily.",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('AI Personalized Workout Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileSummaryCard(context, user),
            const SizedBox(height: 16),

            Text(
              "AI Insights",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              recommendation,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),
            Text(
              "Today's Recommendations",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // Build suggestion cards
            ...suggestions.map((item) => _buildSuggestionCard(
              icon: item["icon"],
              title: item["title"],
              subtitle: item["subtitle"],
              details: item["details"],
              color: colorScheme.primaryContainer.withOpacity(0.5),
            )),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Live AI Workout'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveAIWorkoutScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard(BuildContext context, UserFitnessModel user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.primaryContainer.withOpacity(0.6),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Your Fitness Overview",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric("Height", "${user.height} cm", Icons.height),
                _metric("Weight", "${user.weight} kg", Icons.monitor_weight),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric("BMI", user.bmi.toStringAsFixed(1), Icons.calculate),
                _metric("BMR", "${user.bmr.toStringAsFixed(0)} kcal", Icons.local_fire_department),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Age: ${user.age}, Gender: ${user.gender}",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.deepOrangeAccent),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String details,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.deepOrangeAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
