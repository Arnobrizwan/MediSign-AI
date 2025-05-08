import 'package:flutter/material.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  bool enableBraille = false;
  bool brailleCompatibility = false;
  bool trackProficiency = false;
  bool offlineMode = false;
  bool allowEmergencyLocation = false;
  String preferredOutput = 'Text';
  String selectedDialect = 'Kuala Lumpur dialect';

  // New settings
  bool appointmentReminders = true;
  String preferredPharmacy = 'Pharmacy A';
  bool shareLabResults = true;
  bool shareVisitSummaries = false;
  bool notifLabResults = true;
  bool notifAppointments = true;
  bool notifPrescriptions = true;

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
          'Settings',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Language Management', primaryColor),
            ElevatedButton(
              onPressed: () {},
              style: _sectionButtonStyle(primaryColor),
              child: const Text('Add/Remove Sign Languages'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedDialect,
              decoration: _dropdownDecoration('Dialect Recognition'),
              items: const [
                DropdownMenuItem(value: 'Kuala Lumpur dialect', child: Text('Kuala Lumpur dialect')),
                DropdownMenuItem(value: 'Penang dialect', child: Text('Penang dialect')),
              ],
              onChanged: (val) => setState(() => selectedDialect = val!),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Communication Preferences', primaryColor),
            ElevatedButton(
              onPressed: () {},
              style: _sectionButtonStyle(primaryColor),
              child: const Text('Prioritize Communication Methods'),
            ),
            Column(
              children: [
                RadioListTile(
                  title: const Text('Text'),
                  value: 'Text',
                  groupValue: preferredOutput,
                  onChanged: (val) => setState(() => preferredOutput = val!),
                ),
                RadioListTile(
                  title: const Text('Speech (with voice, speed, pitch)'),
                  value: 'Speech',
                  groupValue: preferredOutput,
                  onChanged: (val) => setState(() => preferredOutput = val!),
                ),
                RadioListTile(
                  title: const Text('Braille'),
                  value: 'Braille',
                  groupValue: preferredOutput,
                  onChanged: (val) => setState(() => preferredOutput = val!),
                ),
              ],
            ),
            if (preferredOutput == 'Speech')
              Column(
                children: [
                  const Text('Voice Speed'),
                  Slider(value: 1.0, onChanged: (val) {}, min: 0.5, max: 2.0, divisions: 3, label: 'Normal'),
                  const Text('Voice Pitch'),
                  Slider(value: 1.0, onChanged: (val) {}, min: 0.5, max: 2.0, divisions: 3, label: 'Normal'),
                ],
              ),

            const SizedBox(height: 24),
            _sectionHeader('Appointment Preferences', primaryColor),
            SwitchListTile(
              title: const Text('Enable Appointment Reminders'),
              value: appointmentReminders,
              onChanged: (val) => setState(() => appointmentReminders = val),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Prescription Preferences', primaryColor),
            DropdownButtonFormField<String>(
              value: preferredPharmacy,
              decoration: _dropdownDecoration('Preferred Pharmacy'),
              items: const [
                DropdownMenuItem(value: 'Pharmacy A', child: Text('Pharmacy A')),
                DropdownMenuItem(value: 'Pharmacy B', child: Text('Pharmacy B')),
                DropdownMenuItem(value: 'Pharmacy C', child: Text('Pharmacy C')),
              ],
              onChanged: (val) => setState(() => preferredPharmacy = val!),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Medical Record Sharing Consent', primaryColor),
            SwitchListTile(
              title: const Text('Share Lab Results with Caregivers'),
              value: shareLabResults,
              onChanged: (val) => setState(() => shareLabResults = val),
            ),
            SwitchListTile(
              title: const Text('Share Visit Summaries with Caregivers'),
              value: shareVisitSummaries,
              onChanged: (val) => setState(() => shareVisitSummaries = val),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Notification Settings', primaryColor),
            SwitchListTile(
              title: const Text('New Lab Results'),
              value: notifLabResults,
              onChanged: (val) => setState(() => notifLabResults = val),
            ),
            SwitchListTile(
              title: const Text('Upcoming Appointments'),
              value: notifAppointments,
              onChanged: (val) => setState(() => notifAppointments = val),
            ),
            SwitchListTile(
              title: const Text('Prescription Refills Ready'),
              value: notifPrescriptions,
              onChanged: (val) => setState(() => notifPrescriptions = val),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Accessibility Features', primaryColor),
            ElevatedButton(
              onPressed: () {},
              style: _sectionButtonStyle(primaryColor),
              child: const Text('Theme: Light / Dark / High Contrast'),
            ),
            SwitchListTile(
              title: const Text('Enable Braille Mode'),
              value: enableBraille,
              onChanged: (val) => setState(() => enableBraille = val),
            ),
            SwitchListTile(
              title: const Text('Braille Display Compatibility'),
              value: brailleCompatibility,
              onChanged: (val) => setState(() => brailleCompatibility = val),
            ),
            SwitchListTile(
              title: const Text('Track Communication Proficiency'),
              value: trackProficiency,
              onChanged: (val) => setState(() => trackProficiency = val),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Offline & Data', primaryColor),
            SwitchListTile(
              title: const Text('Offline Mode'),
              subtitle: const Text('Download frequently used medical phrases and basic translations'),
              value: offlineMode,
              onChanged: (val) => setState(() => offlineMode = val),
            ),
            ElevatedButton(
              onPressed: () {},
              style: _sectionButtonStyle(primaryColor),
              child: const Text('Cache Management'),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Emergency & Safety', primaryColor),
            ElevatedButton(
              onPressed: () {},
              style: _sectionButtonStyle(primaryColor),
              child: const Text('Emergency Communication Button Setup'),
            ),
            SwitchListTile(
              title: const Text('Allow app to access location for emergency services'),
              value: allowEmergencyLocation,
              onChanged: (val) => setState(() => allowEmergencyLocation = val),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Phrasebook', primaryColor),
            ElevatedButton(
              onPressed: () {},
              style: _sectionButtonStyle(primaryColor),
              child: const Text('Custom Medical Phrasebook Management'),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Account', primaryColor),
            ElevatedButton(
              onPressed: () {},
              style: _sectionButtonStyle(primaryColor),
              child: const Text('Edit Profile'),
            ),
            ElevatedButton(
              onPressed: () {},
              style: _sectionButtonStyle(primaryColor),
              child: const Text('Change Password'),
            ),
            ElevatedButton(
              onPressed: () {},
              style: _sectionButtonStyle(primaryColor),
              child: const Text('Manage Family/Caregiver Access'),
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