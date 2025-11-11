// src/features/nutrition/services/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _logKey = 'foodLog';

  static Future<void> addFoodEntry(String foodName, int calories) async {
    final prefs = await SharedPreferences.getInstance();

    // We'll store the entry as a simple formatted string with a separator
    final entry = "$foodName: ~$calories kcal|${DateTime.now().toIso8601String()}";

    // Get the current log, add the new entry
    List<String> currentLog = prefs.getStringList(_logKey) ?? [];
    currentLog.insert(0, entry); // Add to the top of the list

    // Save the updated log
    await prefs.setStringList(_logKey, currentLog);
  }

  static Future<List<String>> getFoodLog() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_logKey) ?? [];
  }

  // --- NEW: Method to delete an entry by index ---
  static Future<void> deleteFoodEntry(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentLog = prefs.getStringList(_logKey) ?? [];
    if (index >= 0 && index < currentLog.length) {
      currentLog.removeAt(index);
      await prefs.setStringList(_logKey, currentLog);
    }
  }

  // Optional: Clear all entries
  static Future<void> clearFoodLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logKey);
  }
}