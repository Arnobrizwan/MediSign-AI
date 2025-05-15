import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'sign_language_model.dart';

class HandTrackingProcessor {
  // ML Kit pose detector - we'll use pose detection instead of hand detection
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    ),
  );

  // Sign language model
  final SignLanguageModel _signLanguageModel = SignLanguageModel();

  // Stream controller for sign detection results
  final StreamController<Map<String, dynamic>> _resultStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Stream for sign detection results
  Stream<Map<String, dynamic>> get onSignDetected => _resultStreamController.stream;

  // Detection cooldown
  DateTime _lastDetectionTime = DateTime.now();
  static const Duration _detectionCooldown = Duration(milliseconds: 1000);

  // Initialize
  Future<void> initialize() async {
    await _signLanguageModel.loadModel();
  }

  // Process camera image
  Future<Map<String, dynamic>?> processImage(XFile file) async {
    try {
      // Implement detection cooldown to avoid too many detections
      final now = DateTime.now();
      if (now.difference(_lastDetectionTime) < _detectionCooldown) {
        return null;
      }

      // Read image
      final bytes = await file.readAsBytes();
      final inputImage = InputImage.fromFilePath(file.path);

      // Detect poses using ML Kit
      final poses = await _poseDetector.processImage(inputImage);

      // Check if we detected a pose and have hand landmarks
      // Specifically looking for wrist, thumb, and index finger landmarks
      final hasPose = poses.isNotEmpty;
      final hasHandLandmarks = hasPose && _hasRelevantHandLandmarks(poses.first);
      
      if (!hasHandLandmarks) {
        return null;
      }

      // Process with sign language model
      final result = await _signLanguageModel.processImage(bytes);

      // Update last detection time
      _lastDetectionTime = now;

      // Broadcast result
      _resultStreamController.add(result);
      return result;
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }
  
  // Check if the pose has relevant hand landmarks for sign language
  bool _hasRelevantHandLandmarks(Pose pose) {
    // Look for wrists, elbows, and shoulders which are needed for hand tracking
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    
    // Check if at least one hand (wrist + elbow) is detected with good confidence
    bool leftHandDetected = leftWrist != null && leftElbow != null && 
                           leftWrist.likelihood > 0.5 && leftElbow.likelihood > 0.5;
    bool rightHandDetected = rightWrist != null && rightElbow != null && 
                            rightWrist.likelihood > 0.5 && rightElbow.likelihood > 0.5;
    
    return leftHandDetected || rightHandDetected;
  }

  // Clean up resources
  void dispose() {
    _poseDetector.close();
    _signLanguageModel.dispose();
    _resultStreamController.close();
  }
}