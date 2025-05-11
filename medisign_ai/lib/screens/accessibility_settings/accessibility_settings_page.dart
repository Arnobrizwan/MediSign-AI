import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../providers/theme_provider.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = const Color(0xFFF45B69);

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
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: Colors.black),
              onPressed: _saveSettings,
            )
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Theme', primaryColor),
            DropdownButtonFormField<String>(
              value: accessibilityProvider.theme,
              decoration: _dropdownDecoration('Select Theme'),
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
                DropdownMenuItem(value: 'high_contrast', child: Text('High Contrast')),
              ],
              onChanged: (val) {
                if (val != null) {
                  accessibilityProvider.setTheme(val);
                  themeProvider.setTheme(val);
                }
              },
            ),

            const SizedBox(height: 24),
            _sectionHeader('Font Size', primaryColor),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Font Size'),
                    Text('${accessibilityProvider.fontSize.toStringAsFixed(0)}px'),
                  ],
                ),
                Slider(
                  value: accessibilityProvider.fontSize,
                  onChanged: (val) => accessibilityProvider.setFontSize(val),
                  min: 12,
                  max: 24,
                  divisions: 12,
                  label: '${accessibilityProvider.fontSize.toStringAsFixed(0)}px',
                  activeColor: primaryColor,
                ),
              ],
            ),

            const SizedBox(height: 24),
            _sectionHeader('Braille Mode', primaryColor),
            SwitchListTile(
              title: const Text('Enable Braille Mode'),
              subtitle: const Text('Enables Braille output for screen readers'),
              value: accessibilityProvider.isBrailleOn,
              onChanged: accessibilityProvider.setBrailleMode,
              activeColor: primaryColor,
            ),

            const SizedBox(height: 24),
            _sectionHeader('Voice Settings', primaryColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Voice Speed'),
                      Text('${accessibilityProvider.voiceSpeed.toStringAsFixed(1)}x'),
                    ],
                  ),
                  Slider(
                    value: accessibilityProvider.voiceSpeed,
                    onChanged: accessibilityProvider.setVoiceSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: '${accessibilityProvider.voiceSpeed.toStringAsFixed(1)}x',
                    activeColor: primaryColor,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Voice Pitch'),
                      Text('${accessibilityProvider.voicePitch.toStringAsFixed(1)}x'),
                    ],
                  ),
                  Slider(
                    value: accessibilityProvider.voicePitch,
                    onChanged: accessibilityProvider.setVoicePitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: '${accessibilityProvider.voicePitch.toStringAsFixed(1)}x',
                    activeColor: primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveSettings,
                style: _sectionButtonStyle(primaryColor),
                icon: isSaving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
                label: Text(
                  isSaving ? 'Saving...' : 'Save Preferences',
                ),
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Accessibility Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accessibilityProvider.highContrast 
                            ? Colors.black 
                            : Colors.grey.shade400,
                        width: accessibilityProvider.highContrast ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      'This is how your text will appear with current settings.',
                      style: accessibilityProvider.getTextStyle(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  ButtonStyle _sectionButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size.fromHeight(48),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF45B69), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }

  Future<void> _saveSettings() async {
    setState(() {
      isSaving = true;
    });

    try {
      final accessibilityProvider = Provider.of<AccessibilityProvider>(context, listen: false);
      await accessibilityProvider.saveSettings();
      
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
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }
}