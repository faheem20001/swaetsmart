import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AINutritionPlanScreen extends StatelessWidget {
  const AINutritionPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Smart Nutrition Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Daily Calorie Target: 2200 kcal', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            _buildMealCard('Breakfast', 'Smart Oats', '450 kcal'),
            _buildMealCard('Lunch', 'Lean Salad', '600 kcal'),
            _buildMealCard('Dinner', 'Grilled Chicken & Veggies', '750 kcal'),
            _buildMealCard('Snacks', 'Protein Shake', '400 kcal'),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Food'),
              onPressed: () => GoRouter.of(context).go('/food_scan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(String meal, String description, String calories) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.food_bank, color: Colors.tealAccent, size: 40),
        title: Text(meal, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Text(calories, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }
}