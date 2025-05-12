// lib/screens/prescription_management/doctor_prescriptions_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorPrescriptionsPage extends StatefulWidget {
  const DoctorPrescriptionsPage({Key? key}) : super(key: key);

  @override
  State<DoctorPrescriptionsPage> createState() =>
      _DoctorPrescriptionsPageState();
}

class _DoctorPrescriptionsPageState extends State<DoctorPrescriptionsPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _doctorId => _auth.currentUser!.uid;
  Color get _primary => const Color(0xFF0070BA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Requests'),
        backgroundColor: _primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // We assume you store requests in a top‐level collection "prescriptionRequests"
        // each doc having: patientId, prescriptionId, name, requestedAt, status
        stream: _db
            .collection('prescriptionRequests')
            .where('doctorId', isEqualTo: _doctorId)
            .where('status', isEqualTo: 'pending')
            .orderBy('requestedAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data()! as Map<String, dynamic>;
              final requestedAt = (d['requestedAt'] as Timestamp).toDate();
              final patientName = d['patientName'] as String? ?? 'Patient';
              final prescriptionName = d['name'] as String? ?? '';
              final docId = docs[i].id;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prescriptionName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Patient: $patientName'),
                      const SizedBox(height: 4),
                      Text(
                        'Requested: ${DateFormat.yMMMd().add_jm().format(requestedAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _updateRequestStatus(
                                  docId, 'approved'),
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red.shade700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () =>
                                  _updateRequestStatus(docId, 'declined'),
                              child: Text(
                                'Decline',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _db
          .collection('prescriptionRequests')
          .doc(requestId)
          .update({'status': newStatus, 'handledAt': FieldValue.serverTimestamp()});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'approved'
                ? 'Request approved.'
                : 'Request declined.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating request: $e')),
      );
    }
  }
}