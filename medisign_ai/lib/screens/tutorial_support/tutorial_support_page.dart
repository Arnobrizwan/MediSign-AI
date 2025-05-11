// lib/screens/tutorial_support/tutorial_support_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TutorialSupportPage extends StatelessWidget {
  const TutorialSupportPage({Key? key}) : super(key: key);

  static const Color primaryColor = Color(0xFFF45B69);

  // Data for each section
  final List<Map<String,String>> _onboardingSteps = const [
    {
      'title': 'Welcome',
      'body': 'Learn how to use MediSign AI to communicate seamlessly with your care team—via speech, text, or sign language.',
    },
    {
      'title': 'Edit Profile',
      'body': 'Tap on “Edit Profile” in the dashboard to set your display name, upload a photo, and choose your preferred language.',
    },
    {
      'title': 'Appointment Center',
      'body': 'Open Appointment Center to view, book, or manage your upcoming visits—all in an accessible, easy-to-read list.',
    },
  ];

  final List<String> _voiceDemos = const [
    'Sign Language Recognition: Position your hands within the camera frame and use clear gestures.',
    'Accessible Appointment Center: Navigate appointments with voice prompts and large text.',
    'Medical Records Hub: Use voice commands to search and filter your records.',
  ];

  final Map<String,String> _faq = const {
    'General':
      'This app helps patients communicate using sign, Braille, and text.',
    'Sign Language':
      'Point the camera clearly at your hands and ensure good lighting.',
    'Braille':
      'Enable Braille Mode in settings; use compatible hardware if needed.',
    'Troubleshooting':
      'If something’s not working, try restarting the app or checking permissions.',
  };

  Future<void> _openBluetoothSettings() async {
    const iosScheme = 'app-settings:';
    if (await canLaunchUrl(Uri.parse(iosScheme))) {
      await launchUrl(Uri.parse(iosScheme));
    } else {
      // Android fallback
      await launchUrl(
        Uri.parse('bluetooth:'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void _openFeedbackForm(BuildContext context) {
    String feedbackType = 'Bug';
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: feedbackType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'Bug', child: Text('Bug')),
                DropdownMenuItem(value: 'Suggestion', child: Text('Suggestion')),
                DropdownMenuItem(value: 'Compliment', child: Text('Compliment')),
              ],
              onChanged: (v) => feedbackType = v ?? 'Bug',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              await FirebaseFirestore.instance.collection('feedback').add({
                'userUid': user?.uid,
                'type': feedbackType,
                'description': descCtrl.text,
                'timestamp': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback submitted')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial & Support'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          // Step-by-Step Onboarding
          _buildCard(
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text('Step-by-Step Onboarding',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _onboardingSteps.map((step) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(step['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(step['body']!),
                );
              }).toList(),
            ),
          ),

          // Voice-Over Demonstrations
          _buildCard(
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text('Voice-Over Demonstrations',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _voiceDemos.map((guideline) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.mic, size: 20, color: primaryColor),
                  title: Text(guideline),
                );
              }).toList(),
            ),
          ),

          // FAQ
         _buildCard(
  ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    title: const Text(
      'FAQ',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    ),
    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    children: _faq.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.value,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }).toList(),
  ),
),
          // Braille Display Pairing
          _buildCard(
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text('Braille Display Pairing',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.bluetooth, color: primaryColor),
                  title: Text('Ensure your Braille device is powered on.'),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.settings, color: primaryColor),
                  title: Text('Open your phone’s Bluetooth settings.'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link, color: primaryColor),
                  title: const Text('Select your Braille device to pair.'),
                  trailing: TextButton(
                    onPressed: _openBluetoothSettings,
                    child: const Text('Open Settings'),
                  ),
                ),
              ],
            ),
          ),

          // On-Screen Braille Guide
          _buildCard(
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text('Using Braille Mode On-Screen',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: const [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.keyboard, color: primaryColor),
                  title: Text('Tap the virtual 6-dot grid to form characters.'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.accessibility_new, color: primaryColor),
                  title: Text('Use the “Send” button to commit text.'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.backspace, color: primaryColor),
                  title: Text('Swipe left to delete a character.'),
                ),
              ],
            ),
          ),

          // Troubleshooting
          _buildCard(
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text('Troubleshooting Guide',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: const [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.camera_alt, color: primaryColor),
                  title: Text('Camera not working → Check permissions.'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.mic_off, color: primaryColor),
                  title: Text('Mic access denied → Re-enable in system settings.'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.translate, color: primaryColor),
                  title: Text('Translation errors → Verify target language.'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.refresh, color: primaryColor),
                  title: Text('App not responding → Restart the app.'),
                ),
              ],
            ),
          ),

          // Contact & Feedback
          _buildCard(
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text('Contact & Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.support_agent, color: primaryColor),
                  title: Text('Email: support@hospital.com'),
                  subtitle: Text('Phone: +60-123-456-789'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _openFeedbackForm(context),
                      icon: const Icon(Icons.feedback),
                      label: const Text('Send Feedback'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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