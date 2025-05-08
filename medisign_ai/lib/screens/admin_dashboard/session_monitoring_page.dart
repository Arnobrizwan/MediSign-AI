import 'package:flutter/material.dart';

class SessionMonitoringPage extends StatelessWidget {
  const SessionMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: Text('Session Monitoring & Support', style: TextStyle(color: primaryColor)),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Active Sessions', primaryColor),
          _placeholderCard('Real-time Session List'),
          _sectionHeader('User Support Tickets', primaryColor),
          _placeholderCard('Ticket List, Assign, Track, Filter, Notes'),
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
        leading: const Icon(Icons.list, color: Color(0xFFF45B69)),
        title: Text(label),
      ),
    );
  }
}