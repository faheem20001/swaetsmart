import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LiveAIWorkoutScreen extends StatelessWidget {
  const LiveAIWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live AI Coaching')),
      body: Stack(
        children: [
          // Camera View Placeholder
          Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.videocam, size: 100, color: Colors.white24),
            ),
          ),
          // AI Feedback Overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'AI Feedback: "Adjust your form: Hips too low!"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.yellowAccent, fontSize: 16),
              ),
            ),
          ),
          // Timer and controls at the bottom
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text('01:34', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => GoRouter.of(context).go('/workout_feedback'),
                  child: const Text('End Workout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}