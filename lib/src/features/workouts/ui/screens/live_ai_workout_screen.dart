import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

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
  String _selectedExercise = 'Squats'; // Squats, Push-ups, Bicep Curls
  String _feedback = 'Get ready...';
  int _repCount = 0;
  bool _isDown = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
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
        setState(() {
          _feedback = "No body detected.";
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("AI Workout Tracker"),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedExercise,
            onSelected: (val) {
              setState(() {
                _selectedExercise = val;
                _repCount = 0;
                _feedback = "Get ready for $val!";
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Squats', child: Text("Squats")),
              const PopupMenuItem(value: 'Push-ups', child: Text("Push-ups")),
              const PopupMenuItem(value: 'Bicep Curls', child: Text("Bicep Curls")),
            ],
          ),
        ],
      ),
      body: _isCameraInitialized
          ? Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          if (_poses.isNotEmpty)
            CustomPaint(
              painter: PosePainter(
                poses: _poses,
                imageSize: Size(
                  _controller!.value.previewSize!.height,
                  _controller!.value.previewSize!.width,
                ),
              ),
            ),

          Positioned(
            top: 30,
            left: 20,
            right: 20,
            child: Center(
              child: Text(
                _feedback,
                style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _selectedExercise,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_repCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;

  PosePainter({required this.poses, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint jointPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 5.0
      ..style = PaintingStyle.fill;

    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    for (final pose in poses) {
      for (final landmark in pose.landmarks.values) {
        final dx = landmark.x * scaleX;
        final dy = landmark.y * scaleY;
        canvas.drawCircle(Offset(dx, dy), 4, jointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
