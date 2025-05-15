import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/accessibility_provider.dart';
import '../health_checkin/health_checkin_page.dart';

/// Model for a single translation entry
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

/// Simulated sign-to-text provider
class SignToHealthProvider extends ChangeNotifier {
  bool _isDetecting = false;
  Function(String)? _onSignDetected;
  final List<String> _possibleSigns = [
    'Hello, I need medical assistance',
    'I am in pain',
    'I have a headache',
    'I have a fever',
    'I have a cough',
    'My stomach hurts',
    'I feel dizzy',
    'I need my medicine',
    'I need to see a doctor',
    'I need water',
    'Yes',
    'No',
    'I need help urgently',
    'I am having an allergic reaction',
    'I am having difficulty breathing',
  ];

  Future<void> initialize({Function(String)? onSignDetected}) async {
    _onSignDetected = onSignDetected;
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void toggleDetection(bool isDetecting) {
    _isDetecting = isDetecting;
    notifyListeners();
  }

  Future<void> processFrame(XFile file) async {
    if (!_isDetecting || _onSignDetected == null) return;
    await Future.delayed(const Duration(milliseconds: 500));
    final index = DateTime.now().millisecondsSinceEpoch % _possibleSigns.length;
    _onSignDetected!(_possibleSigns[index]);
  }
}

class SignTranslatePage extends StatefulWidget {
  const SignTranslatePage({Key? key}) : super(key: key);

  @override
  _SignTranslatePageState createState() => _SignTranslatePageState();
}

class _SignTranslatePageState extends State<SignTranslatePage>
    with WidgetsBindingObserver {
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
    _signToHealthProvider = SignToHealthProvider();
    _initializeCamera();
    _initializeTts();
    _generateSessionId();
    Future.microtask(_initializeSignLanguageDetection);
  }

  Future<void> _initializeSignLanguageDetection() async {
    try {
      await _signToHealthProvider
          .initialize(onSignDetected: _handleSignDetection);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign detection init error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _handleSignDetection(String signText) {
    if (!mounted) return;
    setState(() {
      _translationItems.add(
        TranslationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sign: signText.split(' ')[0],
          text: signText,
          confidence: 0.9,
          timestamp: Timestamp.now(),
          imagePath: null,
        ),
      );
    });
    if (_sendToHealthCheckin) _forwardToHealthCheckin(signText);
  }

  void _forwardToHealthCheckin(String signText) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HealthCheckinPage(initialSignLanguageInput: signText),
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
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _generateSessionId() {
    _currentSessionId = const Uuid().v4();
  }

  /// ─── UPDATED: skip permission on Web, initialize on mobile ──────────────
  Future<void> _initializeCamera() async {
    try {
      // On Android/iOS ask for camera permission; skip on Web/desktop
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final status = await Permission.camera.request();
        if (status != PermissionStatus.granted) {
          _showErrorSnackbar('Camera permission required');
          return;
        }
      }

      // List available cameras (works on Web via camera_web plugin)
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw 'No cameras available';

      // Prefer the front-facing camera if present
      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_selectedCameraIndex < 0) _selectedCameraIndex = 0;

      // Set up the selected controller
      await _setupCamera(_cameras[_selectedCameraIndex]);

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      _showErrorSnackbar('Camera init failed: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    await _cameraController?.dispose();
     final imageGroup = (!kIsWeb && Platform.isAndroid)
      ? ImageFormatGroup.yuv420
      : ImageFormatGroup.bgra8888;
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );
    try {
      await _cameraController!.initialize();
    } catch (e) {
      _showErrorSnackbar('Camera error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final next = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = next;
    await _setupCamera(_cameras[next]);
    setState(() {});
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage(
        _outputLanguage == 'English' ? 'en-US' : 'ms-MY');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _toggleDetection() {
    _isDetecting ? _stopDetection() : _startDetection();
  }

  void _startDetection() {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      _showErrorSnackbar('Camera not initialized');
      return;
    }
    _detectionTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _processFrame());
    _signToHealthProvider.toggleDetection(true);
    _signDetectionTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _processSignLanguageFrame(),
    );
    setState(() => _isDetecting = true);
  }

  void _stopDetection() {
    _detectionTimer?.cancel();
    _signDetectionTimer?.cancel();
    _signToHealthProvider.toggleDetection(false);
    setState(() => _isDetecting = false);
  }

  Future<void> _processSignLanguageFrame() async {
    if (!_isDetecting ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) return;
    try {
      final file = await _cameraController!.takePicture();
      await _signToHealthProvider.processFrame(file);
    } catch (_) {}
  }

  Future<void> _processFrame() async {
    if (_isProcessingFrame ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) return;
    _isProcessingFrame = true;
    try {
      final file = await _cameraController!.takePicture();
      final result = await _predictSignLanguage(file.path);
      if (result != null) _addTranslation(result);
    } catch (_) {}
    _isProcessingFrame = false;
  }

  Future<Map<String, dynamic>?> _predictSignLanguage(
      String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);
      // … call your real ML API here …
      await Future.delayed(const Duration(milliseconds: 500));
      final gestures = [
        {'sign': 'Hello', 'text': 'Hello', 'confidence': 0.95},
        {'sign': 'Thank you', 'text': 'Thank you', 'confidence': 0.92},
        {'sign': 'Help', 'text': 'Help', 'confidence': 0.89},
        {'sign': 'Doctor', 'text': 'Doctor', 'confidence': 0.91},
        {'sign': 'Water', 'text': 'Water', 'confidence': 0.93},
        {'sign': 'Pain', 'text': 'I am in pain', 'confidence': 0.88},
        {'sign': 'Medicine', 'text': 'I need medicine', 'confidence': 0.9},
      ];
      final idx = DateTime.now().millisecondsSinceEpoch % gestures.length;
      return {
        'sign': gestures[idx]['sign'],
        'text': gestures[idx]['text'],
        'confidence': gestures[idx]['confidence'],
        'image_path': imagePath,
      };
    } catch (_) {
      return null;
    }
  }

  void _addTranslation(Map<String, dynamic> result) {
    setState(() {
      _translationItems.add(TranslationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sign: result['sign'],
        text: result['text'],
        confidence: result['confidence'],
        timestamp: Timestamp.now(),
        imagePath: result['image_path'],
      ));
    });
    if (_outputFormat == 'Text-to-Speech') _speakText(result['text']);
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.speak(text);
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Conversation'),
        content:
            const Text('Are you sure you want to clear the transcript?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _translationItems.clear();
                _generateSessionId();
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
      _showErrorSnackbar('No translations to save');
      return;
    }
    setState(() => _isProcessingFrame = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorSnackbar('You need to be logged in to save sessions');
        return;
      }

      final sessionRef =
          _firestore.collection('translation_sessions').doc(_currentSessionId);
      await sessionRef.set({
        'userId': user.uid,
        'createdAt': Timestamp.now(),
        'inputMethod': _inputMethod,
        'inputLanguage': _inputLanguage,
        'outputLanguage': _outputLanguage,
        'itemCount': _translationItems.length,
      });

      final batch = _firestore.batch();
      for (final item in _translationItems) {
        String? imageUrl;
        if (item.imagePath != null) {
          final file = File(item.imagePath!);
          if (await file.exists()) {
            final storageRef = _storage
                .ref()
                .child('translation_images')
                .child(_currentSessionId!)
                .child('${item.id}.jpg');
            await storageRef.putFile(file);
            imageUrl = await storageRef.getDownloadURL();
          }
        }
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
      _showSuccessDialog('Translation session saved successfully!');
      _generateSessionId();
    } catch (e) {
      _showErrorSnackbar('Failed to save session: $e');
    } finally {
      setState(() => _isProcessingFrame = false);
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
              child: const Text('OK'))
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final acc = Provider.of<AccessibilityProvider>(context);
    final primaryColor = const Color(0xFFF45B69);
    final textSize = acc.fontSize / 16.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sign Language Translator',
            style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20 * textSize)),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera,
                color: _isCameraInitialized ? Colors.black : Colors.grey),
            onPressed: _isCameraInitialized ? _switchCamera : null,
          )
        ],
      ),

      body: _isProcessingFrame && _translationItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _isCameraInitialized
                            ? CameraPreview(_cameraController!)
                            : Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                    child: Text('Initializing camera...')),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed:
                          _isCameraInitialized ? _toggleDetection : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                      ),
                      icon:
                          Icon(_isDetecting ? Icons.stop : Icons.videocam),
                      label: Text(
                          _isDetecting ? 'Stop Detection' : 'Start Detection',
                          style: TextStyle(fontSize: 16 * textSize)),
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: Text('Settings',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18 * textSize)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _inputMethod,
                                decoration:
                                    _dropdownDecoration('Input Method'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Sign to Text/Speech',
                                      child:
                                          Text('Sign to Text/Speech')),
                                  DropdownMenuItem(
                                      value: 'Text/Speech to Sign',
                                      child:
                                          Text('Text/Speech to Sign')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _inputMethod = v!),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _outputFormat,
                                decoration:
                                    _dropdownDecoration('Output Format'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Text-Only',
                                      child: Text('Text-Only')), 
                                  DropdownMenuItem(
                                      value: 'Text-to-Speech',
                                      child: Text('Text-to-Speech')),
                                  DropdownMenuItem(
                                      value: 'Braille Format',
                                      child: Text('Braille Format')),
                                ],
                                onChanged: (v) {
                                  setState(() => _outputFormat = v!);
                                  if (v == 'Text-to-Speech')
                                    _initializeTts();
                                },
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _inputLanguage,
                                decoration: _dropdownDecoration(
                                    'Input Sign Language'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'BIM',
                                      child: Text(
                                          'Malaysian Sign Language (BIM)')),
                                  DropdownMenuItem(
                                      value: 'BISINDO',
                                      child: Text(
                                          'Indonesian Sign Language (BISINDO)')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _inputLanguage = v!),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _outputLanguage,
                                decoration:
                                    _dropdownDecoration('Output Language'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'English',
                                      child: Text('English')),
                                  DropdownMenuItem(
                                      value: 'Malay',
                                      child: Text('Malay')),
                                ],
                                onChanged: (v) {
                                  setState(() => _outputLanguage = v!);
                                  _initializeTts();
                                },
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: Text('Auto-Detect Language',
                                    style:
                                        TextStyle(fontSize: 16 * textSize)),
                                value: _autoDetect,
                                onChanged: (v) =>
                                    setState(() => _autoDetect = v),
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: Text('Send to Health Check-in',
                                    style:
                                        TextStyle(fontSize: 16 * textSize)),
                                subtitle: Text(
                                    'Forward detected signs to Health Assistant',
                                    style:
                                        TextStyle(fontSize: 14 * textSize)),
                                value: _sendToHealthCheckin,
                                onChanged: (v) =>
                                    setState(() => _sendToHealthCheckin = v),
                                activeColor: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Translations',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18 * textSize,
                                color: primaryColor)),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const HealthCheckinPage())),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(20))),
                          child: Text('Health Check-in',
                              style: TextStyle(fontSize: 14 * textSize)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _translationItems.isEmpty
                        ? SizedBox(
                            height: 150,
                            child: Center(
                              child: Text(
                                'No translations yet. Tap "Start Detection" to begin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16 * textSize),
                              ),
                            ),
                          )
                        : Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _translationItems.length,
                              itemBuilder: (context, i) {
                                final item = _translationItems[i];
                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  margin:
                                      const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                        'Sign: ${item.sign} → Text: ${item.text}',
                                        style: TextStyle(
                                            fontSize: 16 * textSize)),
                                    subtitle: Text(
                                        'Confidence: ${(item.confidence * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                            fontSize: 14 * textSize,
                                            color: Colors.grey.shade600)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_outputFormat ==
                                            'Text-to-Speech')
                                          IconButton(
                                            icon: const Icon(
                                                Icons.volume_up),
                                            onPressed: () =>
                                                _speakText(item.text),
                                          ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.medical_services_outlined),
                                          color: primaryColor,
                                          onPressed: () =>
                                              _forwardToHealthCheckin(
                                                  item.text),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearConversation,
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12)),
                            icon: const Icon(Icons.clear),
                            label: Text('Clear',
                                style: TextStyle(
                                    fontSize: 16 * textSize)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveSession,
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            20)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12)),
                            icon: const Icon(Icons.save),
                            label: Text('Save',
                                style: TextStyle(
                                    fontSize: 16 * textSize)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}