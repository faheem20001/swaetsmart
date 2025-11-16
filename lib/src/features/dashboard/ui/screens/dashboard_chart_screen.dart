import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/daily_progress_model.dart';
import '../../services/progress_service.dart';
import 'package:percent_indicator/percent_indicator.dart'; // ✅ Add this in pubspec.yaml

class DashboardChartScreen extends StatefulWidget {
  const DashboardChartScreen({super.key});

  @override
  State<DashboardChartScreen> createState() => _DashboardChartScreenState();
}

class _DashboardChartScreenState extends State<DashboardChartScreen> {
  final _progressService = ProgressService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<DailyProgressModel> _progressData = [];
  Map<String, dynamic>? _profileData;
  bool _loading = true;
  double _latestReps = 0;
  double _latestWorkoutCalories = 0;
  double _todaysCalories = 0;
  double _fatBurned = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Fetch profile data
      final profileSnap =
      await _firestore.collection('users').doc(user.uid).get();
      _profileData = profileSnap.data();

      // Fetch progress data (aggregated)
      _progressData = await _progressService.fetchProgressData();

      // Fetch last workout
      final workoutSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_progress')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (workoutSnap.docs.isNotEmpty) {
        final latestWorkout = workoutSnap.docs.first.data();
        _latestReps = (latestWorkout['reps'] ?? 0).toDouble();
        _latestWorkoutCalories =
            (latestWorkout['caloriesBurned'] ?? 0).toDouble();
      }

      // Calculate today’s total calories burned
      final today = DateTime.now();
      final todayData = _progressData.where((p) =>
      p.date.year == today.year &&
          p.date.month == today.month &&
          p.date.day == today.day);

      _todaysCalories = todayData.isNotEmpty
          ? todayData.first.caloriesBurned + _latestWorkoutCalories
          : _latestWorkoutCalories;

      // 1 gram of fat = ~9 kcal, so fat burned (approx)
      _fatBurned = _todaysCalories / 9000;

      setState(() => _loading = false);
    } catch (e) {
      debugPrint("Dashboard load error: $e");
      setState(() => _loading = false);
    }
  }

  // 🧠 Dynamic suggestion logic
  String _generateSuggestion() {
    if (_profileData == null) return "Keep tracking your progress daily!";
    final bmi = (_profileData!['bmi'] ?? 0).toDouble();
    final bmr = (_profileData!['bmr'] ?? 0).toDouble();
    final burned = _todaysCalories;

    final percent = burned / bmr;
    if (bmi < 18.5) {
      return "Eat more balanced calories 🥦, your BMR goal is ${bmr.toStringAsFixed(0)} kcal!";
    } else if (bmi < 25) {
      return percent >= 1.0
          ? "Great! You’ve hit your daily goal 💪"
          : "You’re at ${(percent * 100).toStringAsFixed(0)}% of your goal 🔥 Keep going!";
    } else if (bmi < 30) {
      return percent >= 0.8
          ? "Solid progress! Burn a little more to stay ahead 🏃‍♂️"
          : "Push for a short cardio burst to reach your target!";
    } else {
      return "Focus on consistent calorie deficit & daily walks 🚶‍♂️";
    }
  }

  // 🎨 BMI Color Map
  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blueAccent;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bmi = (_profileData?['bmi'] ?? 0).toDouble();
    final bmr = (_profileData?['bmr'] ?? 2000).toDouble();
    final age = (_profileData?['age'] ?? 0).toInt();
    final height = (_profileData?['height'] ?? 0).toDouble();
    final weight = (_profileData?['weight'] ?? 0).toDouble();

    final suggestion = _generateSuggestion();

    final double progress =
    (_todaysCalories / bmr).clamp(0.0, 1.5); // limit to 150%

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Your Fitness Dashboard"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Profile Summary Card ---
              _buildProfileCard(age, height, weight, bmr, bmi),

              const SizedBox(height: 24),

              // --- Daily Goal Progress Bar ---
              _buildGoalProgressCard(bmr, progress),

              const SizedBox(height: 24),

              // --- AI Workout Snapshot ---
              _buildWorkoutCard(),

              const SizedBox(height: 24),

              // --- Suggestion Card ---
              _buildSuggestionCard(suggestion),
            ],
          ),
        ),
      ),
    );
  }

  // 🧩 Profile summary card
  Widget _buildProfileCard(
      int age, double height, double weight, double bmr, double bmi) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Profile Overview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoTile("Age", "$age"),
              _infoTile("Height", "${height.toStringAsFixed(1)} cm"),
              _infoTile("Weight", "${weight.toStringAsFixed(1)} kg"),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoTile("BMI", bmi.toStringAsFixed(1),
                  color: _bmiColor(bmi), bold: true),
              _infoTile("BMR", "${bmr.toStringAsFixed(0)} kcal", bold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value,
      {Color color = Colors.black, bool bold = false}) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  // 🧩 Goal progress card
  Widget _buildGoalProgressCard(double bmr, double progress) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.teal, Colors.greenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            "Today's Goal Progress",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CircularPercentIndicator(
            radius: 85.0,
            lineWidth: 12.0,
            percent: progress,
            center: Text(
              "${(_todaysCalories).toStringAsFixed(0)} kcal",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            progressColor: Colors.white,
            backgroundColor: Colors.white24,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
          const SizedBox(height: 12),
          Text(
            "Fat burned: ${_fatBurned.toStringAsFixed(2)} kg 💧",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            progress >= 1.0
                ? "✅ Goal Reached!"
                : "Goal: ${bmr.toStringAsFixed(0)} kcal",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // 🧩 Workout summary card
  Widget _buildWorkoutCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.shade400, Colors.orange.shade200],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.shade200,
              blurRadius: 10,
              offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Latest AI Workout",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statTile("Reps", _latestReps.toInt().toString(),
                  Icons.fitness_center),
              _statTile(
                  "Calories",
                  "${_latestWorkoutCalories.toStringAsFixed(1)} kcal",
                  Icons.local_fire_department),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  // 🧩 Suggestion card
  Widget _buildSuggestionCard(String suggestion) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: Colors.teal, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              suggestion,
              style: const TextStyle(
                color: Colors.teal,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
