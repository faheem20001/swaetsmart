import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveAIWorkoutScreen extends StatefulWidget {
  const LiveAIWorkoutScreen({Key? key}) : super(key: key);

  @override
  State<LiveAIWorkoutScreen> createState() => _LiveAIWorkoutScreenState();
}

class _LiveAIWorkoutScreenState extends State<LiveAIWorkoutScreen> {
  CameraController? _controller;
  late PoseDetector _poseDetector;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  List<Pose> _poses = [];

  // Exercise state
  final List<String> _exercises = ['Squats', 'Push-ups', 'Bicep Curls'];
  int _selectedExerciseIndex = 0;
  String get _selectedExercise => _exercises[_selectedExerciseIndex];

  String _feedback = 'Get ready...';
  int _repCount = 0;
  bool _isDown = false;

  // Progress tracking
  late DateTime _startTime;
  double _caloriesBurned = 0;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_processCameraImage);

    setState(() => _isCameraInitialized = true);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final rotation = _controller!.description.sensorOrientation;
      final inputImage = _convertToInputImage(image, rotation);
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        _analyzePose(poses.first);
        setState(() {
          _poses = poses;
        });
      } else {
        setState(() => _feedback = "No body detected.");
      }
    } catch (e) {
      debugPrint("Pose detection error: $e");
    }

    _isDetecting = false;
  }

  InputImage _convertToInputImage(CameraImage image, int rotation) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final InputImageRotation imageRotation =
        InputImageRotationValue.fromRawValue(rotation) ??
            InputImageRotation.rotation0deg;

    const InputImageFormat inputImageFormat = InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow:
      image.planes.isNotEmpty ? image.planes.first.bytesPerRow : image.width,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  // 🔹 Exercise Analysis Logic
  void _analyzePose(Pose pose) {
    switch (_selectedExercise) {
      case 'Squats':
        _analyzeSquat(pose);
        break;
      case 'Push-ups':
        _analyzePushUp(pose);
        break;
      case 'Bicep Curls':
        _analyzeBicepCurl(pose);
        break;
    }
  }

  void _analyzeSquat(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    if (hip == null || knee == null || ankle == null) return;

    final angle = _calculateAngle(hip, knee, ankle);
    if (angle < 100 && !_isDown) {
      _isDown = true;
      _feedback = "Good depth!";
    } else if (angle > 160 && _isDown) {
      _isDown = false;
      _repCount++;
      _caloriesBurned += 0.4;
      _feedback = "Nice rep! ($_repCount)";
    } else if (angle >= 100 && angle <= 140) {
      _feedback = "Go lower!";
    }
  }

  void _analyzePushUp(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    if (shoulder == null || elbow == null || wrist == null) return;

    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle < 70 && !_isDown) {
      _isDown = true;
      _feedback = "Down — great!";
    } else if (angle > 160 && _isDown) {
      _isDown = false;
      _repCount++;
      _caloriesBurned += 0.35;
      _feedback = "Nice push-up! ($_repCount)";
    } else if (angle > 70 && angle < 150) {
      _feedback = "Keep moving!";
    }
  }

  void _analyzeBicepCurl(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    if (shoulder == null || elbow == null || wrist == null) return;

    final angle = _calculateAngle(shoulder, elbow, wrist);
    if (angle < 40 && !_isDown) {
      _isDown = true;
      _feedback = "Full curl!";
    } else if (angle > 150 && _isDown) {
      _isDown = false;
      _repCount++;
      _caloriesBurned += 0.2;
      _feedback = "Good rep! ($_repCount)";
    } else if (angle >= 40 && angle <= 130) {
      _feedback = "Curl fully!";
    }
  }

  double _calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    final rad = math.atan2(p3.y - p2.y, p3.x - p2.x) -
        math.atan2(p1.y - p2.y, p1.x - p2.x);
    double angle = rad * 180 / math.pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  // 🔹 Firestore upload
  Future<void> _finishWorkout() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final duration = DateTime.now().difference(_startTime).inSeconds;

    await _firestore.collection('users').doc(uid).collection('workout_progress').add({
      'exerciseType': _selectedExercise,
      'reps': _repCount,
      'caloriesBurned': _caloriesBurned,
      'duration': duration,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Workout saved ✅")),
      );
      Navigator.pop(context);
    }
  }

  // 🔹 Modern UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          // Gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // Workout selector
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_exercises.length, (index) {
                  final selected = _selectedExerciseIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedExerciseIndex = index;
                        _repCount = 0;
                        _caloriesBurned = 0;
                        _feedback = "Get ready for ${_exercises[index]}!";
                        _startTime = DateTime.now();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.deepOrangeAccent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _exercises[index],
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Feedback text
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _feedback,
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Center stats
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _selectedExercise,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_repCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 10)
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_caloriesBurned.toStringAsFixed(1)} kcal',
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Finish button
          Positioned(
            bottom: 40,
            left: 80,
            right: 80,
            child: ElevatedButton.icon(
              onPressed: _finishWorkout,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Finish Workout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
