// lib/screens/medical_records/doctor_medical_records_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Top‐level doctor page: lists all patients who have appointments
/// with the logged‐in doctor.
class DoctorMedicalRecordsPage extends StatelessWidget {
  const DoctorMedicalRecordsPage({Key? key}) : super(key: key);
  Color get primary => const Color(0xFF0070BA);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Fetch all appointments for this doctor, then extract unique patient IDs.
    final stream = FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
              };
            }).toList()),
            builder: (ctx2, snap2) {
              if (snap2.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final patients = snap2.data!;
              return ListView.separated(
                itemCount: patients.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = patients[i];
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(p['email']),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientMedicalRecordsView(userId: p['uid']),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Very similar to your existing MedicalRecordsPage, but parameterized
/// by a `userId` so doctors can view any patient’s records.
class PatientMedicalRecordsView extends StatelessWidget {
  final String userId;
  const PatientMedicalRecordsView({Key? key, required this.userId}) : super(key: key);

  Color get primary => const Color(0xFF0070BA);
  FirebaseFirestore get db => FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Records'),
        backgroundColor: primary,
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
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
    );
  }

  Widget _buildLabResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
        .collection('users')
        .doc(userId)
        .collection('labResults')
        .orderBy('date', descending: true)
        .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _demoCard(
            title: 'Complete Blood Count — ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days:3)))}',
            body:
              'WBC: 5.2 (4-10)\n'
              'Hemoglobin: 14.0 (12-16)\n'
              'Interpretation: Within normal range.\n'
              'Comments: No issues detected.',
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final title = '${data['testName'] ?? 'Test'} — ${DateFormat.yMMMd().format(date)}';
            final details = StringBuffer()
              ..writeln(data['results'] ?? '')
              ..writeln('Normal: ${data['referenceRange'] ?? ''}')
              ..writeln('Interpretation: ${data['interpretation'] ?? ''}')
              ..writeln('Comments: ${data['doctorComments'] ?? ''}');
            final reportUrl = data['reportUrl'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(details.toString()),
                  ),
                  if (reportUrl != null)
                    TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF0070BA)),
                      label: const Text('View Full Report'),
                      onPressed: () => _launchUrl(reportUrl),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMedicationHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
        .collection('users')
        .doc(userId)
        .collection('medicationHistory')
        .orderBy('prescribedDate', descending: true)
        .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _demoCard(
            title: 'Atorvastatin 10mg Tablet',
            body:
              'Prescribed by Dr. Lee\n'
              'Started: ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days:30)))}\n'
              'Instructions: Take 1 tablet nightly.',
          );
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data()! as Map<String, dynamic>;
            final start = (d['prescribedDate'] as Timestamp).toDate();
            final end = d['endDate'] != null ? (d['endDate'] as Timestamp).toDate() : null;
            final period = end != null
              ? 'From ${DateFormat.yMd().format(start)} to ${DateFormat.yMd().format(end)}'
              : 'Since ${DateFormat.yMd().format(start)}';
            return _demoCard(
              title: '${d['medName'] ?? 'Meds'} ${d['dosage'] ?? ''}',
              body:
                'Prescribed by ${d['prescribingDoctor'] ?? ''}\n'
                '$period\n'
                'Instructions: ${d['instructions'] ?? ''}',
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAllergiesAndConditions() {
    return FutureBuilder<DocumentSnapshot>(
      future: db.collection('users').doc(userId).get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final data = (snap.data?.data() ?? {}) as Map<String, dynamic>;
        final allergies = List<String>.from(data['allergies'] ?? []);
        final conditions = List<String>.from(data['conditions'] ?? []);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pill('${allergies.isEmpty ? 'No known allergies.' : 'Allergies:\n• ${allergies.join('\n• ')}'}'),
            const SizedBox(height: 8),
            _pill('${conditions.isEmpty ? 'No diagnosed conditions.' : 'Conditions:\n• ${conditions.join('\n• ')}'}'),
          ],
        );
      },
    );
  }

  Widget _buildVisitSummaries() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
        .collection('users')
        .doc(userId)
        .collection('visitSummaries')
        .orderBy('visitDate', descending: true)
        .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _demoCard(
            title: '${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days:7)))} — Dr. Mim',
            body: 'Reviewed ECG; all normal.',
          );
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data()! as Map<String, dynamic>;
            final date = (d['visitDate'] as Timestamp).toDate();
            final transcriptUrl = d['transcriptUrl'] as String?;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  '${DateFormat.yMMMd().format(date)} — ${d['doctor'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(d['summary'] ?? ''),
                isThreeLine: true,
                trailing: transcriptUrl != null
                  ? IconButton(
                      icon: const Icon(Icons.chat_bubble, color: Color(0xFF0070BA)),
                      onPressed: () => _launchUrl(transcriptUrl),
                    )
                  : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildImmunizations() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
        .collection('users')
        .doc(userId)
        .collection('immunizations')
        .orderBy('date', descending: true)
        .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _demoCard(
            title: 'COVID-19 Vaccine',
            body: 'Administered: ${DateFormat.yMMMd().format(DateTime(2022,2,10))}',
          );
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data()! as Map<String, dynamic>;
            final date = (d['date'] as Timestamp).toDate();
            return ListTile(
              leading: const Icon(Icons.local_hospital, color: Color(0xFF0070BA)),
              title: Text(d['vaccine'] ?? ''),
              subtitle: Text(DateFormat.yMMMd().format(date)),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDownloadPdfButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Download PDF'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        final userDoc = await db.collection('users').doc(userId).get();
        final pdfUrl = (userDoc.data() ?? {})['recordsPdfUrl'] as String?;
        if (pdfUrl != null && pdfUrl.isNotEmpty) {
          _launchUrl(pdfUrl);
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(userId as BuildContext).showSnackBar(
            const SnackBar(content: Text('No PDF URL configured for download')),
          );
        }
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(body),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text),
    );
  }
}