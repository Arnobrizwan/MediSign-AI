import 'package:flutter/material.dart';

class MedicalRecordsPage extends StatelessWidget {
  const MedicalRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Health Records',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Lab Results', primaryColor),
          _expandableTile(
            context,
            title: 'Complete Blood Count - May 5, 2025',
            content: 'WBC: 5.2 (Normal: 4-10)\n'
                'Hemoglobin: 14.0 (Normal: 12-16)\n'
                'Interpretation: Within normal range.\nDoctor Comments: No issues detected.',
          ),
          _expandableTile(
            context,
            title: 'Glucose Level - May 1, 2025',
            content: 'Result: 105 mg/dL (Normal: 70-110)\n'
                'Interpretation: Slightly elevated after meal.\nDoctor Comments: Monitor diet.',
          ),
          const SizedBox(height: 16),

          _sectionHeader('Medication History', primaryColor),
          _simpleCard('Paracetamol 500mg Tablet\nPrescribed by Dr. Smith\nStarted: May 1, 2025\nInstructions: Take 1 tablet every 6 hours if needed.'),
          _simpleCard('Atorvastatin 10mg Tablet\nPrescribed by Dr. Lee\nStarted: April 20, 2025\nInstructions: Take 1 tablet daily at night.'),
          const SizedBox(height: 16),

          _sectionHeader('Allergies & Conditions', primaryColor),
          _simpleCard('Allergies:\n- Penicillin (Rash)\n- Peanuts (Mild)'),
          _simpleCard('Conditions:\n- Type 2 Diabetes\n- Hypertension'),
          const SizedBox(height: 16),

          _sectionHeader('Visit Summaries & Notes', primaryColor),
          _simpleCard('Consultation - May 5, 2025\nDr. Smith, Cardiology\nSummary: Reviewed ECG, normal.\n[View Summary] [View Transcript]'),
          _simpleCard('Hospital Stay - April 15-17, 2025\nDr. Lee, Endocrinology\nSummary: Managed blood sugar levels.\n[View Summary] [View Transcript]'),
          const SizedBox(height: 16),

          _sectionHeader('Immunization Records', primaryColor),
          _simpleCard('COVID-19 Vaccine - Feb 10, 2022\nFlu Vaccine - Oct 5, 2024'),
          const SizedBox(height: 16),

          _sectionHeader('Download/Export Records', primaryColor),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing PDF export...')),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Download as Accessible PDF'),
            style: _buttonStyle(primaryColor),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing plain text export...')),
              );
            },
            icon: const Icon(Icons.text_snippet),
            label: const Text('Download as Plain Text'),
            style: _buttonStyle(primaryColor),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sending to secure email...')),
              );
            },
            icon: const Icon(Icons.email),
            label: const Text('Send to Secure Email'),
            style: _buttonStyle(primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _expandableTile(BuildContext context, {required String title, required String content}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(content),
          ),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening full report...')),
              );
            },
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFF45B69)),
            label: const Text('View Full Report'),
          ),
        ],
      ),
    );
  }

  Widget _simpleCard(String content) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(content),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size.fromHeight(50),
    );
  }
}