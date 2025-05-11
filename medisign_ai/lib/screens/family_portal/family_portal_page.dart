// lib/screens/family_portal/family_portal_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FamilyPortalPage extends StatefulWidget {
  const FamilyPortalPage({Key? key}) : super(key: key);

  @override
  State<FamilyPortalPage> createState() => _FamilyPortalPageState();
}

class _FamilyPortalPageState extends State<FamilyPortalPage> {
  String? _patientName;
  String? _doctorName;
  bool _loading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPatientAndDoctor();
  }

  Future<void> _loadPatientAndDoctor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};
      _patientName = data['name'] as String? ?? 'Patient';
      _doctorName = data['assignedDoctor'] as String? ?? 'Doctor';
    } else {
      _patientName = 'Patient';
      _doctorName = 'Doctor';
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFF45B69);
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '$_patientName’s Portal',
          style: TextStyle(color: primary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF45B69)),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Greeting
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFF45B69),
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Welcome, $_patientName!',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Health Summary
          _buildSectionHeader('Health Summary', primary),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: Column(
              children: [
                _buildInfoTile(Icons.favorite, 'Mild headache',
                    'Paracetamol taken today'),
                const Divider(height: 1),
                _buildInfoTile(Icons.health_and_safety, 'Lab Results',
                    'Latest blood test uploaded'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Upcoming Appointments
          _buildSectionHeader('Upcoming Appointments', primary),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: Column(
              children: [
                _buildInfoTile(Icons.calendar_today,
                    'Telemedicine with $_doctorName', 'Tomorrow, 10:00 AM'),
                const Divider(height: 1),
                _buildInfoTile(Icons.local_hospital, 'Cardiology Visit',
                    'Next Monday, 2:00 PM'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Prescriptions & Billing
          Row(
            children: [
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Column(
                    children: [
                      _buildInfoTile(Icons.medication, 'Heart Meds',
                          'Refill available'),
                      const Divider(height: 1),
                      _buildInfoTile(Icons.medication_liquid, 'BP Pills',
                          'Next refill in 1 week'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Column(
                    children: [
                      _buildInfoTile(Icons.payment, 'Balance Due',
                          'RM 200 by month end'),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            minimumSize: const Size.fromHeight(40),
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/billing'),
                          child: const Text('Assist Payment'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Communication Logs
          _buildSectionHeader('Communication Logs', primary),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFFF45B69)),
              title: const Text('Check-in Chat'),
              subtitle: const Text('Tap to view transcript'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.pushNamed(context, '/transcript_history'),
            ),
          ),
          const SizedBox(height: 20),

          // Communication Tools
          _buildSectionHeader('Communication Tools', primary),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/telemedicine'),
                    icon: const Icon(Icons.videocam),
                    label: Text('Live Call $_doctorName'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/conversation_mode'),
                    icon: const Icon(Icons.message),
                    label: const Text('Text Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Notification Settings
          _buildSectionHeader('Notification Settings', primary),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: SwitchListTile(
              title: const Text('Enable Patient Alerts'),
              value: _notificationsEnabled,
              activeColor: primary,
              onChanged: (v) {
                setState(() => _notificationsEnabled = v);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(v
                        ? 'Patient alerts enabled'
                        : 'Patient alerts disabled'),
                  ),
                );
                // TODO: persist this setting into Firestore or SharedPreferences
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFF45B69)),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}