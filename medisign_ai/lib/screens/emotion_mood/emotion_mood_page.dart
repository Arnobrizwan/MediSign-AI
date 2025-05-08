import 'package:flutter/material.dart';

class EmotionMoodOverlay extends StatelessWidget {
  final String detectedMood;
  final VoidCallback onShowCalming;
  final VoidCallback onConnectHelpline;
  final VoidCallback onAlertCaregiver;
  final VoidCallback onDismiss;

  const EmotionMoodOverlay({
    super.key,
    required this.detectedMood,
    required this.onShowCalming,
    required this.onConnectHelpline,
    required this.onAlertCaregiver,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mood_bad, color: primaryColor, size: 48),
            const SizedBox(height: 12),
            Text(
              'It seems like you might be feeling $detectedMood.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Would you like some help?',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onShowCalming,
              icon: const Icon(Icons.self_improvement),
              label: const Text('Yes, show calming suggestions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onConnectHelpline,
              icon: const Icon(Icons.phone),
              label: const Text('Connect to Helpline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onAlertCaregiver,
              icon: const Icon(Icons.warning),
              label: const Text('Alert Caregiver/Staff'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onDismiss,
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}