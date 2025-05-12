
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({Key? key}) : super(key: key);

  @override
  _DoctorAppointmentsPageState createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _primaryColor = const Color(0xFF0070BA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _appointmentsStream() {
    final uid = _auth.currentUser?.uid;
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: uid)
        .orderBy('dateTime')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _appointmentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          final now = DateTime.now();

          final upcoming = docs.where((d) {
            final dt = (d['dateTime'] as Timestamp).toDate();
            return dt.isAfter(now);
          }).toList();

          final past = docs.where((d) {
            final dt = (d['dateTime'] as Timestamp).toDate();
            return dt.isBefore(now);
          }).toList().reversed.toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(upcoming, isUpcoming: true),
              _buildList(past, isUpcoming: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> list, {required bool isUpcoming}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isUpcoming ? 'No upcoming appointments.' : 'No past appointments.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final d = list[index].data()! as Map<String, dynamic>;
        final dt = (d['dateTime'] as Timestamp).toDate();
        final formatted = DateFormat.yMMMd().add_jm().format(dt);
        final status = d['status'] as String? ?? '';
        final patient = d['patientName'] as String? ?? 'Patient';
        final type = d['type'] as String? ?? '';

        final badgeColor = status.toLowerCase() == 'confirmed'
            ? Colors.green.shade100
            : Colors.orange.shade100;
        final textColor = status.toLowerCase() == 'confirmed'
            ? Colors.green.shade800
            : Colors.orange.shade800;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Patient & Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$patient — $type',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Date/time
                Text(
                  formatted,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                if (isUpcoming)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // e.g. navigate to telemedicine or conversation
                        },
                        icon: const Icon(Icons.video_call),
                        label: const Text('Start Consultation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          // e.g. view/edit notes
                        },
                        child: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
  }
}