import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../ai_plans/ui/screens/ai_nutrition_plan_screen.dart';
import '../../../nutrition/ui/screens/food_log_screen.dart';
import '../../../nutrition/ui/screens/food_scan_screen.dart';
import '../../../profile/ui/screens/profile_screen.dart';
import '../../../workouts/ui/screens/live_ai_workout_screen.dart';
import '../../../workouts/ui/screens/workout_section_detail_screen.dart';
import 'dashboard_chart_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String plan = "Standard";
  String username = "User";
  String nutritionTip = "";

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPlan();
    _loadUsername();
    _loadNutritionSuggestion();
  }

  Future<void> _loadPlan() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (!mounted) return;
    setState(() {
      plan = snap.data()?["planType"] ?? "Standard";
    });
  }

  Future<void> _loadUsername() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (!mounted) return;
    setState(() {
      username = snap.data()?["name"] ?? "User";
    });
  }

  Future<void> _loadNutritionSuggestion() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final data = snap.data() ?? {};

    final double bmi = (data["bmi"] ?? 22.0).toDouble();

    if (bmi < 18.5) {
      nutritionTip = "You're underweight — add more protein and whole grains 🍗";
    } else if (bmi < 25) {
      nutritionTip = "Healthy BMI — maintain balanced meals 💪";
    } else if (bmi < 30) {
      nutritionTip = "Slightly overweight — reduce sugar intake 🥗";
    } else {
      nutritionTip = "High BMI — focus on low-calorie meals & more steps 🚶‍♂️";
    }

    if (mounted) {
      setState(() {});
    }
  }

  bool _isLocked(String feature) {
    if (plan == "Ultimate") return false;

    if (plan == "Pro") {
      if (feature == "live") return true; // live locked for Pro
      return false;
    }

    if (plan == "Standard") {
      return ["nutrition", "charts", "live"].contains(feature);
    }

    return true;
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Upgrade Required"),
        content: const Text(
            "This feature is available only for Pro & Ultimate users.\nUpgrade your plan to unlock everything."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Not now")),
          ElevatedButton(
            child: const Text("Upgrade"),
            onPressed: () async {
              Navigator.pop(context);

              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );

              _loadPlan(); // refresh
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // TIME BASED GREETING
  // ---------------------------
  String _greet() {
    final hour = DateTime.now().hour;

    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  // ---------------------------
  // BUILD
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final greeting = "${_greet()}, $username 👋";

    final tiles = [
      _tile(
        title: "AI Workout Plan",
        icon: Icons.fitness_center_rounded,
        gradient: [Colors.green, Colors.lightGreen],
        feature: "workout",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutSectionDetailScreen()),
        ),
      ),
      _tile(
        title: "AI Nutrition Plan",
        icon: Icons.restaurant_menu_rounded,
        gradient: [Colors.orange, Colors.deepOrange],
        feature: "nutrition",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AINutritionPlanScreen()),
        ),
      ),
      _tile(
        title: "Live AI Workout",
        icon: Icons.camera_alt_rounded,
        gradient: [Colors.blue, Colors.blueAccent],
        feature: "live",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LiveAIWorkoutScreen()),
        ),
      ),
      _tile(
        title: "Scan Food",
        icon: Icons.qr_code_scanner_rounded,
        gradient: [Colors.purple, Colors.deepPurple],
        feature: "scan",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FoodScanScreen()),
        ),
      ),
      _tile(
        title: "Progress Charts",
        icon: Icons.bar_chart_rounded,
        gradient: [Colors.teal, Colors.cyan],
        feature: "charts",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardChartScreen()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        elevation: 0,
        title: const Text("Dashboard"),
        backgroundColor: Colors.grey[100],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // GREETING
          Text(
            greeting,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // NUTRITION SUGGESTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrangeAccent]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              nutritionTip,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 25),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.92,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: tiles,
          ),
        ],
      ),

      // ----------------------------
      // MODERN MATERIAL 3 NAV BAR
      // ----------------------------
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) async {
          setState(() => currentIndex = i);

          if (i == 1) {
            if (_isLocked("live")) {
              _showUpgradeDialog();
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LiveAIWorkoutScreen()));
            }
          }

          if (i == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FoodLogScreen()));
          }

          if (i == 3) {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
            _loadPlan();
          }
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.green.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: "Home"),
          NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: "AI Pose"),
          NavigationDestination(
              icon: Icon(Icons.fastfood_outlined),
              selectedIcon: Icon(Icons.fastfood),
              label: "Food"),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: "Profile"),
        ],
      ),
    );
  }

  // ---------------------------
  // TILE WIDGET
  // ---------------------------
  Widget _tile({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    required String feature,
  }) {
    final locked = _isLocked(feature);

    return GestureDetector(
      onTap: locked ? _showUpgradeDialog : onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          if (locked)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: Icon(Icons.lock, size: 40, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
