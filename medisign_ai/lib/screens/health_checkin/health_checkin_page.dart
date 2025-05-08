import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class HealthCheckinPage extends StatefulWidget {
  const HealthCheckinPage({super.key});

  @override
  State<HealthCheckinPage> createState() => _HealthCheckinPageState();
}

class _HealthCheckinPageState extends State<HealthCheckinPage> {
  final TextEditingController inputController = TextEditingController();
  List<Map<String, String>> chatLog = [
    {'sender': 'AI', 'message': 'Good morning! How are you feeling today? (e.g., Pain, Mood, Symptoms)'},
  ];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendMessage(String message) async {
    setState(() {
      chatLog.add({'sender': 'User', 'message': message});
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user.');
      }

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getGeminiWelcomeMessage');
      final response = await callable.call(<String, dynamic>{
        'email': user.email,
        'message': message,
      });

      final String aiReply = response.data['message'] ?? 'Sorry, I could not understand.';

      setState(() {
        chatLog.add({'sender': 'AI', 'message': aiReply});
      });
    } catch (error) {
      print('❌ Error calling Cloud Function: $error');
      setState(() {
        chatLog.add({'sender': 'AI', 'message': 'Oops! Something went wrong. Please try again later.'});
      });
    }

    inputController.clear();
  }

  void endChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary generated for caregivers/doctors.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Health Check-In',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: endChat,
            child: const Text('End Chat', style: TextStyle(color: Color(0xFFF45B69))),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatLog.length,
              itemBuilder: (context, index) {
                var entry = chatLog[index];
                bool isUser = entry['sender'] == 'User';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? primaryColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry['message'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick Reply Buttons
          Wrap(
            spacing: 8,
            children: [
              _quickReplyButton('Yes'),
              _quickReplyButton('No'),
              _quickReplyButton('A little'),
              _quickReplyButton('A lot'),
              _quickReplyButton('Book appointment with doctor'),
              _quickReplyButton('Show latest test results'),
              _quickReplyButton('Request medication refill'),
              _quickReplyButton('Get directions to cardiology'),
            ],
          ),
          const SizedBox(height: 8),

          // Input Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mic, color: Color(0xFFF45B69)),
                  onPressed: () {
                    sendMessage('Voice input: I have a headache.');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFFF45B69)),
                  onPressed: () {
                    sendMessage('Sign input: I have a headache.');
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: inputController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (inputController.text.isNotEmpty) {
                      sendMessage(inputController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickReplyButton(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        sendMessage(label);
      },
      backgroundColor: Colors.grey.shade200,
    );
  }
}