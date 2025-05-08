import 'package:flutter/material.dart';

class PrescriptionsPage extends StatelessWidget {
  const PrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    List<Map<String, String>> currentPrescriptions = [
      {
        'name': 'Paracetamol 500mg Tablet',
        'instructions': 'Take 1 tablet every 6 hours if needed.',
        'refills': '2 remaining',
        'doctor': 'Dr. Smith',
        'pharmacy': 'City Pharmacy',
        'nextRefill': 'May 15, 2025',
      },
      {
        'name': 'Atorvastatin 10mg Tablet',
        'instructions': 'Take 1 tablet daily at night.',
        'refills': '1 remaining',
        'doctor': 'Dr. Lee',
        'pharmacy': 'WellCare Pharmacy',
        'nextRefill': 'May 20, 2025',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Prescriptions',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...currentPrescriptions.map((med) => _prescriptionCard(context, primaryColor, med)),
          const SizedBox(height: 24),
          _sectionHeader('Refill Request History', primaryColor),
          _simpleCard('Paracetamol: Approved - May 1, 2025'),
          _simpleCard('Atorvastatin: Pending - May 3, 2025'),
        ],
      ),
    );
  }

  Widget _prescriptionCard(BuildContext context, Color primaryColor, Map<String, String> med) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(med['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(med['instructions'] ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Refills: ${med['refills']}'),
            Text('Prescribed by: ${med['doctor']}'),
            Text('Pharmacy: ${med['pharmacy']}'),
            Text('Next Refill Due: ${med['nextRefill']}'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Refill request sent for ${med['name']}')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Request Refill'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing info for ${med['name']}')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Info'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.alarm, color: Color(0xFFF45B69)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reminder set for ${med['name']}')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
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

  Widget _simpleCard(String content) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(content),
      ),
    );
  }
}