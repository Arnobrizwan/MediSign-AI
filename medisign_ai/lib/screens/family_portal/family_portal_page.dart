import 'package:flutter/material.dart';

class FamilyPortalPage extends StatelessWidget {
  const FamilyPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    String patientName = 'John Doe';
    String caregiverName = 'Anna Smith';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '$patientName\'s Portal - Welcome $caregiverName',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Logout', style: TextStyle(color: Color(0xFFF45B69))),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Patient Health Summary
          _sectionHeader('Patient Health Summary (Consented)', primaryColor),
          _infoCard(Icons.favorite, 'Recent AI Check-in: Mild Headache', 'Medication: Paracetamol confirmed taken today.'),
          _infoCard(Icons.health_and_safety, 'Health Record Access', 'Latest lab results and visit summaries available.'),
          const SizedBox(height: 16),

          // Upcoming Appointments
          _sectionHeader('Upcoming Appointments (Consented)', primaryColor),
          _infoCard(Icons.calendar_today, 'Telemedicine with Dr. Smith', 'Tomorrow at 10:00 AM'),
          _infoCard(Icons.local_hospital, 'In-person Visit - Cardiology', 'Next Monday at 2:00 PM'),
          const SizedBox(height: 16),

          // Prescriptions
          _sectionHeader('Current Prescriptions (Consented)', primaryColor),
          _infoCard(Icons.medication, 'Heart Medication', 'Refill available'),
          _infoCard(Icons.medication_liquid, 'Blood Pressure Pills', 'Next refill: 1 week'),
          const SizedBox(height: 16),

          // Bills & Payments
          _sectionHeader('Bills & Payments (Consented)', primaryColor),
          _infoCard(Icons.payment, 'Outstanding Balance', 'RM 200 due by next month'),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening payment assistance interface...')),
              );
            },
            icon: const Icon(Icons.attach_money),
            label: const Text('Assist with Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 24),

          // Communication Logs
          _sectionHeader('Recent Communication Logs', primaryColor),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFFF45B69)),
              title: const Text('Check-in Chat Summary'),
              subtitle: const Text('Click to view full transcript'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening full transcript...')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Patient Progress
          _sectionHeader('Patient Progress', primaryColor),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: const Text('7-Day Check-in Streak')),
              Chip(label: const Text('Learned 10 BIM Phrases')),
            ],
          ),
          const SizedBox(height: 24),

          // Communication Tools
          _sectionHeader('Communication Tools', primaryColor),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening video message recorder...')),
              );
            },
            icon: const Icon(Icons.videocam),
            label: const Text('Video Message to John'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting live call...')),
              );
            },
            icon: const Icon(Icons.call),
            label: const Text('Live Call John'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 24),

          // Caregiver Settings
          _sectionHeader('Caregiver Settings', primaryColor),
          SwitchListTile(
            title: const Text('Enable Notifications for Patient Alerts'),
            value: true,
            activeColor: primaryColor,
            onChanged: (val) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Notifications enabled' : 'Notifications disabled')),
              );
            },
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

  Widget _infoCard(IconData icon, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFF45B69)),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}