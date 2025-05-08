import 'package:flutter/material.dart';

class SignTranslatePage extends StatefulWidget {
  const SignTranslatePage({super.key});

  @override
  State<SignTranslatePage> createState() => _SignTranslatePageState();
}

class _SignTranslatePageState extends State<SignTranslatePage> {
  bool isDetecting = false;
  String inputMethod = 'Sign to Text/Speech';
  String outputFormat = 'Text-Only';
  String inputLanguage = 'BIM';
  String outputLanguage = 'English';
  bool autoDetect = true;
  List<String> translationBubbles = [];

  void toggleDetection() {
    setState(() {
      isDetecting = !isDetecting;
      if (isDetecting) {
        translationBubbles.add('Sign: Hello -> Text: Hello');
      }
    });
  }

  void clearConversation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('Are you sure you want to clear the transcript?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => translationBubbles.clear());
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void saveSession() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Communication Session'),
        content: const Text('Session Saved to Medical Transcript History.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
          'Sign Language Translator',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Camera View Area (placeholder box)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Camera View Area')),
            ),
            const SizedBox(height: 16),

            // Central Camera/Mic Button
            ElevatedButton.icon(
              onPressed: toggleDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              icon: Icon(isDetecting ? Icons.stop : Icons.videocam),
              label: Text(isDetecting ? 'Stop Detection' : 'Start Detection'),
            ),
            const SizedBox(height: 16),

            // Controls/Options Panel
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: inputMethod,
                  decoration: _dropdownDecoration('Input Method'),
                  items: const [
                    DropdownMenuItem(value: 'Sign to Text/Speech', child: Text('Sign to Text/Speech')),
                    DropdownMenuItem(value: 'Text/Speech to Sign', child: Text('Text/Speech to Sign')),
                  ],
                  onChanged: (value) => setState(() => inputMethod = value!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: outputFormat,
                  decoration: _dropdownDecoration('Output Format'),
                  items: const [
                    DropdownMenuItem(value: 'Text-Only', child: Text('Text-Only')),
                    DropdownMenuItem(value: 'Text-to-Speech', child: Text('Text-to-Speech')),
                    DropdownMenuItem(value: 'Braille Format', child: Text('Braille Format')),
                  ],
                  onChanged: (value) => setState(() => outputFormat = value!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: inputLanguage,
                  decoration: _dropdownDecoration('Input Sign Language'),
                  items: const [
                    DropdownMenuItem(value: 'BIM', child: Text('Malaysian Sign Language (BIM)')),
                    DropdownMenuItem(value: 'BISINDO', child: Text('Indonesian Sign Language (BISINDO)')),
                  ],
                  onChanged: (value) => setState(() => inputLanguage = value!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: outputLanguage,
                  decoration: _dropdownDecoration('Output Language'),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Malay', child: Text('Malay')),
                  ],
                  onChanged: (value) => setState(() => outputLanguage = value!),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Auto-Detect Language'),
                  value: autoDetect,
                  onChanged: (val) => setState(() => autoDetect = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Real-time Translation Bubbles
            Expanded(
              child: ListView.builder(
                itemCount: translationBubbles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(translationBubbles[index]),
                    trailing: outputFormat == 'Text-to-Speech'
                        ? const Icon(Icons.volume_up)
                        : null,
                  );
                },
              ),
            ),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: clearConversation,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Clear Conversation'),
                ),
                ElevatedButton(
                  onPressed: saveSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Save Session'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }
}