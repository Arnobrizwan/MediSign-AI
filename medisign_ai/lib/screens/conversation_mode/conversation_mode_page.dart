// lib/screens/conversation_mode/conversation_mode_page.dart

import 'dart:async';
import 'dart:html' as html;     // for speech synthesis
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

  late js.JsObject _speechRec;
  late DocumentReference _convoRef;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  final List<Map<String, dynamic>> _transcript = [];
  final TextEditingController _inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startConversation();
    _initSpeechRecognition();
  }

  Future<void> _startConversation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _convoRef = FirebaseFirestore.instance
      .collection('conversations')
      .doc();

    await _convoRef.set({
      'userUid': user.uid,
      'startedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'status': 'in_progress',
    });
  }

  void _initSpeechRecognition() {
  final ctor = js.context['SpeechRecognition'] ?? js.context['webkitSpeechRecognition'];
  _speechRec = js.JsObject(ctor);
  _speechRec['continuous'] = false;
  _speechRec['interimResults'] = false;
  _speechRec['lang'] = 'en-US';

  // Listen for results
  _speechRec.callMethod('addEventListener', [
    'result',
    js.allowInterop((rawEvent) {
      // Wrap it into a JsObject so we can safely index it
      final ev = js.JsObject.fromBrowserObject(rawEvent);
      final results = ev['results'];
      if (results != null) {
        // results[0] might be undefined, so guard
        final firstResult = (results as dynamic)[0];
        if (firstResult != null) {
          final bestAlternative = (firstResult as dynamic)[0];
          if (bestAlternative != null) {
            final transcript = bestAlternative['transcript'] as String?;
            if (transcript != null && transcript.isNotEmpty) {
              _handlePatientSpeech(transcript);
            }
          }
        }
      }
      setState(() => listening = false);
    }),
  ]);

  // When the recognition service ends
  _speechRec.callMethod('addEventListener', [
    'end',
    js.allowInterop((_) {
      setState(() => listening = false);
    }),
  ]);
}

  Future<void> _handlePatientSpeech(String origText) async {
    // 1. store original
    await _addMessage('Patient', origText);

    // 2. translate to English
    try {
      final res = await _functions
        .httpsCallable('translateText')
        .call({'text': origText, 'targetLang': 'en'});
      final en = (res.data['translatedText'] as String?) ?? '';
      if (en.isNotEmpty) {
        await _addMessage('Patient (EN)', en);
      }
    } catch (e) {
      debugPrint('Translation error: $e');
    }
  }

  Future<void> _handlePatientText(String text) async {
    _inputCtrl.clear();
    await _handlePatientSpeech(text);
  }

  Future<void> _addMessage(String speaker, String message) async {
    final now = DateTime.now();

    setState(() {
      _transcript.add({
        'speaker': speaker,
        'message': message,
        'timestamp': now,
      });
    });

    await _convoRef.collection('messages').add({
      'speaker': speaker,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // bump lastUpdated
    await _convoRef.update({
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  void _startListening() {
    _speechRec.callMethod('start');
    setState(() => listening = true);
  }

  void _stopListening() {
    _speechRec.callMethod('stop');
    setState(() => listening = false);
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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Mode'),
        backgroundColor: primaryColor,
        actions: [
          TextButton(
            onPressed: _endSession,
            child: const Text(
              'End & Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Transcript area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _transcript.length,
              itemBuilder: (context, i) {
                final e = _transcript[i];
                final speaker = e['speaker'] as String;
                final msg     = e['message'] as String;
                final t        = e['timestamp'] as DateTime;
                final timeStr  = '${t.hour.toString().padLeft(2,'0')}:'
                                   '${t.minute.toString().padLeft(2,'0')}';
                final isDoctor = speaker.startsWith('Dr.');

                return ListTile(
                  leading: Icon(
                    Icons.person,
                    color: isDoctor ? Colors.blue : primaryColor,
                  ),
                  title: Text('$speaker: $msg'),
                  subtitle: Text(
                    timeStr,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

          // Input + mic row
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    listening ? Icons.mic_off : Icons.mic,
                    color: primaryColor,
                  ),
                  onPressed:
                      listening ? _stopListening : _startListening,
                ),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type or speak your message…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (txt) {
                      if (txt.trim().isNotEmpty)
                        _handlePatientText(txt.trim());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: primaryColor,
                  onPressed: () {
                    final txt = _inputCtrl.text.trim();
                    if (txt.isNotEmpty) _handlePatientText(txt);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}