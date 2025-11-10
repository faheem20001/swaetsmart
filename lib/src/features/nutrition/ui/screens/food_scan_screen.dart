import 'package:flutter/material.dart';

class FoodScanScreen extends StatelessWidget {
  const FoodScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Food Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera Placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade700, width: 2),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 80, color: Colors.white54),
                      Text('Camera View', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Show dummy result
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Identified: Apple (95 kcal) - Logging meal...')),
                );
              },
              child: const Text('Scan'),
            ),
          ],
        ),
      ),
    );
  }
}