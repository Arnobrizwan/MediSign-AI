import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/mediapipe_sign_service.dart';

/// Bridge between MediaPipe sign language detection and health check-in
class MediaPipeSignBridge {
  // MediaPipe sign service
  final MediaPipeSignService _signService = MediaPipeSignService();
  
  // State
  bool _isInitialized = false;
  bool _isDetecting = false;
  
  // Get direct reference to stream
  Stream<String> get onSignDetected => _signService.onSignDetected;
  
  // Initialize
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _signService.initialize();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing MediaPipe bridge: $e');
      rethrow;
    }
  }
  
  // Process a frame from the camera
  Future<String?> processFrame(XFile imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isDetecting) {
      return await _signService.processFrame(imageFile);
    }
    
    return null;
  }
  
  // Toggle detection state
  void toggleDetection(bool detect) {
    _isDetecting = detect;
  }
  
  // Get detection state
  bool get isDetecting => _isDetecting;
  
  // Clean up
  void dispose() {
    _signService.dispose();
  }
}

/// Provider that makes it easy to use the bridge in widgets
class MediaPipeSignProvider extends ChangeNotifier {
  // Bridge
  final MediaPipeSignBridge _bridge = MediaPipeSignBridge();
  
  // State
  String _lastDetectedSign = '';
  
  // Getters
  String get lastDetectedSign => _lastDetectedSign;
  bool get isDetecting => _bridge.isDetecting;
  Stream<String> get onSignDetected => _bridge.onSignDetected;
  
  // Initialize
  Future<void> initialize({Function(String)? onSignDetected}) async {
    await _bridge.initialize();
    
    if (onSignDetected != null) {
      _bridge.onSignDetected.listen((sign) {
        _lastDetectedSign = sign;
        onSignDetected(sign);
        notifyListeners();
      });
    }
  }
  
  // Process frame
  Future<String?> processFrame(XFile imageFile) async {
    final result = await _bridge.processFrame(imageFile);
    if (result != null) {
      _lastDetectedSign = result;
      notifyListeners();
    }
    return result;
  }
  
  // Toggle detection
  void toggleDetection(bool detect) {
    _bridge.toggleDetection(detect);
    notifyListeners();
  }
  
  // Clean up
  @override
  void dispose() {
    _bridge.dispose();
    super.dispose();
  }
}