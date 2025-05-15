import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_hands/google_mlkit_hands.dart';
import 'sign_language_model.dart';

class HandTrackingProcessor {
  // ML Kit hand detector
  final HandsDetector _handsDetector = HandsDetector(
    options: HandsDetectorOptions(
      mode: HandDetectorMode.stream,
      maxHands: 2,
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
      
      // Detect hands using ML Kit
      final hands = await _handsDetector.processImage(inputImage);
      
      // If no hands detected, return null
      if (hands.isEmpty) {
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
  
  // Clean up resources
  void dispose() {
    _handsDetector.close();
    _signLanguageModel.dispose();
    _resultStreamController.close();
  }
}