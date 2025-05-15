import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../providers/accessibility_provider.dart';
import '../../services/sign_to_health_service.dart';
import '../health_checkin/health_checkin_page.dart';

class SignTranslatePage extends StatefulWidget {
  const SignTranslatePage({super.key});

  @override
  State<SignTranslatePage> createState() => _SignTranslatePageState();
}

class _SignTranslatePageState extends State<SignTranslatePage> with WidgetsBindingObserver {
  // Camera controllers
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  
  // Detection state
  bool _isDetecting = false;
  bool _isProcessingFrame = false;
  Timer? _detectionTimer;
  Timer? _signDetectionTimer;
  
  // Translation settings
  String _inputMethod = 'Sign to Text/Speech';
  String _outputFormat = 'Text-Only';
  String _inputLanguage = 'BIM';
  String _outputLanguage = 'English';
  bool _autoDetect = true;
  bool _sendToHealthCheckin = false;
  
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Text-to-speech
  final FlutterTts _flutterTts = FlutterTts();
  
  // Translation results
  List<TranslationItem> _translationItems = [];
  String? _currentSessionId;
  
  // Sign language service
  late SignToHealthProvider _signToHealthProvider;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializeTts();
    _generateSessionId();
    
    // Initialize sign language detection
    Future.delayed(Duration.zero, () {
      _initializeSignLanguageDetection();
    });
  }
  
  Future<void> _initializeSignLanguageDetection() async {
    _signToHealthProvider = Provider.of<SignToHealthProvider>(context, listen: false);
    await _signToHealthProvider.initialize(
      onSignDetected: _handleSignDetection,
    );
  }
  
  void _handleSignDetection(String signText) {
    // Add to translations
    setState(() {
      _translationItems.add(
        TranslationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sign: signText.split(' ')[0], // Use first word as sign name
          text: signText,
          confidence: 0.9,
          timestamp: Timestamp.now(),
          imagePath: null,
        ),
      );
    });
    
    // If forwarding to health check-in is enabled
    if (_sendToHealthCheckin) {
      _forwardToHealthCheckin(signText);
    }
  }
  
  void _forwardToHealthCheckin(String signText) {
    // Navigate to health check-in page with the sign language input
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthCheckinPage(
          initialSignLanguageInput: signText,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopDetection();
    _cameraController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to properly manage camera resources
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }
  
  void _generateSessionId() {
    _currentSessionId = const Uuid().v4();
  }
  
  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showErrorSnackbar("Camera permission is required for sign language detection");
      return;
    }
    
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showErrorSnackbar("No cameras available on this device");
        return;
      }
      
      // Start with front camera if available
      _selectedCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;
      
      await _setupCamera(_cameras[_selectedCameraIndex]);
      
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      _showErrorSnackbar("Failed to initialize camera: $e");
    }
  }
  
  Future<void> _setupCamera(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );
    
    try {
      await _cameraController!.initialize();
    } catch (e) {
      _showErrorSnackbar("Error initializing camera: $e");
    }
  }
  
  Future<void> _switchCamera() async {
    if (_cameras.isEmpty || _cameras.length < 2) return;
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCamera(_cameras[_selectedCameraIndex]);
    setState(() {});
  }
  
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage(_outputLanguage == 'English' ? 'en-US' : 'ms-MY');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }
  
  void _toggleDetection() {
    if (_isDetecting) {
      _stopDetection();
    } else {
      _startDetection();
    }
  }
  
  void _startDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorSnackbar("Camera not initialized");
      return;
    }
    
    // Start traditional detection (existing code)
    _detectionTimer = Timer.periodic(const Duration(seconds: 1), (_) => _processFrame());
    
    // Start sign language detection
    _signToHealthProvider.toggleDetection(true);
    _signDetectionTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _processSignLanguageFrame(),
    );
    
    setState(() {
      _isDetecting = true;
    });
  }
  
  void _stopDetection() {
    // Stop traditional detection
    _detectionTimer?.cancel();
    
    // Stop sign language detection
    _signToHealthProvider.toggleDetection(false);
    _signDetectionTimer?.cancel();
    
    setState(() {
      _isDetecting = false;
    });
  }
  
  Future<void> _processSignLanguageFrame() async {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized || 
        !_isDetecting) {
      return;
    }
    
    try {
      // Capture image
      final XFile file = await _cameraController!.takePicture();
      
      // Process with sign language detection
      await _signToHealthProvider.processFrame(file);
    } catch (e) {
      print("Error processing sign language frame: $e");
    }
  }
  
  Future<void> _processFrame() async {
    if (_isProcessingFrame || 
        _cameraController == null || 
        !_cameraController!.value.isInitialized) {
      return;
    }
    
    _isProcessingFrame = true;
    
    try {
      // Capture image from camera
      final XFile file = await _cameraController!.takePicture();
      
      // Process with ML model
      final result = await _predictSignLanguage(file.path);
      
      if (result != null) {
        _addTranslation(result);
      }
    } catch (e) {
      print("Error processing frame: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }
  
  Future<Map<String, dynamic>?> _predictSignLanguage(String imagePath) async {
    try {
      // Prepare image for API
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Create request payload
      final payload = json.encode({
        'image': base64Image,
        'input_language': _inputLanguage,
        'output_language': _outputLanguage,
        'auto_detect': _autoDetect,
      });
      
      // For demo purposes, return mock data
      // In a real app, you'd send the request to your ML API:
      /*
      final response = await http.post(
        Uri.parse(_modelEndpoint),
        headers: _apiHeaders,
        body: payload,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to predict sign: ${response.statusCode}');
      }
      */
      
      // Mock prediction result
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simulate different gestures
      final gestures = [
        {'sign': 'Hello', 'text': 'Hello', 'confidence': 0.95},
        {'sign': 'Thank you', 'text': 'Thank you', 'confidence': 0.92},
        {'sign': 'Help', 'text': 'Help', 'confidence': 0.89},
        {'sign': 'Doctor', 'text': 'Doctor', 'confidence': 0.91},
        {'sign': 'Water', 'text': 'Water', 'confidence': 0.93},
        {'sign': 'Pain', 'text': 'I am in pain', 'confidence': 0.88},
        {'sign': 'Medicine', 'text': 'I need medicine', 'confidence': 0.9},
      ];
      
      // Random gesture from the list
      final randomIndex = DateTime.now().millisecondsSinceEpoch % gestures.length;
      final selectedGesture = gestures[randomIndex];
      
      return {
        'sign': selectedGesture['sign'],
        'text': selectedGesture['text'],
        'confidence': selectedGesture['confidence'],
        'image_path': imagePath
      };
    } catch (e) {
      print("Error in prediction: $e");
      return null;
    }
  }
  
  void _addTranslation(Map<String, dynamic> result) {
    final sign = result['sign'] as String;
    final text = result['text'] as String;
    final confidence = result['confidence'] as double;
    final imagePath = result['image_path'] as String;
    
    final newItem = TranslationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sign: sign,
      text: text,
      confidence: confidence,
      timestamp: Timestamp.now(),
      imagePath: imagePath,
    );
    
    setState(() {
      _translationItems.add(newItem);
    });
    
    // If text-to-speech is enabled, speak the translated text
    if (_outputFormat == 'Text-to-Speech') {
      _speakText(text);
    }
  }
  
  Future<void> _speakText(String text) async {
    await _flutterTts.speak(text);
  }
  
  void _clearConversation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('Are you sure you want to clear the transcript?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _translationItems.clear();
                _generateSessionId(); // Generate new session ID for next translations
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveSession() async {
    if (_translationItems.isEmpty) {
      _showErrorSnackbar("No translations to save");
      return;
    }
    
    setState(() {
      _isProcessingFrame = true;  // Use this to show loading
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorSnackbar("You need to be logged in to save sessions");
        return;
      }
      
      // Save translation items to Firestore
      final sessionRef = _firestore.collection('translation_sessions').doc(_currentSessionId);
      
      // Create session document
      await sessionRef.set({
        'userId': user.uid,
        'createdAt': Timestamp.now(),
        'inputMethod': _inputMethod,
        'inputLanguage': _inputLanguage,
        'outputLanguage': _outputLanguage,
        'itemCount': _translationItems.length,
      });
      
      // Batch save translation items
      final batch = _firestore.batch();
      
      for (final item in _translationItems) {
        // First upload the image to storage if available
        String? imageUrl;
        if (item.imagePath != null) {
          final file = File(item.imagePath!);
          if (await file.exists()) {
            final storageRef = _storage.ref()
                .child('translation_images')
                .child(_currentSessionId!)
                .child('${item.id}.jpg');
            
            await storageRef.putFile(file);
            imageUrl = await storageRef.getDownloadURL();
          }
        }
        
        // Create the translation item document
        final itemRef = sessionRef.collection('items').doc(item.id);
        batch.set(itemRef, {
          'sign': item.sign,
          'text': item.text,
          'confidence': item.confidence,
          'timestamp': item.timestamp,
          'imageUrl': imageUrl,
        });
      }
      
      await batch.commit();
      
      _showSuccessDialog("Translation session saved successfully!");
      
      // Generate new session ID for next translations
      _generateSessionId();
    } catch (e) {
      _showErrorSnackbar("Failed to save session: $e");
    } finally {
      setState(() {
        _isProcessingFrame = false;
      });
    }
  }
  
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final acc = Provider.of<AccessibilityProvider>(context);
    final primaryColor = const Color(0xFFF45B69);
    final textSize = acc.fontSize / 16.0;

    return ChangeNotifierProvider(
      create: (_) => SignToHealthProvider(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Sign Language Translator',
            style: TextStyle(
              color: primaryColor, 
              fontWeight: FontWeight.bold,
              fontSize: 20 * textSize,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.switch_camera,
                color: _isCameraInitialized ? Colors.black : Colors.grey,
              ),
              onPressed: _isCameraInitialized ? _switchCamera : null,
            ),
          ],
        ),
        body: _isProcessingFrame && _translationItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Camera View Area
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _isCameraInitialized
                        ? CameraPreview(_cameraController!)
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Center(child: Text('Initializing camera...')),
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Central Camera/Mic Button
                  ElevatedButton.icon(
                    onPressed: _isCameraInitialized ? _toggleDetection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    icon: Icon(_isDetecting ? Icons.stop : Icons.videocam),
                    label: Text(
                      _isDetecting ? 'Stop Detection' : 'Start Detection',
                      style: TextStyle(fontSize: 16 * textSize),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Collapsible settings panel
                  ExpansionTile(
                    title: Text('Settings', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18 * textSize,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _inputMethod,
                              decoration: _dropdownDecoration('Input Method'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Sign to Text/Speech', 
                                  child: Text('Sign to Text/Speech')
                                ),
                                DropdownMenuItem(
                                  value: 'Text/Speech to Sign', 
                                  child: Text('Text/Speech to Sign')
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _inputMethod = value!);
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _outputFormat,
                              decoration: _dropdownDecoration('Output Format'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Text-Only', 
                                  child: Text('Text-Only')
                                ),
                                DropdownMenuItem(
                                  value: 'Text-to-Speech', 
                                  child: Text('Text-to-Speech')
                                ),
                                DropdownMenuItem(
                                  value: 'Braille Format', 
                                  child: Text('Braille Format')
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _outputFormat = value!);
                                if (value == 'Text-to-Speech') {
                                  _initializeTts();
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _inputLanguage,
                              decoration: _dropdownDecoration('Input Sign Language'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'BIM', 
                                  child: Text('Malaysian Sign Language (BIM)')
                                ),
                                DropdownMenuItem(
                                  value: 'BISINDO', 
                                  child: Text('Indonesian Sign Language (BISINDO)')
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _inputLanguage = value!);
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _outputLanguage,
                              decoration: _dropdownDecoration('Output Language'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'English', 
                                  child: Text('English')
                                ),
                                DropdownMenuItem(
                                  value: 'Malay', 
                                  child: Text('Malay')
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _outputLanguage = value!);
                                _initializeTts();
                              },
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              title: Text(
                                'Auto-Detect Language',
                                style: TextStyle(fontSize: 16 * textSize),
                              ),
                              value: _autoDetect,
                              onChanged: (val) => setState(() => _autoDetect = val),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              title: Text(
                                'Send to Health Check-in',
                                style: TextStyle(fontSize: 16 * textSize),
                              ),
                              subtitle: Text(
                                'Forward detected signs to Health Assistant',
                                style: TextStyle(fontSize: 14 * textSize),
                              ),
                              value: _sendToHealthCheckin,
                              onChanged: (val) => setState(() => _sendToHealthCheckin = val),
                              activeColor: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Translations title with Health Check-in button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Translations',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18 * textSize, 
                          color: primaryColor,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthCheckinPage(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Health Check-in',
                          style: TextStyle(fontSize: 14 * textSize),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Real-time Translation Bubbles
                  Expanded(
                    child: _translationItems.isEmpty
                      ? Center(
                          child: Text(
                            'No translations yet. Tap "Start Detection" to begin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16 * textSize,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _translationItems.length,
                          itemBuilder: (context, index) {
                            final item = _translationItems[index];
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  'Sign: ${item.sign} → Text: ${item.text}',
                                  style: TextStyle(fontSize: 16 * textSize),
                                ),
                                subtitle: Text(
                                  'Confidence: ${(item.confidence * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 14 * textSize,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_outputFormat == 'Text-to-Speech')
                                      IconButton(
                                        icon: const Icon(Icons.volume_up),
                                        onPressed: () => _speakText(item.text),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.medical_services_outlined),
                                      color: primaryColor,
                                      onPressed: () => _forwardToHealthCheckin(item.text),
                                      tooltip: 'Send to Health Check-in',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),

                  // Action Buttons Row
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearConversation,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.clear),
                            label: Text(
                              'Clear',
                              style: TextStyle(fontSize: 16 * textSize),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.save),
                            label: Text(
                              'Save',
                              style: TextStyle(fontSize: 16 * textSize),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }
}

class TranslationItem {
  final String id;
  final String sign;
  final String text;
  final double confidence;
  final Timestamp timestamp;
  final String? imagePath;
  
  TranslationItem({
    required this.id,
    required this.sign,
    required this.text,
    required this.confidence,
    required this.timestamp,
    this.imagePath,
  });
}