import 'dart:async';
import 'dart:html' as html;     // for speech synthesis (if you ever need it)
import 'dart:js' as js;        // for Web Speech API
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../dashboard/dashboard_page.dart';

class ConversationModePage extends StatefulWidget {
  const ConversationModePage({Key? key}) : super(key: key);

  @override
  State<ConversationModePage> createState() => _ConversationModePageState();
}

class _ConversationModePageState extends State<ConversationModePage> {
  bool listening = false;
  late js.JsObject? _speechRec;
  late DocumentReference _convoRef;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final TextEditingController _inputCtrl = TextEditingController();
  bool _hasInteracted = false; // Track if user has interacted (to remove hardcoded data)
  bool _autoTranslate = true; // Control auto-translation setting
  
  // Track which messages are being translated to avoid duplicates
  final Set<int> _translatingIndices = {};

  // Pre-populated example conversation entries
  List<Map<String, dynamic>> _transcript = [
    {
      'speaker': 'Dr. Mim',
      'message': 'Hello, how can I assist you today?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      'example': true,
    },
    {
      'speaker': 'Patient',
      'message': 'I have a headache.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
      'example': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startConversation();
    _initSpeechRecognition();
  }

  Future<void> _startConversation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _convoRef = FirebaseFirestore.instance.collection('conversations').doc();
    await _convoRef.set({
      'userUid': user.uid,
      'startedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'status': 'in_progress',
    });
  }

  void _initSpeechRecognition() {
    final ctor = js.context['SpeechRecognition'] ?? js.context['webkitSpeechRecognition'];
    if (ctor == null) {
      debugPrint('Speech Recognition not supported in this browser');
      _speechRec = null;
      return;
    }
    
    _speechRec = js.JsObject(ctor);
    _speechRec!['continuous'] = false;
    _speechRec!['interimResults'] = false;
    _speechRec!['lang'] = 'en-US';

    _speechRec!.callMethod('addEventListener', [
      'result',
      js.allowInterop((rawEvent) {
        final ev = js.JsObject.fromBrowserObject(rawEvent);
        final results = ev['results'];
        if (results != null) {
          final firstResult = (results as dynamic)[0];
          final bestAlt = (firstResult as dynamic)[0];
          final transcript = bestAlt['transcript'] as String?;
          if (transcript != null && transcript.isNotEmpty) {
            _handlePatientSpeech(transcript);
          }
        }
        setState(() => listening = false);
      }),
    ]);

    _speechRec!.callMethod('addEventListener', [
      'end',
      js.allowInterop((_) {
        setState(() => listening = false);
      }),
    ]);

    _speechRec!.callMethod('addEventListener', [
      'error',
      js.allowInterop((error) {
        debugPrint('Speech recognition error: $error');
        setState(() => listening = false);
      }),
    ]);
  }

  Future<void> _handlePatientSpeech(String origText) async {
    // Remove hardcoded data when user first interacts
    _removeExampleData();
    
    // Add the raw patient message
    await _addMessage('Patient', origText, example: false);
    
    // Check if the text is non-English and should be translated
    if (_shouldTranslate(origText)) {
      // Get the index of the just-added message
      final messageIndex = _transcript.length - 1;
      
      if (_autoTranslate) {
        // Auto-translate without user interaction
        await _translateEntry(messageIndex, isAutoTranslation: true);
      }
    }
  }

  Future<void> _handlePatientText(String text) async {
    _inputCtrl.clear();
    if (text.trim().isNotEmpty) {
      await _handlePatientSpeech(text.trim());
    }
  }

  void _removeExampleData() {
    if (!_hasInteracted) {
      setState(() {
        _transcript.removeWhere((entry) => entry['example'] == true);
        _hasInteracted = true;
      });
    }
  }

  Future<void> _addMessage(String speaker, String message, {required bool example}) async {
    final now = DateTime.now();
    setState(() {
      _transcript.add({
        'speaker': speaker,
        'message': message,
        'timestamp': now,
        'example': example,
        'translated': false, // Will be set to true when translation is added
        'translationFailed': false, // Track if translation was attempted but failed
      });
    });
    
    // persist to Firestore only for non-example messages
    if (!example) {
      await _convoRef.collection('messages').add({
        'speaker': speaker,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _convoRef.update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  // Improved translation logic
  Future<void> _translateEntry(int index, {bool isAutoTranslation = false}) async {
    if (index >= _transcript.length || _translatingIndices.contains(index)) return;
    
    final entry = _transcript[index];
    final orig = entry['message'] as String;
    final speaker = entry['speaker'] as String;
    
    // Skip if already translated
    if (speaker.contains('(EN)')) {
      if (!isAutoTranslation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This message is already translated')),
        );
      }
      return;
    }
    
    _translatingIndices.add(index);
    
    try {
      // Show loading indicator only for manual translations
      if (!isAutoTranslation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Translating...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      final res = await _functions
          .httpsCallable('translateText')
          .call({'text': orig, 'targetLang': 'en'});
      
      final translatedText = (res.data['translatedText'] as String?) ?? '';
      if (translatedText.isNotEmpty && translatedText.toLowerCase() != orig.toLowerCase()) {
        // Add translated version
        await _addMessage('$speaker (EN)', translatedText, example: false);
        
        // Mark original as translated
        setState(() {
          _transcript[index]['translated'] = true;
        });
        
        if (!isAutoTranslation) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Translation complete')),
          );
        }
      } else {
        setState(() {
          _transcript[index]['translationFailed'] = true;
        });
        
        if (!isAutoTranslation) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No translation needed or translation failed')),
          );
        }
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      setState(() {
        _transcript[index]['translationFailed'] = true;
      });
      
      if (!isAutoTranslation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation failed: ${e.toString()}')),
        );
      }
    } finally {
      _translatingIndices.remove(index);
    }
  }

  void _startListening() {
    if (_speechRec == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }
    
    try {
      _speechRec!.callMethod('start');
      setState(() => listening = true);
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _stopListening() {
    if (_speechRec == null) return;
    
    try {
      _speechRec!.callMethod('stop');
      setState(() => listening = false);
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  Future<void> _endSession() async {
    await _convoRef.update({
      'endedAt': FieldValue.serverTimestamp(),
      'status': 'pending_admin',
    });
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientDashboardPage()),
      );
    }
  }

  bool _shouldTranslate(String text) {
    // Always show translate button for patient messages (but don't auto-translate everything)
    // This allows manual translation even for edge cases
    
    // Check for non-ASCII characters
    final nonAsciiRegex = RegExp(r'[^\x00-\x7F]');
    if (nonAsciiRegex.hasMatch(text)) {
      return true;
    }
    
    // Check for common non-English words/patterns
    final commonNonEnglishWords = [
      'ke', 'tum', 'aap', 'hai', 'hain', 'mujhe', 'tumhe', // Hindi
      'ami', 'tumi', 'apni', 'ache', 'achho', // Bengali
      'ek', 'do', 'teen', 'char', 'paanch', // Numbers in Hindi
      'ki', 'ka', 'ko', 'me', 'se', 'par', // Hindi prepositions
    ];
    
    final lowerText = text.toLowerCase();
    for (final word in commonNonEnglishWords) {
      if (lowerText.contains(word)) {
        return true;
      }
    }
    
    // If text is very short and could be non-English, show translate button
    if (text.trim().split(' ').length <= 2) {
      return true;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Mode'),
        backgroundColor: primaryColor,
        actions: [
          // Toggle for auto-translation
          IconButton(
            icon: Icon(_autoTranslate ? Icons.translate : Icons.translate_outlined),
            onPressed: () {
              setState(() {
                _autoTranslate = !_autoTranslate;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _autoTranslate 
                      ? 'Auto-translation enabled' 
                      : 'Auto-translation disabled',
                  ),
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            },
            tooltip: _autoTranslate ? 'Disable auto-translation' : 'Enable auto-translation',
          ),
          TextButton(
            onPressed: _endSession,
            child: const Text('End & Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // transcript list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _transcript.length,
              itemBuilder: (context, i) {
                final e = _transcript[i];
                final speaker = e['speaker'] as String;
                final msg = e['message'] as String;
                final t = e['timestamp'] as DateTime;
                final example = e['example'] as bool;
                final translated = e['translated'] as bool? ?? false;
                final translationFailed = e['translationFailed'] as bool? ?? false;
                final isDoctor = speaker.startsWith('Dr.');
                final isPatient = speaker.startsWith('Patient');
                final timeStr = '${t.hour.toString().padLeft(2,'0')}:' +
                                '${t.minute.toString().padLeft(2,'0')}';

                // Show translate button for patient messages that haven't been translated
                final shouldShowTranslateButton = 
                    !example && 
                    isPatient && 
                    !speaker.contains('(EN)') && 
                    !translated;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: example 
                          ? Colors.grey.shade300 
                          : (isDoctor ? Colors.blue : primaryColor),
                      child: Icon(
                        isDoctor ? Icons.medical_services : Icons.person,
                        color: example ? Colors.grey : Colors.white,
                      ),
                    ),
                    title: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: '$speaker: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: example ? Colors.grey : null,
                            ),
                          ),
                          TextSpan(
                            text: msg,
                            style: TextStyle(
                              color: example ? Colors.grey : null,
                              fontStyle: example ? FontStyle.italic : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          timeStr, 
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (example) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(Example - Tap to remove)',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                        if (_translatingIndices.contains(i)) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    // tap example messages to remove
                    onTap: example
                        ? () => setState(() => _transcript.removeAt(i))
                        : null,
                    // Show translate button for all patient messages that aren't already translated
                    trailing: shouldShowTranslateButton
                        ? Tooltip(
                            message: translationFailed ? 'Retry translation' : 'Translate to English',
                            child: IconButton(
                              icon: const Icon(Icons.translate),
                              color: primaryColor,
                              onPressed: () => _translateEntry(i),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),

          // Add a helpful instruction if there are example messages
          if (_transcript.any((e) => e['example'] == true))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Tap example messages to remove them, or start typing/speaking to begin',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

          // input row
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    listening ? Icons.mic_off : Icons.mic,
                    color: listening ? Colors.red : primaryColor,
                  ),
                  onPressed: listening ? _stopListening : _startListening,
                  tooltip: listening ? 'Stop listening' : 'Start voice input',
                ),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type or speak your message…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: _handlePatientText,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: primaryColor,
                  onPressed: () => _handlePatientText(_inputCtrl.text),
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}