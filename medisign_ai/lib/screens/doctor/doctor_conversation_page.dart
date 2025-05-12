
import 'dart:async';
import 'dart:html' as html;     // for Web Speech API fallback
import 'dart:js' as js;        // for Web Speech API
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DoctorConversationPage extends StatefulWidget {
  /// If non-null, immediately send this as the patient's first turn
  final String? initialPrompt;

  /// Display name of the doctor (e.g. "Dr. Smith")
  final String doctorName;

  const DoctorConversationPage({
    Key? key,
    required this.doctorName,
    this.initialPrompt,
  }) : super(key: key);

  @override
  State<DoctorConversationPage> createState() => _DoctorConversationPageState();
}

class _DoctorConversationPageState extends State<DoctorConversationPage> {
  bool listening = false;
  js.JsObject? _speechRec;
  late DocumentReference _convoRef;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final TextEditingController _inputCtrl = TextEditingController();
  bool _hasInteracted = false;
  bool _autoTranslate = true;
  final Set<int> _translatingIndices = {};

  // transcript holds both patient & doctor turns
  List<Map<String, dynamic>> _transcript = [
    {
      'speaker': null, // will be set in initState
      'message': '',
      'timestamp': DateTime.now(),
      'example': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    // replace the placeholder with a real initial doctor message
    _transcript[0] = {
      'speaker': widget.doctorName,
      'message': 'Hello, how can I assist you today?',
      'timestamp': DateTime.now(),
      'example': true,
    };

    _startConversation().then((_) {
      if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
        _removeExampleData();
        _addMessage('Patient', widget.initialPrompt!, example: false);
      }
    });

    _initSpeechRecognition();
  }

  Future<void> _startConversation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // create a new conversation doc
    _convoRef = FirebaseFirestore.instance.collection('conversations').doc();
    await _convoRef.set({
      'doctorUid': user.uid,
      'startedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'status': 'in_progress',
    });
  }

  void _initSpeechRecognition() {
    final ctor = js.context['SpeechRecognition'] ??
        js.context['webkitSpeechRecognition'];
    if (ctor == null) {
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
      js.allowInterop((_) => setState(() => listening = false)),
    ]);
    _speechRec!.callMethod('addEventListener', [
      'error',
      js.allowInterop((_) => setState(() => listening = false)),
    ]);
  }

  Future<void> _handlePatientSpeech(String origText) async {
    _removeExampleData();
    await _addMessage('Patient', origText, example: false);
  }

  Future<void> _handleDoctorText(String text) async {
    _inputCtrl.clear();
    if (text.trim().isNotEmpty) {
      await _addMessage(widget.doctorName, text.trim(), example: false);
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
      // persist to Firestore
      await _convoRef.collection('messages').add({
        'speaker': speaker,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _convoRef.update({'lastUpdated': FieldValue.serverTimestamp()});

      // AUTO-TRANSLATE ANY PATIENT TURN
      if (speaker == 'Patient' && _autoTranslate && _shouldTranslate(message)) {
        final idx = _transcript.length - 1;
        await _translateEntry(idx, isAutoTranslation: true);
      }
    }
  }

  Future<void> _translateEntry(int index, { bool isAutoTranslation = false }) async {
    if (index < 0 || index >= _transcript.length) return;
    if (_translatingIndices.contains(index)) return;
    final entry = _transcript[index];
    final orig   = entry['message'] as String;
    final speaker = entry['speaker'] as String;
    if (speaker.contains('(EN)')) return;

    _translatingIndices.add(index);
    try {
      if (!isAutoTranslation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Translating…'), duration: Duration(seconds: 2)),
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
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Translation complete')));
        }
      } else {
        setState(() => _transcript[index]['translationFailed'] = true);
        if (!isAutoTranslation) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No translation needed')));
        }
      }
    } catch (e) {
      setState(() => _transcript[index]['translationFailed'] = true);
      if (!isAutoTranslation) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Translation failed: $e')));
      }
    } finally {
      _translatingIndices.remove(index);
    }
  }

  bool _shouldTranslate(String text) {
    // translate if any non-ASCII chars or very short text
    if (RegExp(r'[^\x00-\x7F]').hasMatch(text)) return true;
    if (text.trim().split(' ').length <= 2) return true;
    return false;
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
      'status':  'closed_by_doctor',
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorName),
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
            child: const Text('End', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _transcript.length,
              itemBuilder: (ctx, i) {
                final e         = _transcript[i];
                final speaker   = e['speaker'] as String?;
                final msg       = e['message'] as String;
                final t         = e['timestamp'] as DateTime;
                final example   = e['example'] as bool;
                final translated = e['translated'] as bool? ?? false;
                final failed     = e['translationFailed'] as bool? ?? false;
                final isDoctor   = speaker == widget.doctorName;
                final timeStr    = '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
                final showTranslate = !example
                  && speaker == 'Patient'
                  && !translated;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: example
                        ? Colors.grey.shade300
                        : (isDoctor ? primaryColor : Colors.blue),
                      child: Icon(
                        isDoctor ? Icons.medical_services : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text.rich(TextSpan(
                      children: [
                        TextSpan(
                          text: '$speaker: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: msg),
                      ],
                    )),
                    subtitle: Row(
                      children: [
                        Text(timeStr, style: const TextStyle(fontSize: 12)),
                        if (_translatingIndices.contains(i))
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                    trailing: showTranslate
                      ? IconButton(
                          icon: const Icon(Icons.translate),
                          onPressed: () => _translateEntry(i),
                        )
                      : null,
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(offset: const Offset(0,-2), blurRadius: 4, color: Colors.black.withOpacity(0.1)),
            ]),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    listening ? Icons.mic_off : Icons.mic,
                    color: listening ? Colors.red : primaryColor,
                  ),
                  onPressed: listening ? _stopListening : _startListening,
                ),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type your reply…',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: _handleDoctorText,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: primaryColor,
                  onPressed: () => _handleDoctorText(_inputCtrl.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}