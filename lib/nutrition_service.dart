// lib/nutrition_service.dart

class NutritionService {
  // Our simple, offline, hard-coded database
  // In a real app, this might be a local SQLite database or a larger JSON file.
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
    'salad': 15, // Note: "Salad" is generic, this is a big approximation
    'food': 100 // A generic fallback
  };

  // Gets calories for a given food label
  static int? getApproxCalories(String foodLabel) {
    // Check for a direct match (e.g., "Apple" -> "apple")
    final key = foodLabel.toLowerCase();
    if (_calorieDatabase.containsKey(key)) {
      return _calorieDatabase[key];
    }

    // Try a simple plural check (e.g., "Apples" -> "apple")
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