import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AINutritionPlanScreen extends StatefulWidget {
  const AINutritionPlanScreen({super.key});

  @override
  State<AINutritionPlanScreen> createState() => _AINutritionPlanScreenState();
}

class _AINutritionPlanScreenState extends State<AINutritionPlanScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loading = true;
  double _bmi = 0;
  double _weight = 0;
  double _calorieTarget = 0;
  List<Map<String, dynamic>> _meals = [];

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Fetch user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};
      _bmi = (data['bmi'] ?? 22.0).toDouble();
      _weight = (data['weight'] ?? 70.0).toDouble();
      _calorieTarget =
          (data['calorieTarget'] ?? data['bmr'] ?? 2200).toDouble();

      // Determine BMI category
      String category;
      if (_bmi < 18.5) {
        category = 'underweight';
      } else if (_bmi < 25) {
        category = 'healthy';
      } else if (_bmi < 30) {
        category = 'overweight';
      } else {
        category = 'obese';
      }

      // Check if nutrition plan exists for this category
      final existing =
      await _firestore.collection('nutrition_plans').doc(category).collection('meals').get();

      // Auto-seed if missing
      if (existing.docs.isEmpty) {
        await _autoSeedNutritionPlans();
      }

      // Fetch the plan again (fresh)
      final planSnap = await _firestore
          .collection('nutrition_plans')
          .doc(category)
          .collection('meals')
          .get();

      _meals =
          planSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      setState(() => _loading = false);
    } catch (e) {
      debugPrint("Error loading nutrition plan: $e");
      setState(() => _loading = false);
    }
  }

  /// 🔹 Seeds default AI nutrition plans only if none exist
  Future<void> _autoSeedNutritionPlans() async {
    final firestore = FirebaseFirestore.instance;

    final plans = {
      "underweight": [
        {
          "mealName": "Oats with Peanut Butter & Milk",
          "description":
          "High-protein breakfast with complex carbs for healthy gain.",
          "calories": 550,
          "time": "8:00 AM"
        },
        {
          "mealName": "Rice, Chicken & Veg Curry",
          "description": "Balanced carbs and protein for steady gain.",
          "calories": 700,
          "time": "1:00 PM"
        },
        {
          "mealName": "Banana Shake & Nuts",
          "description": "Energy-dense evening snack for surplus calories.",
          "calories": 400,
          "time": "4:00 PM"
        },
        {
          "mealName": "Whole Wheat Chapati & Paneer Curry",
          "description": "High protein, low fat dinner.",
          "calories": 600,
          "time": "8:00 PM"
        },
      ],
      "healthy": [
        {
          "mealName": "Greek Yogurt Bowl",
          "description": "Balanced macros with protein and healthy carbs.",
          "calories": 400,
          "time": "8:00 AM"
        },
        {
          "mealName": "Grilled Chicken & Brown Rice",
          "description": "Perfect post-workout lunch.",
          "calories": 600,
          "time": "1:00 PM"
        },
        {
          "mealName": "Almond Snack & Apple",
          "description": "Light snack to stay energetic.",
          "calories": 250,
          "time": "4:00 PM"
        },
        {
          "mealName": "Fish Curry & Veggies",
          "description": "Protein-packed dinner with omega-3 fats.",
          "calories": 550,
          "time": "8:00 PM"
        },
      ],
      "overweight": [
        {
          "mealName": "Egg White Omelette & Smoothie",
          "description": "Low-fat, high-protein breakfast.",
          "calories": 300,
          "time": "8:00 AM"
        },
        {
          "mealName": "Grilled Chicken Salad",
          "description": "Lean protein with fresh vegetables.",
          "calories": 350,
          "time": "12:30 PM"
        },
        {
          "mealName": "Green Tea & Nuts",
          "description": "Healthy mid-day metabolism boost.",
          "calories": 200,
          "time": "4:00 PM"
        },
        {
          "mealName": "Lentil Soup & Veggies",
          "description": "Fiber-rich, light dinner.",
          "calories": 400,
          "time": "8:00 PM"
        },
      ],
      "obese": [
        {
          "mealName": "Oatmeal with Berries",
          "description": "Low-calorie, high-fiber breakfast.",
          "calories": 250,
          "time": "8:00 AM"
        },
        {
          "mealName": "Steamed Broccoli & Tofu",
          "description": "Nutrient-dense lunch, low in calories.",
          "calories": 300,
          "time": "1:00 PM"
        },
        {
          "mealName": "Green Tea & Chia Seeds",
          "description": "Boosts metabolism, curbs hunger.",
          "calories": 150,
          "time": "4:00 PM"
        },
        {
          "mealName": "Vegetable Soup & Quinoa",
          "description": "Light dinner for calorie control.",
          "calories": 350,
          "time": "8:00 PM"
        },
      ],
    };

    for (final category in plans.keys) {
      final meals = plans[category]!;
      for (final meal in meals) {
        await firestore
            .collection('nutrition_plans')
            .doc(category)
            .collection('meals')
            .add(meal);
      }
    }

    debugPrint("✅ Auto-seeded nutrition plans into Firestore!");
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("AI Nutrition Plan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              ..._meals.map((meal) => _buildMealCard(
                meal['mealName'] ?? 'Meal',
                meal['description'] ?? '',
                "${meal['calories'] ?? 'N/A'} kcal",
                meal['time'] ?? '',
              )),
              const SizedBox(height: 30),
              _buildScanFoodButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Builders ---
  Widget _buildHeaderCard() {
    final color = _bmiColor(_bmi);
    final label = _bmiCategoryText(_bmi);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text("Personalized Plan for ${_bmi.toStringAsFixed(0)} (${label.split('•').first})",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(
      String meal, String description, String calories, String time) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: const Icon(Icons.restaurant, color: Colors.teal),
        ),
        title: Text(meal,
            style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("$description${time.isNotEmpty ? " • $time" : ""}"),
        trailing: Text(calories,
            style: const TextStyle(
                color: Colors.teal, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildScanFoodButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => GoRouter.of(context).go('/food_scan'),
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text("Scan Food"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // Helpers
  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blueAccent;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _bmiCategoryText(double bmi) {
    if (bmi < 18.5) return "Underweight • Add healthy calories 🍳";
    if (bmi < 25) return "Healthy • Maintain balance 💪";
    if (bmi < 30) return "Overweight • Light calorie deficit 🏃‍♂️";
    return "Obese • Focus on calorie control 🥗";
  }
}
