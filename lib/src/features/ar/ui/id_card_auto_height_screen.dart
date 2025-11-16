import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class AutoHeightMeasureScreen extends StatefulWidget {
  const AutoHeightMeasureScreen({super.key});

  @override
  State<AutoHeightMeasureScreen> createState() => _AutoHeightMeasureScreenState();
}

class _AutoHeightMeasureScreenState extends State<AutoHeightMeasureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isFront = false;

  final PoseDetector _poseDetector =
  PoseDetector(options: PoseDetectorOptions(
    mode: PoseDetectionMode.single,
  ));

  bool _isBusy = false;
  double? _measuredHeight;
  String _status = "Align your full body inside the frame";

  Timer? _countdownTimer;
  int _countdown = 5;
  bool _timerStarted = false;

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  Future<void> _initCameras() async {
    _cameras = await availableCameras();
    _startCamera();
  }

  Future<void> _startCamera() async {
    final cam = _isFront
        ? _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front)
        : _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  void _switchCamera() {
    _isFront = !_isFront;
    _controller?.dispose();
    _startCamera();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: metadata,
      );

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) {
        _status = "Move back – full body not detected";
        _isBusy = false;
        return;
      }

      final pose = poses.first;

      final head = pose.landmarks[PoseLandmarkType.nose];
      final foot = pose.landmarks[PoseLandmarkType.leftAnkle] ??
          pose.landmarks[PoseLandmarkType.rightAnkle];

      if (head == null || foot == null) {
        _status = "Full body not detected";
        _isBusy = false;
        return;
      }

      final heightPixels = (foot.y - head.y).abs();
      if (heightPixels < 80) {
        _status = "Move back – body too close";
        _isBusy = false;
        return;
      }

      // Camera pixel to cm estimation (simple model)
      final distanceFactor = 0.25; // tweak if needed
      final heightCm = heightPixels * distanceFactor;

      _measuredHeight = heightCm;
      _status = "Height detected: ${heightCm.toStringAsFixed(1)} cm";

      if (!_timerStarted) {
        _startTimer();
      }
    } catch (e) {
      print("Pose error: $e");
    }

    _isBusy = false;
  }

  void _startTimer() {
    _timerStarted = true;
    _countdown = 5;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
        _saveHeight();
        return;
      }
      setState(() => _countdown--);
    });
  }

  void _saveHeight() {
    if (_measuredHeight == null) return;

    Navigator.pop(context, {
      "autoHeightCm": _measuredHeight!.round(),
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector.close();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Auto Height Measure"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
          ),
        ],
      ),

      body: Stack(
        children: [
          CameraPreview(_controller!),

          /// Body outline overlay
          Center(
            child: Container(
              width: 280,
              height: 520,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          /// Countdown
          if (_timerStarted)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Text(
                "Capturing in $_countdown",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          /// Status text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
