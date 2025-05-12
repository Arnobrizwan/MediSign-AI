// lib/screens/accessibility_settings/accessibility_settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/accessibility_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/emotion_mood_detection_manager.dart';
// ← import the overlay widget, not a nonexistent page
import '../braille_interaction/braille_interaction_page.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettingsPage> createState() =>
      _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState
    extends State<AccessibilitySettingsPage> {
  bool isSaving = false;
  final double _cardElevation = 2.0;
  final BorderRadius _cardRadius = BorderRadius.circular(12);

  @override
  Widget build(BuildContext context) {
    final accessibility = context.watch<AccessibilityProvider>();
    final theme = context.watch<ThemeProvider>();
    const primary = Color(0xFFF45B69);
    final headerStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: primary,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Accessibility Preferences',
          style: TextStyle(color: primary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: Colors.black87),
              onPressed: _saveSettings,
            ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ── Theme Section ────────────────────────────────────────────
            Card(
              elevation: _cardElevation,
              shape:
                  RoundedRectangleBorder(borderRadius: _cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.palette, color: primary),
                      const SizedBox(width: 8),
                      Text('Theme', style: headerStyle),
                    ]),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: accessibility.theme,
                      decoration:
                          _dropdownDecoration('Select theme'),
                      items: const [
                        DropdownMenuItem(
                            value: 'light', child: Text('Light')),
                        DropdownMenuItem(
                            value: 'dark', child: Text('Dark')),
                        DropdownMenuItem(
                            value: 'high_contrast',
                            child: Text('High Contrast')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          accessibility.setTheme(val);
                          theme.setTheme(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Font Size Section ────────────────────────────────────────
            Card(
              elevation: _cardElevation,
              shape:
                  RoundedRectangleBorder(borderRadius: _cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.format_size, color: primary),
                      const SizedBox(width: 8),
                      Text('Font Size', style: headerStyle),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Size: ${accessibility.fontSize.toStringAsFixed(0)}px',
                        ),
                        Slider(
                          value: accessibility.fontSize,
                          min: 12,
                          max: 32,
                          divisions: 20,
                          label:
                              '${accessibility.fontSize.toStringAsFixed(0)}px',
                          activeColor: primary,
                          onChanged: accessibility.setFontSize,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Braille Mode Section ────────────────────────────────────
            Card(
              elevation: _cardElevation,
              shape:
                  RoundedRectangleBorder(borderRadius: _cardRadius),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                title: Row(
                  children: [
                    Icon(Icons.accessible, color: primary),
                    const SizedBox(width: 8),
                    Text('Braille Mode', style: headerStyle),
                  ],
                ),
                subtitle: const Text(
                    'Enable on-screen Braille input/output'),
                value: accessibility.isBrailleOn,
                activeColor: primary,
                onChanged: (on) {
                  accessibility.setBrailleMode(on);
                  _saveSettings();
                },
              ),
            ),

            // ── Open Braille Keyboard ───────────────────────────────────
            if (accessibility.isBrailleOn) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.keyboard),
                label: const Text('Open Braille Keyboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: BrailleInteractionOverlay(
                        onSend: (char) {
                          // handle the character however you like:
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Braille input: $char')),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 16),

            // ── Voice Settings Section ─────────────────────────────────
            Card(
              elevation: _cardElevation,
              shape:
                  RoundedRectangleBorder(borderRadius: _cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.hearing, color: primary),
                      const SizedBox(width: 8),
                      Text('Voice Settings', style: headerStyle),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                        'Speed: ${accessibility.voiceSpeed.toStringAsFixed(1)}x'),
                    Slider(
                      value: accessibility.voiceSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label:
                          '${accessibility.voiceSpeed.toStringAsFixed(1)}x',
                      activeColor: primary,
                      onChanged: (v) {
                        accessibility.setVoiceSpeed(v);
                        _saveSettings();
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Pitch: ${accessibility.voicePitch.toStringAsFixed(1)}x'),
                    Slider(
                      value: accessibility.voicePitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label:
                          '${accessibility.voicePitch.toStringAsFixed(1)}x',
                      activeColor: primary,
                      onChanged: (v) {
                        accessibility.setVoicePitch(v);
                        _saveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Emotional Support Section ───────────────────────────────
            Card(
              elevation: _cardElevation,
              shape:
                  RoundedRectangleBorder(borderRadius: _cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.psychology, color: primary),
                      const SizedBox(width: 8),
                      Text('Emotional Support', style: headerStyle),
                    ]),
                    const SizedBox(height: 12),
                    EmotionDetectionSettingsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFF45B69), width: 2),
        ),
      );

  Future<void> _saveSettings() async {
    setState(() => isSaving = true);
    try {
      await context.read<AccessibilityProvider>().saveSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
}