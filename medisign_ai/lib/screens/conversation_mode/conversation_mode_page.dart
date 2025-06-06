// lib/screens/conversation/conversation_mode_page.dart

import 'dart:async';
import 'dart:html' as html;     // for speech synthesis if needed
import 'dart:js' as js;        // for Web Speech API
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../dashboard/dashboard_page.dart';

class ConversationModePage extends StatefulWidget {
  /// If non-null, immediately send this as the patient's first turn
  final String? initialPrompt;

  const ConversationModePage({
    Key? key,
    this.initialPrompt,
  }) : super(key: key);

  @override
  State<ConversationModePage> createState() => _ConversationModePageState();
}

class _ConversationModePageState extends State<ConversationModePage> {
  bool listening = false;
  late js.JsObject? _speechRec;
  late DocumentReference _convoRef;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final TextEditingController _inputCtrl = TextEditingController();
  bool _hasInteracted = false; 
  bool _autoTranslate = true; 
  final Set<int> _translatingIndices = {};

  // Example entries shown until the user interacts
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
    _startConversation().then((_) {
      // Inject the initial prompt if provided
      final prompt = widget.initialPrompt;
      if (prompt != null && prompt.trim().isNotEmpty) {
        _removeExampleData();
        _addMessage('Patient', prompt, example: false);
      }
    });
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
      _speechRec = null;
      return;
    }
    _speechRec = js.JsObject(ctor);
    _speechRec!['continuous']    = false;
    _speechRec!['interimResults'] = false;
    _speechRec!['lang']           = 'en-US';

    _speechRec!.callMethod('addEventListener', [
      'result',
      js.allowInterop((rawEvent) {
        final ev      = js.JsObject.fromBrowserObject(rawEvent);
        final results = ev['results'];
        if (results != null) {
          final firstResult = (results as dynamic)[0];
          final bestAlt     = (firstResult as dynamic)[0];
          final transcript  = bestAlt['transcript'] as String?;
          if (transcript != null && transcript.isNotEmpty) {
            _handlePatientSpeech(transcript);
          }
        }
        setState(() => listening = false);
      }),
    ]);

    _speechRec!.callMethod('addEventListener', [
      'end',
      js.allowInterop((_) => setState(() => listening = false)),
    ]);

    _speechRec!.callMethod('addEventListener', [
      'error',
      js.allowInterop((error) {
        setState(() => listening = false);
      }),
    ]);
  }

  Future<void> _handlePatientSpeech(String origText) async {
    _removeExampleData();
    await _addMessage('Patient', origText, example: false);
    if (_shouldTranslate(origText)) {
      final messageIndex = _transcript.length - 1;
      if (_autoTranslate) {
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
        _transcript.removeWhere((e) => e['example'] == true);
        _hasInteracted = true;
      });
    }
  }

  Future<void> _addMessage(String speaker, String message, { required bool example }) async {
    final now = DateTime.now();
    setState(() {
      _transcript.add({
        'speaker': speaker,
        'message': message,
        'timestamp': now,
        'example': example,
        'translated': false,
        'translationFailed': false,
      });
    });
    if (!example) {
      await _convoRef.collection('messages').add({
        'speaker': speaker,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _convoRef.update({'lastUpdated': FieldValue.serverTimestamp()});
    }
  }

  Future<void> _translateEntry(int index, { bool isAutoTranslation = false }) async {
    if (index >= _transcript.length || _translatingIndices.contains(index)) return;
    final entry   = _transcript[index];
    final orig    = entry['message'] as String;
    final speaker = entry['speaker'] as String;
    if (speaker.contains('(EN)')) return;

    _translatingIndices.add(index);
    try {
      if (!isAutoTranslation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 16),
                Text('Translating…'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      final res = await _functions
          .httpsCallable('translateText')
          .call({'text': orig, 'targetLang': 'en'});
      final translated = (res.data['translatedText'] as String?) ?? '';
      if (translated.isNotEmpty && translated.toLowerCase() != orig.toLowerCase()) {
        await _addMessage('$speaker (EN)', translated, example: false);
        setState(() => _transcript[index]['translated'] = true);
        if (!isAutoTranslation) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Translation complete')),
          );
        }
      } else {
        setState(() => _transcript[index]['translationFailed'] = true);
        if (!isAutoTranslation) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No translation needed')),
          );
        }
      }
    } catch (e) {
      setState(() => _transcript[index]['translationFailed'] = true);
      if (!isAutoTranslation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation failed: $e')),
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
    } catch (_) {}
  }

  void _stopListening() {
    try {
      _speechRec?.callMethod('stop');
      setState(() => listening = false);
    } catch (_) {}
  }

  Future<void> _endSession() async {
    await _convoRef.update({
      'endedAt': FieldValue.serverTimestamp(),
      'status':  'pending_admin',
    });
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientDashboardPage()),
      );
    }
  }

  bool _shouldTranslate(String text) {
    final nonAscii = RegExp(r'[^\x00-\x7F]');
    if (nonAscii.hasMatch(text)) return true;
    if (text.trim().split(' ').length <= 2) return true;
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
          IconButton(
            icon: Icon(_autoTranslate ? Icons.translate : Icons.translate_outlined),
            onPressed: () {
              setState(() => _autoTranslate = !_autoTranslate);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_autoTranslate 
                    ? 'Auto-translation enabled' 
                    : 'Auto-translation disabled'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
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
              itemBuilder: (ctx, i) {
                final e       = _transcript[i];
                final speaker = e['speaker'] as String;
                final msg     = e['message'] as String;
                final t       = e['timestamp'] as DateTime;
                final example = e['example'] as bool;
                final translated      = e['translated'] as bool? ?? false;
                final failed          = e['translationFailed'] as bool? ?? false;
                final isDoctor        = speaker.startsWith('Dr.');
                final isPatient       = speaker.startsWith('Patient');
                final timeStr         = '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

                final showTranslate = 
                      !example
                  && isPatient
                  && !speaker.contains('(EN)')
                  && !translated;

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
                        Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if (example) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(Example – tap to remove)',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                        if (_translatingIndices.contains(i)) ...[
                          const SizedBox(width: 8),
                          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ],
                    ),
                    onTap: example 
                      ? () => setState(() => _transcript.removeAt(i)) 
                      : null,
                    trailing: showTranslate
                      ? IconButton(
                          icon: const Icon(Icons.translate),
                          color: primaryColor,
                          tooltip: failed ? 'Retry translation' : 'Translate to English',
                          onPressed: () => _translateEntry(i),
                        )
                      : null,
                  ),
                );
              },
            ),
          ),

          // helper hint
          if (_transcript.any((e) => e['example'] == true))
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap example messages to remove them, or start typing/speaking to begin',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),

          // input row
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(offset: const Offset(0,-2), blurRadius: 4, color: Colors.black.withOpacity(0.1)),
            ]),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(listening ? Icons.mic_off : Icons.mic,
                    color: listening ? Colors.red : primaryColor),
                  onPressed: listening ? _stopListening : _startListening,
                ),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type or speak your message…',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: _handlePatientText,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: primaryColor,
                  onPressed: () => _handlePatientText(_inputCtrl.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}