import 'dart:async';
import 'dart:html' as html; // for Web Speech API fallback
import 'dart:js' as js; // for Web Speech API
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

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
  final ScrollController _scrollController = ScrollController();
  
  // Updated color palette
  final Color _primaryColor = const Color(0xFFF45B69);
  
  // Use hardcoded data for testing (set to false to use real Firestore data)
  final bool _useHardcodedData = true;
  
  // transcript holds both patient & doctor turns
  List<Map<String, dynamic>> _transcript = [
    {
      'speaker': null, // will be set in initState
      'message': '',
      'timestamp': DateTime.now(),
      'example': true,
    },
  ];
  
  // Example past conversations for the sidebar
  final List<Map<String, dynamic>> _pastConversations = [
    {
      'patientName': 'Sarah Johnson',
      'lastMessage': 'Thanks for your help, doctor.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      'unread': false,
    },
    {
      'patientName': 'Michael Brown',
      'lastMessage': 'I\'ll follow your advice regarding the medication.',
      'timestamp': DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      'unread': true,
    },
    {
      'patientName': 'Emily Davis',
      'lastMessage': 'When should I schedule my next appointment?',
      'timestamp': DateTime.now().subtract(const Duration(days: 3, hours: 1)),
      'unread': false,
    },
    {
      'patientName': 'Robert Wilson',
      'lastMessage': 'The prescription is working well.',
      'timestamp': DateTime.now().subtract(const Duration(days: 4, hours: 2)),
      'unread': false,
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
    
    // If using hardcoded data, load example conversation
    if (_useHardcodedData) {
      _loadExampleConversation();
    }
    
    _startConversation().then((_) {
      if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
        _removeExampleData();
        _addMessage('Patient', widget.initialPrompt!, example: false);
      }
    });
    
    _initSpeechRecognition();
  }
  
  void _loadExampleConversation() {
    final now = DateTime.now();
    
    _transcript = [
      {
        'speaker': widget.doctorName,
        'message': 'Hello, how can I assist you today?',
        'timestamp': now.subtract(const Duration(minutes: 10)),
        'example': false,
      },
      {
        'speaker': 'Patient',
        'message': 'I\'ve been experiencing headaches almost daily for the past week.',
        'timestamp': now.subtract(const Duration(minutes: 9)),
        'example': false,
        'translated': false,
        'translationFailed': false,
      },
      {
        'speaker': widget.doctorName,
        'message': 'I\'m sorry to hear that. Can you describe the nature of these headaches? For example, where is the pain located and how severe is it?',
        'timestamp': now.subtract(const Duration(minutes: 8)),
        'example': false,
      },
      {
        'speaker': 'Patient',
        'message': 'It\'s mostly on the right side of my head, and it feels like a throbbing pain. It\'s not unbearable, but it\'s definitely distracting.',
        'timestamp': now.subtract(const Duration(minutes: 7)),
        'example': false,
        'translated': false,
        'translationFailed': false,
      },
      {
        'speaker': widget.doctorName,
        'message': 'Have you noticed any triggers or patterns? For instance, do they occur at a particular time of day or after certain activities?',
        'timestamp': now.subtract(const Duration(minutes: 6)),
        'example': false,
      },
      {
        'speaker': 'Patient',
        'message': 'Now that you mention it, they often start in the afternoon and seem worse when I\'ve been looking at screens for a long time.',
        'timestamp': now.subtract(const Duration(minutes: 5)),
        'example': false,
        'translated': false,
        'translationFailed': false,
      },
      {
        'speaker': widget.doctorName,
        'message': 'That\'s helpful information. It sounds like you might be experiencing tension headaches, possibly related to eye strain. Have you made any changes to your routine recently? Or are you under more stress than usual?',
        'timestamp': now.subtract(const Duration(minutes: 4)),
        'example': false,
      },
    ];
    
    _hasInteracted = true;
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
  
  Future<void> _addMessage(String speaker, String message, {required bool example}) async {
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
    
    // Scroll to bottom after adding message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    if (!example && !_useHardcodedData) {
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
  
  Future<void> _translateEntry(int index, {bool isAutoTranslation = false}) async {
    if (index < 0 || index >= _transcript.length) return;
    if (_translatingIndices.contains(index)) return;
    
    final entry = _transcript[index];
    final orig = entry['message'] as String;
    final speaker = entry['speaker'] as String;
    if (speaker.contains('(EN)')) return;
    
    _translatingIndices.add(index);
    
    try {
      if (!isAutoTranslation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Translating…'), duration: Duration(seconds: 2)),
        );
      }
      
      // Simulate translation for hardcoded data
      if (_useHardcodedData) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        // For demo purposes, just append "(Translated)" to the message
        final translated = "$orig (Translated)";
        
        await _addMessage('$speaker (EN)', translated, example: false);
        setState(() => _transcript[index]['translated'] = true);
        
        if (!isAutoTranslation) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Translation complete')));
        }
      } else {
        // Real translation logic
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
    if (!_useHardcodedData) {
      await _convoRef.update({
        'endedAt': FieldValue.serverTimestamp(),
        'status': 'closed_by_doctor',
      });
    }
    
    if (mounted) Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conversation with Patient',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 0,
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
          TextButton.icon(
            onPressed: _endSession,
            icon: const Icon(Icons.call_end, color: Colors.white),
            label: const Text('End Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Row(
        children: [
          // Past conversations sidebar (only on wide screens)
          if (isWideScreen)
            Container(
              width: 300,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Conversations',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {},
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _pastConversations.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final conv = _pastConversations[index];
                        final date = conv['timestamp'] as DateTime;
                        final timeStr = DateFormat('MMM d, h:mm a').format(date);
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _primaryColor.withOpacity(0.1),
                            child: Text(
                              conv['patientName'].toString().substring(0, 1),
                              style: TextStyle(color: _primaryColor),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conv['patientName'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (conv['unread'] == true)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conv['lastMessage'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          onTap: () {
                            // Would load this conversation
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Main conversation area
          Expanded(
            child: Column(
              children: [
                // Transcript
                Expanded(
                  child: _transcript.isEmpty
                      ? Center(
                          child: Text(
                            'Start a new conversation',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _transcript.length,
                          itemBuilder: (ctx, i) {
                            final e = _transcript[i];
                            final speaker = e['speaker'] as String?;
                            final msg = e['message'] as String;
                            final t = e['timestamp'] as DateTime;
                            final example = e['example'] as bool;
                            final translated = e['translated'] as bool? ?? false;
                            final failed = e['translationFailed'] as bool? ?? false;
                            final isDoctor = speaker == widget.doctorName;
                            final timeStr = DateFormat('h:mm a').format(t);
                            final showTranslate = !example && speaker == 'Patient' && !translated;
                            
                            return Align(
                              alignment: isDoctor ? Alignment.centerRight : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Card(
                                  color: isDoctor ? _primaryColor.withOpacity(0.1) : Colors.white,
                                  margin: EdgeInsets.only(
                                    bottom: 12,
                                    left: isDoctor ? 50 : 0,
                                    right: isDoctor ? 0 : 50,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: isDoctor ? _primaryColor : Colors.blue,
                                              child: Icon(
                                                isDoctor ? Icons.medical_services : Icons.person,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              speaker!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              timeStr,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          msg,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        if (showTranslate)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              if (_translatingIndices.contains(i))
                                                const Padding(
                                                  padding: EdgeInsets.only(right: 8),
                                                  child: SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                              TextButton.icon(
                                                icon: const Icon(Icons.translate, size: 16),
                                                label: const Text('Translate'),
                                                style: TextButton.styleFrom(
                                                  visualDensity: VisualDensity.compact,
                                                  padding: EdgeInsets.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                onPressed: () => _translateEntry(i),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Input area
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          listening ? Icons.mic_off : Icons.mic,
                          color: listening ? Colors.red : _primaryColor,
                        ),
                        onPressed: listening ? _stopListening : _startListening,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          decoration: InputDecoration(
                            hintText: 'Type your reply…',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: _handleDoctorText,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: _primaryColor,
                        onPressed: () => _handleDoctorText(_inputCtrl.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}