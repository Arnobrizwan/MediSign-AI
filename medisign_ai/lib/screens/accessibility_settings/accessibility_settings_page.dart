import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  String selectedTheme = 'light';
  bool isBrailleOn = false;
  double voiceSpeed = 1.0;
  double voicePitch = 1.0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('preferences')
          .doc('settings')
          .get();

      final data = doc.data();
      if (data != null) {
        setState(() {
          selectedTheme = data['theme'] ?? 'light';
          isBrailleOn = data['brailleMode'] ?? false;
          voiceSpeed = (data['voiceSpeed'] ?? 1.0).toDouble();
          voicePitch = (data['voicePitch'] ?? 1.0).toDouble();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load preferences.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('preferences')
          .doc('settings')
          .set({
        'theme': selectedTheme,
        'brailleMode': isBrailleOn,
        'voiceSpeed': voiceSpeed,
        'voicePitch': voicePitch,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved successfully!')),
      );
    } catch (e) {
      print('❌ Error saving preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save preferences.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Accessibility Preferences',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black),
            onPressed: _savePreferences,
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Theme', primaryColor),
            DropdownButtonFormField<String>(
              value: selectedTheme,
              decoration: _dropdownDecoration('Select Theme'),
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
                DropdownMenuItem(value: 'high_contrast', child: Text('High Contrast')),
              ],
              onChanged: (val) => setState(() => selectedTheme = val!),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Braille Mode', primaryColor),
            SwitchListTile(
              title: const Text('Enable Braille Mode'),
              value: isBrailleOn,
              onChanged: (val) => setState(() => isBrailleOn = val),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Voice Settings', primaryColor),
            const Text('Voice Speed'),
            Slider(
              value: voiceSpeed,
              onChanged: (val) => setState(() => voiceSpeed = val),
              min: 0.5,
              max: 2.0,
              divisions: 3,
              label: voiceSpeed.toStringAsFixed(1),
            ),
            const Text('Voice Pitch'),
            Slider(
              value: voicePitch,
              onChanged: (val) => setState(() => voicePitch = val),
              min: 0.5,
              max: 2.0,
              divisions: 3,
              label: voicePitch.toStringAsFixed(1),
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _savePreferences,
              style: _sectionButtonStyle(primaryColor),
              icon: const Icon(Icons.save),
              label: const Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  ButtonStyle _sectionButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size.fromHeight(45),
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