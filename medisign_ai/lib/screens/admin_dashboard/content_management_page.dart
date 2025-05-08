import 'package:flutter/material.dart';

class ContentManagementPage extends StatelessWidget {
  const ContentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: Text('Content & Systems Management', style: TextStyle(color: primaryColor)),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Appointments', primaryColor),
          _placeholderCard('Doctor Schedules, Appointment Rules, Reminder Templates'),
          _sectionHeader('Hospital Content', primaryColor),
          _placeholderCard('Doctor Directory, Department & Services CRUD, Maps'),
          _sectionHeader('Medical Records Display', primaryColor),
          _placeholderCard('Templates, Jargon Simplification, Consent Forms'),
          _sectionHeader('Prescription Workflow', primaryColor),
          _placeholderCard('Refill Flow, Queues, Status Tracking'),
          _sectionHeader('Billing & Financial', primaryColor),
          _placeholderCard('Bill Templates, Financial Assistance, Payment Gateway'),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _placeholderCard(String label) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.settings, color: Color(0xFFF45B69)),
        title: Text(label),
      ),
    );
  }
}