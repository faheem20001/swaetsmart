import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  int _selectedIndex = 0; // State for BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme.of(context) to get colors from your FlexColorScheme theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.lightGreen[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        // Use theme colors for a consistent look
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            // FIX: Use push with the full path for nested routes
            onPressed: () => GoRouter.of(context).push('/dashboard/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back, Hashiii!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            // Modern, animated AI summary card
            _buildAiSummaryCard(context, colorScheme),

            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context,
                    icon: Icons.personal_video,
                    label: 'AI Workout Plan',
                    // FIX: Use push with the full path
                    onTap: () =>
                        GoRouter.of(context).push('/dashboard/ai_workout_plan'),
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.restaurant_menu,
                    label: 'AI Nutrition Plan',
                    // FIX: Use push with the full path
                    onTap: () => GoRouter.of(context)
                        .push('/dashboard/ai_nutrition_plan'),
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.camera,
                    label: 'Live AI Workout',
                    // FIX: Use push with the full path
                    onTap: () =>
                        GoRouter.of(context).push('/dashboard/live_ai_workout'),
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: 'Scan Food',
                    // FIX: Use push with the full path
                    onTap: () => GoRouter.of(context).push('/dashboard/food_scan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Add a modern Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        elevation:
            16, // Increase the shadow height for a more pronounced effect
        // Use theme colors for consistency
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.7),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // TODO: Implement navigation or state change based on tap
        },
        // Use fixed type for more than 3 items to keep labels visible
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.accessibility_new_rounded),
            label: 'AI Pose',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.fastfood_rounded), label: 'Food Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildAiSummaryCard(BuildContext context, ColorScheme colorScheme) {
    final int progressPercentage = (_animation.value * 100).toInt();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // Use a gradient for a more modern feel
      color: colorScheme.primaryContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Progress",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _animation.value,
                        strokeWidth: 8,
                        backgroundColor: colorScheme.onPrimaryContainer.withOpacity(0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                      Center(
                        child: Text('$progressPercentage%',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Great job!",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You're 70% of the way to your daily goal. Just a 15-minute walk to hit 100%!",
                        // Use theme color for subtext
                        style: TextStyle(
                            fontSize: 14, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    // Get colors from the theme for consistency
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        // Add an outline that matches the theme
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
        // Add a subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18), // Slightly smaller for visual inset
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
