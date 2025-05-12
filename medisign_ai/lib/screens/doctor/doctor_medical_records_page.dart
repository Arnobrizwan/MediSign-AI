// lib/screens/medical_records/doctor_medical_records_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Top-level doctor page: lists all patients who have appointments
/// with the logged-in doctor.
class DoctorMedicalRecordsPage extends StatelessWidget {
  const DoctorMedicalRecordsPage({Key? key}) : super(key: key);
  
  // Updated color palette
  Color get primary => const Color(0xFFF45B69);
  
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    bool useHardcodedData = true; // Toggle this for testing with hardcoded data
    
    // Hardcoded list of patients
    final hardcodedPatients = [
      {
        'uid': 'patient1',
        'name': 'Sarah Johnson',
        'email': 'sarah.johnson@example.com',
        'avatar': 'SJ',
      },
      {
        'uid': 'patient2',
        'name': 'Michael Brown',
        'email': 'michael.brown@example.com',
        'avatar': 'MB',
      },
      {
        'uid': 'patient3',
        'name': 'Emily Davis',
        'email': 'emily.davis@example.com',
        'avatar': 'ED',
      },
      {
        'uid': 'patient4',
        'name': 'Robert Wilson',
        'email': 'robert.wilson@example.com',
        'avatar': 'RW',
      },
      {
        'uid': 'patient5',
        'name': 'Jennifer Taylor',
        'email': 'jennifer.taylor@example.com',
        'avatar': 'JT',
      },
    ];
    
    // Fetch all appointments for this doctor, then extract unique patient IDs.
    final stream = FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: uid)
        .snapshots();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: useHardcodedData 
        ? _buildPatientList(context, hardcodedPatients)
        : StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final docs = snap.data!.docs;
              // collect unique patient IDs
              final patientIds = {
                for (var d in docs) (d['patientId'] as String)
              }.toList();
              
              if (patientIds.isEmpty) {
                return const Center(child: Text('No patients yet.'));
              }
              
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: Future.wait(patientIds.map((pid) async {
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(pid)
                      .get();
                  final data = userDoc.data()!;
                  return {
                    'uid': pid,
                    'name': data['displayName'] ?? data['email'] ?? 'Unknown',
                    'email': data['email'] ?? '',
                    'avatar': (data['displayName'] ?? 'U').substring(0, 1),
                  };
                }).toList()),
                builder: (ctx2, snap2) {
                  if (snap2.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final patients = snap2.data!;
                  return _buildPatientList(context, patients);
                },
              );
            },
          ),
    );
  }
  
  Widget _buildPatientList(BuildContext context, List<Map<String, dynamic>> patients) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: patients.length,
      itemBuilder: (context, i) {
        final p = patients[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, 
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: primary.withOpacity(0.1),
              radius: 24,
              child: Text(
                p['avatar'] ?? p['name'].substring(0, 1),
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              p['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(p['email']),
            trailing: Icon(Icons.chevron_right, color: primary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientMedicalRecordsView(userId: p['uid']),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Very similar to your existing MedicalRecordsPage, but parameterized
/// by a `userId` so doctors can view any patient's records.
class PatientMedicalRecordsView extends StatelessWidget {
  final String userId;
  
  const PatientMedicalRecordsView({Key? key, required this.userId}) : super(key: key);
  
  // Updated color palette
  Color get primary => const Color(0xFFF45B69);
  
  FirebaseFirestore get db => FirebaseFirestore.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Records',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade50,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Lab Results'),
          _buildLabResults(),
          const SizedBox(height: 24),
          _sectionHeader('Medication History'),
          _buildMedicationHistory(),
          const SizedBox(height: 24),
          _sectionHeader('Allergies & Conditions'),
          _buildAllergiesAndConditions(),
          const SizedBox(height: 24),
          _sectionHeader('Visit Summaries & Notes'),
          _buildVisitSummaries(),
          const SizedBox(height: 24),
          _sectionHeader('Immunization Records'),
          _buildImmunizations(),
          const SizedBox(height: 24),
          _sectionHeader('Download / Export Records'),
          _buildDownloadPdfButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLabResults() {
    // Always use demo data for consistency
    return Column(
      children: [
        _demoCard(
          title: 'Complete Blood Count — ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 3)))}',
          body:
            'WBC: 5.2 (4-10)\n'
            'Hemoglobin: 14.0 (12-16)\n'
            'Interpretation: Within normal range.\n'
            'Comments: No issues detected.',
        ),
        _demoCard(
          title: 'Lipid Panel — ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 30)))}',
          body:
            'Total Cholesterol: 185 mg/dL (< 200)\n'
            'LDL: 110 mg/dL (< 130)\n'
            'HDL: 55 mg/dL (> 40)\n'
            'Triglycerides: 120 mg/dL (< 150)\n'
            'Interpretation: Within normal range.\n'
            'Comments: Good cholesterol profile, maintain current diet.',
        ),
        _demoCard(
          title: 'Thyroid Function — ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 90)))}',
          body:
            'TSH: 2.5 mIU/L (0.4-4.0)\n'
            'T4: 1.2 ng/dL (0.8-1.8)\n'
            'Interpretation: Normal thyroid function.\n'
            'Comments: No abnormalities detected.',
        ),
      ],
    );
  }
  
  Widget _buildMedicationHistory() {
    // Always use demo data for consistency
    return Column(
      children: [
        _demoCard(
          title: 'Atorvastatin 10mg Tablet',
          body:
            'Prescribed by Dr. Johnson\n'
            'Started: ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 30)))}\n'
            'Instructions: Take 1 tablet nightly.',
        ),
        _demoCard(
          title: 'Lisinopril 5mg Tablet',
          body:
            'Prescribed by Dr. Smith\n'
            'Started: ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 60)))}\n'
            'Instructions: Take 1 tablet daily in the morning.',
        ),
        _demoCard(
          title: 'Metformin 500mg Tablet',
          body:
            'Prescribed by Dr. Johnson\n'
            'Started: ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 90)))}\n'
            'Ended: ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 30)))}\n'
            'Instructions: Take 1 tablet twice daily with meals.',
        ),
      ],
    );
  }
  
  Widget _buildAllergiesAndConditions() {
    // Always use demo data for consistency
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pill('Allergies:\n• Penicillin - Moderate\n• Peanuts - Severe\n• Latex - Mild'),
        const SizedBox(height: 8),
        _pill('Conditions:\n• Hypertension (diagnosed ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 180)))})\n• Type 2 Diabetes (diagnosed ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 365)))})'),
      ],
    );
  }
  
  Widget _buildVisitSummaries() {
    // Always use demo data for consistency
    return Column(
      children: [
        _demoCard(
          title: '${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 7)))} — Dr. Johnson',
          body: 'Follow-up appointment for hypertension. Blood pressure 130/85, which is improved from previous visit. Continuing current medication regimen.',
        ),
        _demoCard(
          title: '${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 30)))} — Dr. Smith',
          body: 'Annual physical examination. All vitals within normal range. Discussed diet and exercise plan for diabetes management.',
        ),
        _demoCard(
          title: '${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 90)))} — Dr. Johnson',
          body: 'Consultation for mild back pain. Recommended physical therapy and OTC pain relievers as needed. No significant findings on examination.',
        ),
      ],
    );
  }
  
  Widget _buildImmunizations() {
    // Always use demo data for consistency
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: primary.withOpacity(0.1),
              child: Icon(Icons.local_hospital, color: primary, size: 20),
            ),
            title: const Text('COVID-19 Vaccine (Moderna)'),
            subtitle: Text(DateFormat.yMMMd().format(DateTime(2022, 2, 10))),
          ),
          const Divider(height: 1, indent: 70),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: primary.withOpacity(0.1),
              child: Icon(Icons.local_hospital, color: primary, size: 20),
            ),
            title: const Text('Influenza Vaccine'),
            subtitle: Text(DateFormat.yMMMd().format(DateTime(2022, 10, 5))),
          ),
          const Divider(height: 1, indent: 70),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: primary.withOpacity(0.1),
              child: Icon(Icons.local_hospital, color: primary, size: 20),
            ),
            title: const Text('Tdap Booster'),
            subtitle: Text(DateFormat.yMMMd().format(DateTime(2020, 6, 15))),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDownloadPdfButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Download Complete Medical Record'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        // Since this is hardcoded data, just show a snackbar instead of launching a URL
        ScaffoldMessenger.of(GlobalKey<ScaffoldState>().currentContext!)
            .showSnackBar(
          const SnackBar(
            content: Text('PDF download started...'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }
  
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  
  Widget _demoCard({required String title, required String body}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, 
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _pill(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: const TextStyle(height: 1.4)),
    );
  }
}