import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(color: primaryColor)),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Analytics', primaryColor),
          _analyticsCard('Appointments'),
          _analyticsCard('EHR Access'),
          _analyticsCard('Prescription Refills'),
          _analyticsCard('Hospital Info Usage'),
          _analyticsCard('Billing'),
          _sectionHeader('Quick Links', primaryColor),
          _quickLink(context, 'Manage Appointment Configurations', '/admin_manage_appointments'),
          _quickLink(context, 'Manage Hospital Content', '/admin_manage_content'),
          _quickLink(context, 'User Support Tickets', '/admin_support_tickets'),
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

  Widget _analyticsCard(String title) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.bar_chart, color: Color(0xFFF45B69)),
        title: Text(title),
      ),
    );
  }

  Widget _quickLink(BuildContext context, String label, String route) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}