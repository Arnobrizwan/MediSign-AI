import 'package:flutter/material.dart';

class PatientLocatorPage extends StatefulWidget {
  const PatientLocatorPage({super.key});

  @override
  State<PatientLocatorPage> createState() => _PatientLocatorPageState();
}

class _PatientLocatorPageState extends State<PatientLocatorPage> {
  String selectedFilter = 'Wheelchair Accessible Paths';

  void requestAmbulance() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Emergency Request'),
        content: const Text(
            'Are you sure you want to request emergency assistance? This will alert hospital emergency staff and share your location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help is on the way. Your location has been shared. Stay calm.'),
                ),
              );
            },
            child: const Text('Yes, Request Help'),
          ),
        ],
      ),
    );
  }

  void callEmergencyContact() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling your emergency contact...')),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Emergency Locator & Request',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Emergency Locator (if staff/caregiver-enabled)
            _sectionHeader('Patient Location (For Staff Use)', primaryColor),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Emergency Location Map Placeholder'),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: InputDecoration(
                labelText: 'Accessibility Route Filters (Staff View)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              items: const [
                DropdownMenuItem(value: 'Wheelchair Accessible Paths', child: Text('Wheelchair Accessible Paths')),
                DropdownMenuItem(value: 'Braille Signage Routes', child: Text('Braille Signage Routes')),
                DropdownMenuItem(value: 'Quiet Paths', child: Text('Quiet Paths')),
              ],
              onChanged: (val) => setState(() => selectedFilter = val!),
            ),

            const SizedBox(height: 24),

            // Emergency Assistance Section
            _sectionHeader('Emergency Assistance', primaryColor),
            ElevatedButton.icon(
              onPressed: requestAmbulance,
              icon: const Icon(Icons.local_hospital),
              label: const Text('REQUEST AMBULANCE / IMMEDIATE ASSISTANCE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: callEmergencyContact,
              icon: const Icon(Icons.call),
              label: const Text('Call Emergency Contact'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'For general navigation and hospital information, please use the "Hospital Guide & Wayfinding" section on your Dashboard.',
                  style: TextStyle(color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}