import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform, File;
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

/// Fake sign‐to‐text provider (simulates detections)
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
    // pretend some async init
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void toggleDetection(bool on) {
    _isDetecting = on;
    notifyListeners();
  }

  Future<void> processFrame(XFile file) async {
    if (!_isDetecting || _onSignDetected == null) return;
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = DateTime.now().millisecondsSinceEpoch % _possibleSigns.length;
    _onSignDetected!(_possibleSigns[idx]);
  }
}

class SignTranslatePage extends StatefulWidget {
  const SignTranslatePage({Key? key}) : super(key: key);

  @override
  _SignTranslatePageState createState() => _SignTranslatePageState();
}

class _SignTranslatePageState extends State<SignTranslatePage>
    with WidgetsBindingObserver {
  // ─── Camera & detection ───────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;

  bool _isDetecting = false;
  bool _isProcessingFrame = false;
  Timer? _detectionTimer;
  Timer? _signDetectionTimer;

  // ─── Settings ─────────────────────────────────────────────────
  String _inputMethod = 'Sign to Text/Speech';
  String _outputFormat = 'Text-Only';
  String _inputLanguage = 'BIM';
  String _outputLanguage = 'English';
  bool _autoDetect = true;
  bool _sendToHealthCheckin = false;

  // ─── Firebase & TTS ───────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FlutterTts _flutterTts = FlutterTts();

  // ─── Results ──────────────────────────────────────────────────
  List<TranslationItem> _translationItems = [];
  String? _currentSessionId;

  // ─── Fake ML provider ────────────────────────────────────────
  late SignToHealthProvider _signToHealthProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // fake sign-to-text
    _signToHealthProvider = SignToHealthProvider();
    Future.microtask(_initializeSignLanguageDetection);

    // TTS & session ID
    _initializeTts();
    _generateSessionId();

    // camera setup
    _initializeCamera();
  }

  Future<void> _initializeSignLanguageDetection() async {
    try {
      await _signToHealthProvider.initialize(
        onSignDetected: _handleSignDetection,
      );
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
      _translationItems.add(TranslationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sign: signText.split(' ')[0],
        text: signText,
        confidence: 0.9,
        timestamp: Timestamp.now(),
        imagePath: null,
      ));
    });

    if (_sendToHealthCheckin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HealthCheckinPage(initialSignLanguageInput: signText),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _flutterTts.stop();
    _stopDetection();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // re-init on resume
    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _generateSessionId() {
    _currentSessionId = const Uuid().v4();
  }

  /// Initialize camera with proper Platform checks
  Future<void> _initializeCamera() async {
    try {
      // only request permission on Android/iOS
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final status = await Permission.camera.request();
        if (status != PermissionStatus.granted) {
          _showErrorSnackbar('Camera permission required');
          return;
        }
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw 'No cameras found';

      // prefer front camera
      _selectedCameraIndex = _cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
          );
      if (_selectedCameraIndex < 0) _selectedCameraIndex = 0;

      await _setupCamera(_cameras[_selectedCameraIndex]);

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      _showErrorSnackbar('Camera init failed: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    // dispose old
    await _cameraController?.dispose();

    // pick a web-safe format on web; on Android use yuv420
    final format = (!kIsWeb && Platform.isAndroid)
        ? ImageFormatGroup.yuv420
        : ImageFormatGroup.bgra8888;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: format,
    );

    try {
      await _cameraController!.initialize();
    } catch (e) {
      _showErrorSnackbar('Camera error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCamera(_cameras[_selectedCameraIndex]);
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

    // every second run placeholder ML, every 1.5s run fake detect
    _detectionTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _processFrame());
    _signDetectionTimer =
        Timer.periodic(const Duration(milliseconds: 1500), (_) async {
      if (_cameraController != null &&
          _cameraController!.value.isInitialized) {
        final pic = await _cameraController!.takePicture();
        _signToHealthProvider.processFrame(pic);
      }
    });

    _signToHealthProvider.toggleDetection(true);
    setState(() => _isDetecting = true);
  }

  void _stopDetection() {
    _detectionTimer?.cancel();
    _signDetectionTimer?.cancel();
    _signToHealthProvider.toggleDetection(false);
    setState(() => _isDetecting = false);
  }

  /// Placeholder for real ML — here we do nothing
  Future<void> _processFrame() async {
    if (_isProcessingFrame ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) return;

    _isProcessingFrame = true;
    try {
      await _cameraController!.takePicture();
      // If you had an ML API, you'd send the bytes here, then call _addTranslation()
    } catch (_) {}
    _isProcessingFrame = false;
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _speakText(String text) {
    if (_outputFormat == 'Text-to-Speech') {
      _flutterTts.speak(text);
    }
  }

  InputDecoration _dropdownDecoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );

  @override
  Widget build(BuildContext context) {
    final acc = Provider.of<AccessibilityProvider>(context);
    final primaryColor = const Color(0xFFF45B69);
    final textSize = acc.fontSize / 16.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: BackButton(color: Colors.black),
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
            icon: Icon(Icons.switch_camera,
                color: _isCameraInitialized
                    ? Colors.black
                    : Colors.grey),
            onPressed:
                _isCameraInitialized ? _switchCamera : null,
          ),
        ],
      ),
      body: _isProcessingFrame && _translationItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Camera preview
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _isCameraInitialized
                          ? CameraPreview(_cameraController!)
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                  child:
                                      Text('Initializing camera...')),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start/stop detection
                  ElevatedButton.icon(
                    icon: Icon(
                        _isDetecting ? Icons.stop : Icons.videocam),
                    label: Text(
                        _isDetecting
                            ? 'Stop Detection'
                            : 'Start Detection',
                        style:
                            TextStyle(fontSize: 16 * textSize)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isCameraInitialized
                        ? _toggleDetection
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Settings panel
                  ExpansionTile(
                    title: Text('Settings',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18 * textSize)),
                    childrenPadding:
                        const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      DropdownButtonFormField<String>(
                        value: _inputMethod,
                        decoration:
                            _dropdownDecoration('Input Method'),
                        items: const [
                          DropdownMenuItem(
                              value: 'Sign to Text/Speech',
                              child: Text(
                                  'Sign to Text/Speech')),
                          DropdownMenuItem(
                              value: 'Text/Speech to Sign',
                              child: Text(
                                  'Text/Speech to Sign')),
                        ],
                        onChanged: (v) => setState(() {
                          _inputMethod = v!;
                        }),
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
                          setState(() {
                            _outputFormat = v!;
                          });
                          if (v == 'Text-to-Speech') {
                            _initializeTts();
                          }
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
                        onChanged: (v) => setState(() {
                          _inputLanguage = v!;
                        }),
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
                          setState(() {
                            _outputLanguage = v!;
                          });
                          _initializeTts();
                        },
                      ),
                      const SizedBox(height: 8),

                      SwitchListTile(
                        title: Text('Auto-Detect Language',
                            style: TextStyle(
                                fontSize: 16 * textSize)),
                        value: _autoDetect,
                        onChanged: (v) =>
                            setState(() => _autoDetect = v),
                      ),

                      SwitchListTile(
                        title: Text('Send to Health Check-in',
                            style: TextStyle(
                                fontSize: 16 * textSize)),
                        subtitle: Text(
                            'Forward detected signs to Health Assistant',
                            style: TextStyle(
                                fontSize: 14 * textSize)),
                        value: _sendToHealthCheckin,
                        onChanged: (v) => setState(
                            () => _sendToHealthCheckin = v),
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Translations header + health‐checkin button
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
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
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(20))),
                        child: Text('Health Check-in',
                            style:
                                TextStyle(fontSize: 14 * textSize)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Translations list or placeholder
                  _translationItems.isEmpty
                      ? SizedBox(
                          height: 120,
                          child: Center(
                            child: Text(
                              'No translations yet.\nHit "Start Detection" to begin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16 * textSize),
                            ),
                          ),
                        )
                      : Container(
                          constraints:
                              const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _translationItems.length,
                            itemBuilder: (ctx, i) {
                              final item = _translationItems[i];
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                                margin: const EdgeInsets
                                    .symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(
                                      'Sign: ${item.sign} → Text: ${item.text}',
                                      style: TextStyle(
                                          fontSize:
                                              16 * textSize)),
                                  subtitle: Text(
                                      'Confidence: ${(item.confidence * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                          fontSize:
                                              14 * textSize,
                                          color: Colors
                                              .grey.shade600)),
                                  trailing: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      if (_outputFormat ==
                                          'Text-to-Speech')
                                        IconButton(
                                          icon: const Icon(
                                              Icons.volume_up),
                                          onPressed: () =>
                                              _speakText(
                                                  item.text),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons
                                            .medical_services_outlined),
                                        color: primaryColor,
                                        onPressed: () =>
                                            Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                HealthCheckinPage(
                                                    initialSignLanguageInput:
                                                        item
                                                            .text),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 16),

                  // Clear & Save buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _translationItems.clear();
                              _generateSessionId();
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: Text('Clear',
                              style: TextStyle(
                                  fontSize: 16 * textSize)),
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          20)),
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // your save logic here
                          },
                          icon: const Icon(Icons.save),
                          label: Text('Save',
                              style: TextStyle(
                                  fontSize: 16 * textSize)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          20))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}