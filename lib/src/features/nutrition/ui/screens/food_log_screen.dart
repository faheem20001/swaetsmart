// src/features/nutrition/ui/screens/food_log_screen.dart

import 'package:flutter/material.dart';
// Import the new package for slidable list items
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../../storage_service.dart';
// Corrected path

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  late Future<List<String>> _foodLogFuture;
  List<String> _currentLog = []; // To hold the actual data

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  // Function to load the log and update the state
  void _loadLog() {
    _foodLogFuture = StorageService.getFoodLog();
    _foodLogFuture.then((log) {
      setState(() {
        _currentLog = log; // Store the loaded log in state
      });
    });
  }

  // Function to delete an item
  void _deleteEntry(int index) async {
    await StorageService.deleteFoodEntry(index);
    setState(() {
      _currentLog.removeAt(index); // Remove from the local list
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Food entry deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Food Log'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Log',
            onPressed: _loadLog, // Use the updated _loadLog
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All Log',
            onPressed: () async {
              // Confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Clear All Entries?'),
                    content: const Text('This action cannot be undone.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                      TextButton(
                        child: const Text('Clear'),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                await StorageService.clearFoodLog();
                _loadLog(); // Reload the log
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Food log cleared.')),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _foodLogFuture, // Still use future for initial load
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _currentLog.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading log: ${snapshot.error}'));
          }

          if (_currentLog.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fastfood_outlined, size: 80, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No food logged yet. Go scan something!',
                    style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                  ),
                ],
              ),
            );
          }

          // Display the log in a modern list with Slidable
          return SlidableAutoCloseBehavior( // Allows only one slidable to be open at a time
            child: ListView.builder(
              itemCount: _currentLog.length,
              itemBuilder: (context, index) {
                final entryString = _currentLog[index];
                final parts = entryString.split('|');
                final foodCaloriesText = parts[0]; // e.g., "Apple: ~52 kcal"
                final dateText = parts.length > 1 ? parts[1] : '';

                // Extract food name and calories from foodCaloriesText
                String foodName = "Unknown Food";
                int? calories;
                final regex = RegExp(r'^(.*?):\s*~?(\d+)\s*kcal$');
                final match = regex.firstMatch(foodCaloriesText);
                if (match != null) {
                  foodName = match.group(1)!.trim();
                  calories = int.tryParse(match.group(2)!);
                } else {
                  foodName = foodCaloriesText.split(':')[0].trim();
                }


                DateTime? loggedDate;
                if (dateText.isNotEmpty) {
                  try {
                    loggedDate = DateTime.parse(dateText.trim()).toLocal();
                  } catch (e) {
                    print('Error parsing date: $dateText, $e');
                    // Fallback or handle error if date parsing fails
                  }
                }

                return Slidable(
                  key: ValueKey(entryString), // Unique key for each slidable item
                  endActionPane: ActionPane(
                    motion: const StretchMotion(), // Smooth slide animation
                    extentRatio: 0.25, // How much of the item the action pane takes
                    children: [
                      SlidableAction(
                        onPressed: (context) => _deleteEntry(index),
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: AnimatedContainer( // Add a subtle animation for when items appear
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.fastfood, color: colorScheme.primary, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  foodName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (calories != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '$calories kcal',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (loggedDate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Logged: ${loggedDate.day}/${loggedDate.month}/${loggedDate.year} ${loggedDate.hour}:${loggedDate.minute.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                  ),
                                ] else if (dateText.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Logged: Invalid Date',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.error.withOpacity(0.7),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          // Optional: Add a small visual indicator for calories if desired
                          if (calories != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$calories',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}