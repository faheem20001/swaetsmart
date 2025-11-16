import 'dart:ui';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class HeightMeasurementService {
  final PoseDetector _poseDetector =
  PoseDetector(options: PoseDetectorOptions());

  bool _isProcessing = false;

  double? heightCm;
  String status = "Point the camera to capture full body";

  Future<void> processImage(CameraImage image) async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      final inputImg = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetector.processImage(inputImg);

      if (poses.isEmpty) {
        status = "No body detected";
        _isProcessing = false;
        return;
      }

      final pose = poses.first;

      final nose = pose.landmarks[PoseLandmarkType.nose];
      final la = pose.landmarks[PoseLandmarkType.leftAnkle];
      final ra = pose.landmarks[PoseLandmarkType.rightAnkle];

      if (nose == null || la == null || ra == null) {
        status = "Move back to capture full height";
        _isProcessing = false;
        return;
      }

      final feetY = (la.y + ra.y) / 2;
      final headY = nose.y;

      final pixelHeight = (feetY - headY).abs();

      const pxPerCm = 9.5; // Tuned default
      heightCm = pixelHeight / pxPerCm;

      status = "Height: ${heightCm!.toStringAsFixed(1)} cm";

    } catch (e) {
      status = "Error";
      print("Height Error: $e");
    }

    _isProcessing = false;
  }

  Future<void> dispose() async {
    await _poseDetector.close();
  }
}
