
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
  late js.JsObject _speechRec;
  late DocumentReference _convoRef;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final TextEditingController _inputCtrl = TextEditingController();

  // Pre-populated example conversation entries
  final List<Map<String, dynamic>> _transcript = [
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
    _speechRec = js.JsObject(ctor);
    _speechRec['continuous'] = false;
    _speechRec['interimResults'] = false;
    _speechRec['lang'] = 'en-US';

    _speechRec.callMethod('addEventListener', [
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

    _speechRec.callMethod('addEventListener', [
      'end',
      js.allowInterop((_) {
        setState(() => listening = false);
      }),
    ]);
  }

  Future<void> _handlePatientSpeech(String origText) async {
    // 1) add the raw patient message
    await _addMessage('Patient', origText, example: false);
    // 2) we do *not* auto-translate English ASCII; translation will be on demand
  }

  Future<void> _handlePatientText(String text) async {
    _inputCtrl.clear();
    if (text.trim().isNotEmpty) {
      await _handlePatientSpeech(text.trim());
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
      });
    });
    // persist to Firestore
    await _convoRef.collection('messages').add({
      'speaker': speaker,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _convoRef.update({
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // On-demand translation for non-ASCII messages:
  Future<void> _translateEntry(int index) async {
    final entry = _transcript[index];
    final orig = entry['message'] as String;
    try {
      final res = await _functions
          .httpsCallable('translateText')
          .call({'text': orig, 'targetLang': 'en'});
      final en = (res.data['translatedText'] as String?) ?? '';
      if (en.isNotEmpty) {
        await _addMessage('Patient (EN)', en, example: false);
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation failed')),
      );
    }
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

  bool _isAscii(String s) => RegExp(r'^[\x00-\x7F]+$').hasMatch(s);

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
                final msg     = e['message'] as String;
                final t        = e['timestamp'] as DateTime;
                final example = e['example'] as bool;
                final isDoctor = speaker.startsWith('Dr.');
                final timeStr = '${t.hour.toString().padLeft(2,'0')}:' +
                                '${t.minute.toString().padLeft(2,'0')}';

                return ListTile(
                  leading: Icon(Icons.person,
                     color: isDoctor ? Colors.blue : primaryColor),
                  title: Text('$speaker: $msg'),
                  subtitle: Text(timeStr, style: const TextStyle(fontSize:12,color:Colors.grey)),
                  // tap example messages to remove
                  onTap: example
                      ? () => setState(() => _transcript.removeAt(i))
                      : null,
                  // if non-ASCII patient message, show a translate button
                  trailing: (!example && speaker=='Patient' && !_isAscii(msg))
                      ? IconButton(
                          icon: const Icon(Icons.translate),
                          color: primaryColor,
                          tooltip: 'Translate',
                          onPressed: () => _translateEntry(i),
                        )
                      : null,
                );
              },
            ),
          ),

          // input row
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(listening ? Icons.mic_off : Icons.mic,
                    color: primaryColor),
                  onPressed: listening ? _stopListening : _startListening,
                ),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type or speak your message…',
                      border: OutlineInputBorder(),
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