import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../profile/services/user_service.dart';
import '../../profile/models/user_fitness_model.dart';
import '../../dashboard/models/daily_progress_model.dart';
import '../../dashboard/services/progress_service.dart';

class PoseEstimationService {
  final _poseDetector = PoseDetector(options: PoseDetectorOptions());
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  double _caloriesBurned = 0;
  int _repCount = 0;
  PoseLandmarkType? _lastPose;

  double get caloriesBurned => _caloriesBurned;
  int get repCount => _repCount;

  Future<void> processPose(CameraImage image) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) return;

      final pose = poses.first;
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

      if (leftKnee != null && leftHip != null && leftShoulder != null) {
        final angle = _calculateAngle(leftShoulder, leftHip, leftKnee);
        if (angle < 70 && _lastPose != PoseLandmarkType.leftKnee) {
          _repCount++;
          _lastPose = PoseLandmarkType.leftKnee;
          _caloriesBurned += 0.4; // calories per rep
        } else if (angle > 160) {
          _lastPose = null;
        }
      }
    } catch (e) {
      print("Pose detection error: $e");
    }
  }

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = [a.x - b.x, a.y - b.y];
    final cb = [c.x - b.x, c.y - b.y];
    final dot = ab[0] * cb[0] + ab[1] * cb[1];
    final magAB = sqrt(ab[0] * ab[0] + ab[1] * ab[1]);
    final magCB = sqrt(cb[0] * cb[0] + cb[1] * cb[1]);
    final cosTheta = dot / (magAB * magCB);
    return acos(cosTheta) * 180 / pi;
  }

  Future<void> saveWorkoutData({ String exerciseType = 'unknown', int durationSec = 0 }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('workout_progress')
        .doc(); // auto id

    await docRef.set({
      'caloriesBurned': _caloriesBurned,   // double
      'duration': durationSec,             // int seconds
      'exerciseType': exerciseType,        // string
      'reps': _repCount,                   // int
      'timestamp': now.toUtc(),            // Firestore Timestamp will store this
    });
  }

  Future<void> dispose() async {
    await _poseDetector.close();
  }

}
