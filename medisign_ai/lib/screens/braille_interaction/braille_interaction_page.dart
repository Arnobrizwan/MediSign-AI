import 'package:flutter/material.dart';

class BrailleInteractionOverlay extends StatefulWidget {
  final Function(String translatedText) onSend;

  const BrailleInteractionOverlay({super.key, required this.onSend});

  @override
  State<BrailleInteractionOverlay> createState() => _BrailleInteractionOverlayState();
}

class _BrailleInteractionOverlayState extends State<BrailleInteractionOverlay> {
  List<bool> dots = List.generate(6, (_) => false); // 6-dot Braille example
  String brailleSequence = '';
  String translatedText = '';

  void toggleDot(int index) {
    setState(() {
      dots[index] = !dots[index];
    });
  }

  void translateBraille() {
    // Simple placeholder translation logic
    setState(() {
      brailleSequence = dots.map((d) => d ? '●' : '○').join();
      translatedText = 'SampleText'; // Replace with real Braille-to-text mapping
    });
  }

  void sendInput() {
    widget.onSend(translatedText);
    setState(() {
      dots = List.generate(6, (_) => false);
      brailleSequence = '';
      translatedText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: primaryColor, width: 2)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Braille Input Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(6, (index) {
                return GestureDetector(
                  onTap: () {
                    toggleDot(index);
                    translateBraille();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: dots[index] ? primaryColor : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              'Braille Pattern: $brailleSequence',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Translated Text: $translatedText',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: sendInput,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Send', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        dots = List.generate(6, (_) => false);
                        brailleSequence = '';
                        translatedText = '';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}