import 'package:flutter/material.dart';

class HealthCheckinPage extends StatefulWidget {
  const HealthCheckinPage({super.key});

  @override
  State<HealthCheckinPage> createState() => _HealthCheckinPageState();
}

class _HealthCheckinPageState extends State<HealthCheckinPage> {
  final TextEditingController inputController = TextEditingController();
  List<Map<String, String>> chatLog = [
    {'sender': 'AI', 'message': 'Good morning, John! How are you feeling today? (e.g., Pain, Mood, Symptoms)'},
  ];

  void sendMessage(String message) {
    setState(() {
      chatLog.add({'sender': 'User', 'message': message});

      // Simulated AI replies with enhanced integration
      String aiReply;
      if (message.toLowerCase().contains('book appointment')) {
        aiReply = 'Sure! I can help book an appointment with Dr. Lim. What date and time would you prefer?';
      } else if (message.toLowerCase().contains('latest blood test')) {
        aiReply = 'Fetching your latest blood test results... Found: Normal cholesterol, elevated glucose.';
      } else if (message.toLowerCase().contains('refill')) {
        aiReply = 'I\'ve placed a refill request for your heart medication. Your pharmacy will notify you.';
      } else if (message.toLowerCase().contains('cardiology')) {
        aiReply = 'To get to the Cardiology department, take Elevator B to the 3rd floor, then follow the blue signs.';
      } else {
        aiReply = 'I understand. On a scale of 1-5, how severe is it?';
      }

      chatLog.add({'sender': 'AI', 'message': aiReply});
    });
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
              _quickReplyButton('Book appointment with Dr. Lim'),
              _quickReplyButton('Show latest blood test results'),
              _quickReplyButton('Request medication refill'),
              _quickReplyButton('Get directions to Cardiology'),
            ],
          ),
          const SizedBox(height: 8),

          // Input Area with Text, Mic, and Sign
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
                      hintText: 'Type your response or command...',
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