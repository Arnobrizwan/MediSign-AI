import 'package:flutter/material.dart';
import '../dashboard/dashboard_page.dart';

class ConversationModePage extends StatefulWidget {
  const ConversationModePage({super.key});

  @override
  State<ConversationModePage> createState() => _ConversationModePageState();
}

class _ConversationModePageState extends State<ConversationModePage> {
  bool detectSignLanguage = true;
  bool brailleMode = false;
  List<String> transcriptLog = [
    '[10:35 AM] Patient (Sign): My head hurts.',
    '[10:36 AM] Doctor (Speech): Okay, can you describe the pain?',
  ];
  TextEditingController patientInputController = TextEditingController();

  void endAndSaveSession() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Session Saved'),
        content: const Text('Conversation saved to Medical Transcript History.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void addToTranscript(String speaker, String message) {
    setState(() {
      String timestamp = TimeOfDay.now().format(context);
      transcriptLog.add('[$timestamp] $speaker: $message');
    });
    patientInputController.clear();
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Conversation Mode',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: endAndSaveSession,
            child: const Text('End & Save', style: TextStyle(color: Color(0xFFF45B69))),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Auto-Switch Toggle (Patient Input)
          SwitchListTile(
            title: const Text('Detect Sign Language (Camera Active)'),
            value: detectSignLanguage,
            onChanged: (val) => setState(() => detectSignLanguage = val),
          ),

          // Patient Input/Output Area
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: ListView.builder(
                itemCount: transcriptLog.length,
                itemBuilder: (context, index) {
                  String entry = transcriptLog[index];
                  bool isDoctor = entry.contains('Doctor');
                  return ListTile(
                    leading: isDoctor
                        ? const Icon(Icons.person, color: Colors.blue)
                        : const Icon(Icons.person, color: Color(0xFFF45B69)),
                    title: Text(entry),
                    trailing: brailleMode
                        ? const Icon(Icons.blur_on, color: Colors.black)
                        : null,
                  );
                },
              ),
            ),
          ),

          // Quick Medical Phrase Suggestions
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                _quickPhraseButton('Pain Level?'),
                _quickPhraseButton('Yes'),
                _quickPhraseButton('No'),
                _quickPhraseButton('I need water'),
                _quickPhraseButton('Explain again'),
                _quickPhraseButton('Medication taken?'),
              ],
            ),
          ),

          // Patient Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: patientInputController,
                    decoration: InputDecoration(
                      hintText: detectSignLanguage ? 'Camera detecting signs...' : 'Type your message...',
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
                    if (patientInputController.text.isNotEmpty) {
                      addToTranscript('Patient', patientInputController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),

          // Doctor Input & Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      addToTranscript('Doctor', 'Okay, I understand.');
                    },
                    icon: const Icon(Icons.mic),
                    label: const Text('Start Speech-to-Text'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Playing doctor\'s message...')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickPhraseButton(String phrase) {
    return ActionChip(
      label: Text(phrase),
      onPressed: () {
        addToTranscript('Patient', phrase);
      },
      backgroundColor: Colors.grey.shade200,
    );
  }
}