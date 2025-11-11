// src/features/nutrition/services/nutrition_service.dart

class NutritionService {
  // Our simple, offline, hard-coded database (calories per 100g)
  static const Map<String, int> _calorieDatabase = {
    'apple': 52,
    'banana': 89,
    'orange': 47,
    'grape': 69,
    'kiwi': 61,
    'strawberry': 32,
    'blueberry': 57,
    'lettuce': 15,
    'tomato': 18,
    'cucumber': 15,
    'carrot': 41,
    'broccoli': 55,
    'bread': 265,
    'cookie': 502,
    'pizza': 266,
    'salad': 15,
    'food': 100 // A generic fallback
  };

  // Gets calories for a given food label
  static int? getApproxCalories(String foodLabel) {
    final key = foodLabel.toLowerCase();

    // Check for a direct match
    if (_calorieDatabase.containsKey(key)) {
      return _calorieDatabase[key];
    }

    // Try a simple plural check
    if (key.endsWith('s')) {
      final singularKey = key.substring(0, key.length - 1);
      if (_calorieDatabase.containsKey(singularKey)) {
        return _calorieDatabase[singularKey];
      }
    }

    // No match found
    return null;
  }
}