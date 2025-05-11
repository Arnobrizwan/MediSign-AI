import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AccessibilityProvider extends ChangeNotifier {
  String _theme = 'light';
  bool _isBrailleOn = false;
  double _voiceSpeed = 1.0;
  double _voicePitch = 1.0;
  double _fontSize = 16.0;
  bool _highContrast = false;

  String get theme => _theme;
  bool get isBrailleOn => _isBrailleOn;
  double get voiceSpeed => _voiceSpeed;
  double get voicePitch => _voicePitch;
  double get fontSize => _fontSize;
  bool get highContrast => _highContrast;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void setTheme(String theme) {
    _theme = theme;
    _highContrast = theme == 'high_contrast';
    notifyListeners();
  }

  void setBrailleMode(bool enabled) {
    _isBrailleOn = enabled;
    notifyListeners();
  }

  void setVoiceSpeed(double speed) {
    _voiceSpeed = speed;
    notifyListeners();
  }

  void setVoicePitch(double pitch) {
    _voicePitch = pitch;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  // Load settings from Firebase
  Future<void> loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _theme = data['theme'] ?? 'light';
        _isBrailleOn = data['brailleMode'] ?? false;
        _voiceSpeed = (data['voiceSpeed'] ?? 1.0).toDouble();
        _voicePitch = (data['voicePitch'] ?? 1.0).toDouble();
        _fontSize = (data['fontSize'] ?? 16.0).toDouble();
        _highContrast = _theme == 'high_contrast';
        notifyListeners();
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  // Save settings to Firebase
  Future<void> saveSettings() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .set({
        'theme': _theme,
        'brailleMode': _isBrailleOn,
        'voiceSpeed': _voiceSpeed,
        'voicePitch': _voicePitch,
        'fontSize': _fontSize,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving settings: $e');
      rethrow;
    }
  }

  // Helper method to get text style with current font size
  TextStyle getTextStyle({
    double sizeMultiplier = 1.0,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontSize: _fontSize * sizeMultiplier,
      fontWeight: fontWeight ?? (_highContrast ? FontWeight.bold : FontWeight.normal),
      color: color,
    );
  }
}