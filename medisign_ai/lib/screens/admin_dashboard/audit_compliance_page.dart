import 'package:flutter/material.dart';

class AuditCompliancePage extends StatelessWidget {
  const AuditCompliancePage({super.key});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: Text('Audit, Compliance & User Management', style: TextStyle(color: primaryColor)),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('User Account Management', primaryColor),
          _placeholderCard('View/Edit Profiles, Caregiver Links, Passwords'),
          _sectionHeader('Access Control & Permissions', primaryColor),
          _placeholderCard('Role Settings, Consent Management'),
          _sectionHeader('Audit Logs', primaryColor),
          _placeholderCard('Medical Record Access, Admin Actions'),
          _sectionHeader('Data & Privacy Compliance', primaryColor),
          _placeholderCard('Data Export, Deletion, Retention Policies'),
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
        leading: const Icon(Icons.security, color: Color(0xFFF45B69)),
        title: Text(label),
      ),
    );
  }
}