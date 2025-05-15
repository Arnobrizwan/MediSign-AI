// // lib/screens/health_checkin/health_checkin_page.dart

// import 'package:flutter/material.dart';
// import '../../providers/gemini_chat_client.dart';  // <-- updated path

// class HealthCheckinPage extends StatefulWidget {
//   const HealthCheckinPage({super.key});
//   @override
//   _HealthCheckinPageState createState() => _HealthCheckinPageState();
// }

// class _HealthCheckinPageState extends State<HealthCheckinPage> {
//   final GeminiChatClient _chat = GeminiChatClient();
//   final TextEditingController _ctr = TextEditingController();

//   final List<Map<String, String>> _log = [
//     {
//       'sender': 'AI',
//       'message':
//           '👋 Hi there! Describe any health concern—symptoms, conditions, or questions—and I’ll guide you.'
//     }
//   ];

//   Future<void> _send(String txt) async {
//     // 1) Append the user’s message
//     setState(() => _log.add({'sender': 'User', 'message': txt}));

//     // 2) Call the AI, catching & logging any errors
//     try {
//       final reply = await _chat.send(txt);
//       setState(() => _log.add({'sender': 'AI', 'message': reply}));
//     } catch (e, st) {
//       // Print the full error & stacktrace to console
//       print('❌ Gemini error: $e\n$st');

//       // Show the actual exception message in the chat
//       setState(() => _log.add({
//             'sender': 'AI',
//             'message': '⚠️ Error: ${e.toString()}'
//           }));
//     }

//     // 3) Clear the text field
//     _ctr.clear();
//   }

//   @override
//   Widget build(BuildContext ctx) {
//     const primary = Color(0xFFF45B69);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('AI Health Check-In'),
//         backgroundColor: primary,
//       ),
//       body: Column(
//         children: [
//           // Chat history
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: _log.length,
//               itemBuilder: (_, i) {
//                 final entry = _log[i];
//                 final isUser = entry['sender'] == 'User';
//                 return Align(
//                   alignment:
//                       isUser ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(vertical: 4),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: isUser ? primary : Colors.grey[200],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       entry['message']!,
//                       style: TextStyle(
//                           color: isUser ? Colors.white : Colors.black87),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),

//           // Input row: voice / braille / sign / text
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.mic, color: primary),
//                   onPressed: () =>
//                       _send('Voice input: <transcribe via STT here>'),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.accessible, color: primary),
//                   onPressed: () =>
//                       _send('Braille input: <translate braille here>'),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.camera_alt, color: primary),
//                   onPressed: () => _send('Sign input: <transcribe sign here>'),
//                 ),
//                 Expanded(
//                   child: TextField(
//                     controller: _ctr,
//                     decoration: const InputDecoration(
//                       hintText: 'Type your message…',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(backgroundColor: primary),
//                   onPressed: () {
//                     if (_ctr.text.isNotEmpty) _send(_ctr.text);
//                   },
//                   child: const Icon(Icons.send, color: Colors.white),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/gemini_chat_client.dart';
import '../../services/sign_to_health_service.dart';

class HealthCheckinPage extends StatefulWidget {
  final String? initialSignLanguageInput;
  
  const HealthCheckinPage({
    super.key, 
    this.initialSignLanguageInput,
  });
  
  @override
  _HealthCheckinPageState createState() => _HealthCheckinPageState();
}

class _HealthCheckinPageState extends State<HealthCheckinPage> {
  final GeminiChatClient _chat = GeminiChatClient();
  final TextEditingController _ctr = TextEditingController();
  
  // Sign language detection
  late SignToHealthProvider _signToHealthProvider;
  bool _isSignDetectionActive = false;
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  Timer? _signDetectionTimer;

  List<Map<String, String>> _log = [
    {
      'sender': 'AI',
      'message':
          '👋 Hi there! Describe any health concern—symptoms, conditions, or questions—and I'll guide you.'
    }
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize sign language detection
    Future.delayed(Duration.zero, () {
      _initializeSignLanguageDetection();
    });
    
    // Handle initial sign language input if provided
    if (widget.initialSignLanguageInput != null && widget.initialSignLanguageInput!.isNotEmpty) {
      // Add slight delay to ensure the UI is built
      Future.delayed(const Duration(milliseconds: 300), () {
        _handleSignLanguageInput(widget.initialSignLanguageInput!);
      });
    }
  }
  
  @override
  void dispose() {
    _ctr.dispose();
    _stopSignDetection();
    _cameraController?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeSignLanguageDetection() async {
    _signToHealthProvider = Provider.of<SignToHealthProvider>(context, listen: false);
    await _signToHealthProvider.initialize(
      onSignDetected: _handleSignDetectionResult,
    );
    
    // Initialize camera (but don't start it yet)
    await _initializeCamera();
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
      final frontCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front
      );
      final cameraIndex = frontCameraIndex != -1 ? frontCameraIndex : 0;
      
      _cameraController = CameraController(
        _cameras[cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }
  
  void _handleSignDetectionResult(String signText) {
    _handleSignLanguageInput(signText);
  }
  
  void _handleSignLanguageInput(String signText) {
    // Format the message for the chatbot
    final formattedMessage = "Sign language: $signText";
    
    // Send to the chat
    _send(formattedMessage);
  }

  Future<void> _send(String txt) async {
    // 1) Append the user's message
    setState(() => _log.add({'sender': 'User', 'message': txt}));

    // 2) Call the AI, catching & logging any errors
    try {
      // Add special handling for sign language input
      String promptText = txt;
      if (txt.startsWith("Sign language:")) {
        // Add context for the AI about sign language input
        promptText = "$txt\n\nThis is from sign language translation. Please respond considering that the user may have a health concern.";
      }
      
      final reply = await _chat.send(promptText);
      setState(() => _log.add({'sender': 'AI', 'message': reply}));
    } catch (e, st) {
      // Print the full error & stacktrace to console
      print('❌ Gemini error: $e\n$st');

      // Show the actual exception message in the chat
      setState(() => _log.add({
            'sender': 'AI',
            'message': '⚠️ Error: ${e.toString()}'
          }));
    }

    // 3) Clear the text field
    _ctr.clear();
  }
  
  void _toggleSignDetection() {
    if (_isSignDetectionActive) {
      _stopSignDetection();
    } else {
      _startSignDetection();
    }
  }
  
  void _startSignDetection() {
    if (!_isCameraInitialized) {
      _showErrorSnackbar("Camera not initialized");
      return;
    }
    
    // Start the camera if it's not active
    if (!_cameraController!.value.isInitialized) {
      _initializeCamera();
    }
    
    // Enable sign detection
    _signToHealthProvider.toggleDetection(true);
    
    // Start periodic frame processing
    _signDetectionTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _processSignLanguageFrame(),
    );
    
    setState(() {
      _isSignDetectionActive = true;
    });
    
    // Show tooltip
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign language detection active. Make signs in front of camera.'),
        backgroundColor: Color(0xFFF45B69),
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  void _stopSignDetection() {
    // Disable sign detection
    _signToHealthProvider.toggleDetection(false);
    
    // Stop timer
    _signDetectionTimer?.cancel();
    
    setState(() {
      _isSignDetectionActive = false;
    });
  }
  
  Future<void> _processSignLanguageFrame() async {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized || 
        !_isSignDetectionActive) {
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
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    const primary = Color(0xFFF45B69);

    return ChangeNotifierProvider(
      create: (_) => SignToHealthProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Health Check-In'),
          backgroundColor: primary,
        ),
        body: Column(
          children: [
            // Optional: Mini camera preview when sign detection is active
            if (_isSignDetectionActive && _isCameraInitialized)
              Container(
                height: 120,
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
              
            // Chat history
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _log.length,
                itemBuilder: (_, i) {
                  final entry = _log[i];
                  final isUser = entry['sender'] == 'User';
                  
                  // Check if this is a sign language message
                  final isSignLanguage = isUser && 
                      entry['message']!.startsWith('Sign language:');
                  
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? primary : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        // Add icon indicator for sign language
                        border: isSignLanguage ? Border.all(
                          color: Colors.blue, 
                          width: 2,
                        ) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add sign language icon if applicable
                          if (isSignLanguage)
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sign_language,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Sign Language',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          if (isSignLanguage)
                            const SizedBox(height: 4),
                          
                          // Message text (clean up sign language prefix)
                          Text(
                            isSignLanguage
                                ? entry['message']!.replaceFirst('Sign language: ', '')
                                : entry['message']!,
                            style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input row: voice / braille / sign / text
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic, color: primary),
                    onPressed: () =>
                        _send('Voice input: <transcribe via STT here>'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.accessible, color: primary),
                    onPressed: () =>
                        _send('Braille input: <translate braille here>'),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.sign_language, 
                      color: _isSignDetectionActive ? Colors.green : primary,
                    ),
                    onPressed: _toggleSignDetection,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctr,
                      decoration: const InputDecoration(
                        hintText: 'Type your message…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primary),
                    onPressed: () {
                      if (_ctr.text.isNotEmpty) _send(_ctr.text);
                    },
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}