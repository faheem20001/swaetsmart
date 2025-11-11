import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'src/features/workouts/ui/screens/workout_section_detail_screen.dart';

// Import all your screen files
import 'src/features/onboarding/ui/screens/splash_screen.dart';
import 'src/features/dashboard/ui/screens/dashboard_screen.dart';
import 'src/features/ai_plans/ui/screens/ai_workout_plan_screen.dart';
import 'src/features/ai_plans/ui/screens/ai_nutrition_plan_screen.dart';
import 'src/features/nutrition/ui/screens/food_scan_screen.dart';
import 'src/features/workouts/ui/screens/live_ai_workout_screen.dart';
import 'src/features/workouts/ui/screens/workout_feedback_screen.dart';
import 'src/features/profile/ui/screens/settings_screen.dart';

// Import the new log screen
import 'src/features/nutrition/ui/screens/food_log_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SweatSmartApp());
}

final GoRouter _router = GoRouter(
  navigatorKey: GlobalKey<NavigatorState>(),
  initialLocation: '/', // Start at the splash screen
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    // The Dashboard is a top-level route
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
      // Define other screens as "children" of the dashboard
      routes: [
        GoRoute(
          path: 'ai_workout_plan', // Becomes '/dashboard/ai_workout_plan'
          builder: (context, state) => const AIWorkoutPlanScreen(),
        ),
        GoRoute(
          path: 'ai_nutrition_plan', // Becomes '/dashboard/ai_nutrition_plan'
          builder: (context, state) => const AINutritionPlanScreen(),
        ),
        GoRoute(
          path: 'food_scan', // Becomes '/dashboard/food_scan'
          // --- FIX: Added 'const' ---
          builder: (context, state) => const FoodScanScreen(),
        ),
        GoRoute(
          path: 'food_log', // Becomes '/dashboard/food_log'
          // --- NEW: Added 'const' and the route ---
          builder: (context, state) => const FoodLogScreen(),
        ),
        GoRoute(
            path: 'live_ai_workout', // Becomes '/dashboard/live_ai_workout'
            builder: (context, state) => const LiveAIWorkoutScreen(),
            // Further nesting is also possible
            routes: [
              GoRoute(
                path: 'feedback', // Becomes '/dashboard/live_ai_workout/feedback'
                builder: (context, state) => const WorkoutFeedbackScreen(),
              ),
            ]
        ),
        GoRoute(
          path: 'settings', // Becomes '/dashboard/settings'
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'workout_details/:sectionId', // Uses a path parameter
          builder: (context, state) {
            // Extract the parameter
            final sectionId = state.pathParameters['sectionId']!;
            return WorkoutSectionDetailScreen(sectionId: sectionId);
          },
        ),
      ],
    ),
  ],
);

class SweatSmartApp extends StatelessWidget {
  const SweatSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SweatSmart',
      // 3. Apply a modern theme with FlexColorScheme
      theme: FlexThemeData.light(
        scheme: FlexScheme.tealM3, // A nice teal-based Material 3 theme
        useMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.tealM3,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Automatically adapt to system light/dark mode
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}