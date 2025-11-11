import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


import '../../../profile/models/user_fitness_model.dart';
import '../../../profile/services/user_service.dart';


class WorkoutSectionDetailScreen extends StatefulWidget {
  const WorkoutSectionDetailScreen({super.key});

  @override
  State<WorkoutSectionDetailScreen> createState() =>
      _WorkoutSectionDetailScreenState();
}

class _WorkoutSectionDetailScreenState
    extends State<WorkoutSectionDetailScreen> {
  final _userService = UserService();
  UserFitnessModel? _fitnessData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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
      return const Scaffold(
        body: Center(
            child: Text("No fitness data found. Please update your profile.")),
      );
    }

    // --- Extract user data ---
    final bmi = _fitnessData!.bmi;
    final bmr = _fitnessData!.bmr;
    final weight = _fitnessData!.weight;
    final height = _fitnessData!.height;
    final age = _fitnessData!.age;
    final gender = _fitnessData!.gender;

    final String category = _getBmiCategory(bmi);
    final String planTitle = _getPlanTitle(category);

    final List<Map<String, String>> recommendedSections =
    _getWorkoutPlan(category);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Personalized Workout Plan"),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧠 User Fitness Overview Card
              _buildUserStatsCard(
                context,
                bmi,
                bmr,
                height,
                weight,
                age,
                gender,
                category,
              ),
              const SizedBox(height: 24),

              // 🏋️ Plan Title
              Text(planTitle,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontWeight: FontWeight.bold, shadows: [
                    const Shadow(
                        blurRadius: 1,
                        offset: Offset(1, 1),
                        color: Colors.black26),
                    const Shadow(
                        blurRadius: 3,
                        offset: Offset(-1, -1),
                        color: Colors.black26),
                  ])),

              const SizedBox(height: 12),
              Text(
                "Based on your BMI and BMR, here’s your personalized workout plan for ${DateFormat('EEEE, MMM d').format(DateTime.now())}:",
                style: const TextStyle(color: Colors.black54, shadows: [
                  Shadow(
                      blurRadius: 1,
                      offset: Offset(0.5, 0.5),
                      color: Colors.white)
                ]),
              ),

              const SizedBox(height: 20),

              // 💪 Recommended Workouts
              ...recommendedSections.map((section) {
                return _buildWorkoutCard(
                  context,
                  title: section['title']!,
                  subtitle: section['desc']!,
                  color: colorScheme.primary.withOpacity(0.9),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // --- 🧩 Components ---

  Widget _buildUserStatsCard(
      BuildContext context,
      double bmi,
      double bmr,
      double height,
      double weight,
      int age,
      String gender,
      String category) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: colorScheme.primary.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.fitness_center, size: 48, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("BMI: ${bmi.toStringAsFixed(1)}  •  $category",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 1, offset: Offset(1, 1))])),
                  const SizedBox(height: 6),
                  Text(
                    "BMR: ${bmr.toStringAsFixed(0)} kcal/day",
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(blurRadius: 1, offset: Offset(1, 1))]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                      "Height: ${height.toStringAsFixed(0)} cm, "
                      "Weight: ${weight.toStringAsFixed(0)} kg",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, shadows: [
                        Shadow(blurRadius: 1, offset: Offset(1, 1))
                      ])),
                  Text("Age: $age, Gender: $gender",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, shadows: [Shadow(blurRadius: 1, offset: Offset(1, 1))])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context,
      {required String title,
        required String subtitle,
        required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.3),
          child: const Icon(Icons.accessibility_new, color: Colors.white),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [Shadow(blurRadius: 1, offset: Offset(1, 1))])),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.3, shadows: [
              Shadow(blurRadius: 1, offset: Offset(1, 1))
            ])),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 1, offset: Offset(1, 1))]),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Opening $title..."),
          ));
        },
      ),
    );
  }

  // --- 🧮 Logic Helpers ---

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  String _getPlanTitle(String category) {
    switch (category) {
      case "Underweight":
        return "🏋️ Gain Healthy Muscle Mass";
      case "Normal":
        return "💪 Maintain Your Fitness & Strength";
      case "Overweight":
        return "🔥 Fat-Burning & Conditioning Plan";
      case "Obese":
        return "⚡ Weight Loss & Endurance Routine";
      default:
        return "Your Personalized Plan";
    }
  }

  List<Map<String, String>> _getWorkoutPlan(String category) {
    switch (category) {
      case "Underweight":
        return [
          {
            'title': 'Upper Body Strength',
            'desc': 'Focus on compound lifts to build lean muscle.'
          },
          {
            'title': 'Lower Body Power',
            'desc': 'Leg workouts to improve mass and stability.'
          },
          {
            'title': 'Warm-up Mobility',
            'desc': 'Dynamic stretches to prepare your muscles.'
          },
        ];
      case "Normal":
        return [
          {
            'title': 'Balanced Routine',
            'desc': 'Full body workouts for muscle maintenance.'
          },
          {
            'title': 'Cardio Endurance',
            'desc': 'Moderate intensity cardio 3× a week.'
          },
          {
            'title': 'Core Strength',
            'desc': 'Planks, crunches, and balance drills.'
          },
        ];
      case "Overweight":
        return [
          {
            'title': 'HIIT Fat Burn',
            'desc': 'Short bursts of high intensity workouts.'
          },
          {
            'title': 'Lower Body Sculpt',
            'desc': 'Target legs and glutes for maximum calorie burn.'
          },
          {
            'title': 'Stretch & Cooldown',
            'desc': 'Light stretches to aid recovery.'
          },
        ];
      case "Obese":
        return [
          {
            'title': 'Low-Impact Cardio',
            'desc': 'Gentle fat-burning movements with minimal joint strain.'
          },
          {
            'title': 'Resistance Basics',
            'desc': 'Use bodyweight or light bands to improve mobility.'
          },
          {
            'title': 'Recovery & Breathing',
            'desc': 'Cool down with deep breathing and mobility.'
          },
        ];
      default:
        return [];
    }
  }
}
