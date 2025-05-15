// lib/integration/mediapipe_sign_integration.dart

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mediapipe_bridge.dart';

/// Helper for integrating MediaPipe sign detection with your existing pages
class MediaPipeSignIntegration {
  /// Set up MediaPipe sign detection in your sign translate page
  static Future<void> setupInSignTranslatePage({
    required BuildContext context,
    required Function(String) onSignDetected,
    bool startDetection = false,
  }) async {
    // Get provider from context
    final provider = Provider.of<MediaPipeSignProvider>(context, listen: false);
    
    // Initialize
    await provider.initialize(onSignDetected: onSignDetected);
    
    // Start detection if requested
    if (startDetection) {
      provider.toggleDetection(true);
    }
  }
  
  /// Process a camera frame for sign language detection
  static Future<String?> processFrame({
    required BuildContext context,
    required XFile imageFile,
  }) async {
    final provider = Provider.of<MediaPipeSignProvider>(context, listen: false);
    return provider.processFrame(imageFile);
  }
  
  /// Toggle sign detection
  static void toggleDetection({
    required BuildContext context,
    required bool detect,
  }) {
    final provider = Provider.of<MediaPipeSignProvider>(context, listen: false);
    provider.toggleDetection(detect);
  }
}

/// Extension for the SignTranslatePage class
extension SignTranslatePageMediaPipeExtension {
  /// Set up periodic frame processing for MediaPipe sign detection
  static Timer startPeriodicFrameProcessing({
    required BuildContext context,
    required CameraController cameraController,
    Duration interval = const Duration(milliseconds: 1500),
  }) {
    return Timer.periodic(interval, (_) async {
      if (!cameraController.value.isInitialized) return;
      
      try {
        // Capture image
        final XFile file = await cameraController.takePicture();
        
        // Process with MediaPipe
        await MediaPipeSignIntegration.processFrame(
          context: context,
          imageFile: file,
        );
      } catch (e) {
        print('Error processing frame: $e');
      }
    });
  }
}

