// lib/screens/health_checkin/health_checkin_page.dart

import 'package:flutter/material.dart';
import '../../providers/gemini_chat_client.dart';  // <-- updated path

class HealthCheckinPage extends StatefulWidget {
  const HealthCheckinPage({super.key});
  @override
  _HealthCheckinPageState createState() => _HealthCheckinPageState();
}

class _HealthCheckinPageState extends State<HealthCheckinPage> {
  final GeminiChatClient _chat = GeminiChatClient();
  final TextEditingController _ctr = TextEditingController();

  final List<Map<String, String>> _log = [
    {
      'sender': 'AI',
      'message':
          '👋 Hi there! Describe any health concern—symptoms, conditions, or questions—and I’ll guide you.'
    }
  ];

  Future<void> _send(String txt) async {
    // 1) Append the user’s message
    setState(() => _log.add({'sender': 'User', 'message': txt}));

    // 2) Call the AI, catching & logging any errors
    try {
      final reply = await _chat.send(txt);
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

  @override
  Widget build(BuildContext ctx) {
    const primary = Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Check-In'),
        backgroundColor: primary,
      ),
      body: Column(
        children: [
          // Chat history
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _log.length,
              itemBuilder: (_, i) {
                final entry = _log[i];
                final isUser = entry['sender'] == 'User';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry['message']!,
                      style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87),
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
                  icon: const Icon(Icons.camera_alt, color: primary),
                  onPressed: () => _send('Sign input: <transcribe sign here>'),
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
    );
  }
}