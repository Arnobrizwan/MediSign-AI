import 'package:flutter/material.dart';

class HospitalGuidePage extends StatelessWidget {
  const HospitalGuidePage({super.key});

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
          'Hospital Information & Guide',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTile(context, primaryColor, Icons.person_search, 'Doctor Directory', '/doctor_directory'),
          _sectionTile(context, primaryColor, Icons.local_hospital, 'Department & Services Directory', '/department_services'),
          _sectionTile(context, primaryColor, Icons.map, 'Interactive Map & Wayfinding', '/map_wayfinding'),
          _sectionTile(context, primaryColor, Icons.info_outline, 'General Hospital Info', '/general_info'),
          _sectionTile(context, primaryColor, Icons.warning, 'Emergency Procedures Guide', '/emergency_guide'),
        ],
      ),
    );
  }

  Widget _sectionTile(BuildContext context, Color primaryColor, IconData icon, String title, String route) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: primaryColor, size: 32),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}