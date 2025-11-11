// src/features/nutrition/ui/screens/food_scan_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

// Import your new services
import 'package:swaetsmart/src/features/nutrition/services/nutrition_service.dart';

import '../../../../../storage_service.dart';


class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({super.key});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late ImageLabeler _imageLabeler;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();

    // Initialize the ImageLabeler
    final ImageLabelerOptions options =
    ImageLabelerOptions(confidenceThreshold: 0.5);
    _imageLabeler = ImageLabeler(options: options);
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );
    return _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _imageLabeler.close();
    super.dispose();
  }

  void _onScanButtonPressed() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analyzing image...')),
      );

      final inputImage = InputImage.fromFilePath(image.path);
      final List<ImageLabel> labels =
      await _imageLabeler.processImage(inputImage);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (labels.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not identify any food.")),
        );
        return;
      }

      final topLabel = labels.first.label;
      final calories = NutritionService.getApproxCalories(topLabel);

      if (calories == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Identified: $topLabel (No calorie data found)")),
        );
      } else {
        // We found a match! Show a SnackBar with an "Add" button
        final entryText = "$topLabel (~$calories kcal)";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Found: $entryText"),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: "Add to Log",
              onPressed: () {
                StorageService.addFoodEntry(topLabel, calories);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Logged: $topLabel")),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      print("Error scanning image: $e");
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Food Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade700, width: 2),
                ),
                child: FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CameraPreview(_controller),
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onScanButtonPressed,
              child: const Text('Scan'),
            ),
          ],
        ),
      ),
    );
  }
}