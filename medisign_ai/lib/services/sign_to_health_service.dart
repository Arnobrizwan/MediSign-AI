import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../ml/hand_tracking_processor.dart';

class SignToHealthService {
  // Hand tracking processor
  final HandTrackingProcessor _handTrackingProcessor = HandTrackingProcessor();
  
  // Stream controller for translated sign messages
  final StreamController<String> _signMessageController = 
      StreamController<String>.broadcast();
  
  // State
  bool _isInitialized = false;
  bool _isDetecting = false;
  
  // Public stream for sign messages
  Stream<String> get onSignMessage => _signMessageController.stream;
  
  // Detection state
  bool get isDetecting => _isDetecting;
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize hand tracking
      await _handTrackingProcessor.initialize();
      
      // Listen for sign detections
      _handTrackingProcessor.onSignDetected.listen((result) {
        final text = result['text'] as String;
        _signMessageController.add(text);
      });
      
      _isInitialized = true;
      print('Sign to health service initialized successfully');
    } catch (e) {
      print('Failed to initialize sign to health service: $e');
      rethrow;
    }
  }
  
  // Process a camera frame
  Future<String?> processFrame(XFile imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_isDetecting) {
      return null;
    }
    
    try {
      final result = await _handTrackingProcessor.processImage(imageFile);
      return result?['text'] as String?;
    } catch (e) {
      print('Error processing frame in SignToHealthService: $e');
      return null;
    }
  }
  
  // Toggle detection
  void toggleDetection(bool detect) {
    _isDetecting = detect;
  }
  
  // Clean up resources
  void dispose() {
    _handTrackingProcessor.dispose();
    _signMessageController.close();
  }
}

// Provider for easier state management
class SignToHealthProvider extends ChangeNotifier {
  // Service
  final SignToHealthService _service = SignToHealthService();
  
  // Last detected sign
  String _lastSignMessage = '';
  
  // Getters
  String get lastSignMessage => _lastSignMessage;
  bool get isDetecting => _service.isDetecting;
  Stream<String> get onSignMessage => _service.onSignMessage;
  
  // Initialize
  Future<void> initialize({void Function(String)? onSignDetected}) async {
    await _service.initialize();
    
    if (onSignDetected != null) {
      _service.onSignMessage.listen((message) {
        _lastSignMessage = message;
        onSignDetected(message);
        notifyListeners();
      });
    }
  }
  
  // Process a camera frame
  Future<String?> processFrame(XFile imageFile) async {
    final result = await _service.processFrame(imageFile);
    if (result != null) {
      _lastSignMessage = result;
      notifyListeners();
    }
    return result;
  }
  
  // Toggle detection
  void toggleDetection(bool detect) {
    _service.toggleDetection(detect);
    notifyListeners();
  }
  
  // Clean up
  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}