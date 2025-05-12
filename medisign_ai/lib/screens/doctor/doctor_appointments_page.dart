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
  
  // Updated color palette
  final _primaryColor = const Color(0xFFF45B69);
  final _accentColor = const Color(0xFF4694FA);
  
  // Current date for appointments
  final today = DateTime.now();
  
  // Hardcoded appointment data
  late List<Map<String, dynamic>> _hardcodedUpcoming;
  late List<Map<String, dynamic>> _hardcodedPast;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize hardcoded data
    _initHardcodedData();
    
    // Simulate loading data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _initHardcodedData() {
    _hardcodedUpcoming = [
      {
        'patientName': 'Sarah Johnson',
        'dateTime': DateTime(today.year, today.month, today.day, 8, 37),
        'status': 'Confirmed',
        'type': 'Check-up',
        'notes': 'Follow-up on blood pressure medication',
      },
      {
        'patientName': 'Michael Brown',
        'dateTime': DateTime(today.year, today.month, today.day, 10, 37),
        'status': 'Pending',
        'type': 'Consultation',
        'notes': 'New patient with back pain symptoms',
      },
      {
        'patientName': 'Emily Davis',
        'dateTime': DateTime(today.year, today.month, today.day + 1, 5, 37),
        'status': 'Confirmed',
        'type': 'Telemedicine',
        'notes': 'Diabetes management review',
      },
      {
        'patientName': 'Robert Wilson',
        'dateTime': DateTime(today.year, today.month, today.day + 1, 9, 37),
        'status': 'Pending',
        'type': 'Laboratory Results',
        'notes': 'Review recent blood work and adjust treatment plan',
      },
    ];
    
    _hardcodedPast = [
      {
        'patientName': 'Jennifer Taylor',
        'dateTime': DateTime(today.year, today.month, today.day - 2, 14, 30),
        'status': 'Completed',
        'type': 'Prescription Renewal',
        'notes': 'Renewed hypertension medication for 3 months',
      },
      {
        'patientName': 'David Miller',
        'dateTime': DateTime(today.year, today.month, today.day - 3, 9, 15),
        'status': 'Completed',
        'type': 'Follow-up',
        'notes': 'Post-surgery recovery progressing well',
      },
      {
        'patientName': 'Lisa Garcia',
        'dateTime': DateTime(today.year, today.month, today.day - 5, 11, 0),
        'status': 'Cancelled',
        'type': 'Check-up',
        'notes': 'Patient did not show up for appointment',
      },
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fixed Firebase query to use appointmentDate instead of dateTime
  Stream<QuerySnapshot> _appointmentsStream() {
    final uid = _auth.currentUser?.uid;
    
    try {
      return _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: uid)
          .orderBy('appointmentDate')
          .snapshots();
    } catch (e) {
      return Stream<QuerySnapshot>.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new appointment functionality
        },
        backgroundColor: Color(0xFF4694FA),
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_hardcodedUpcoming, isUpcoming: true),
              _buildList(_hardcodedPast, isUpcoming: false),
            ],
          ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, {required bool isUpcoming}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isUpcoming ? 'No upcoming appointments.' : 'No past appointments.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final appointment = list[index];
        final dt = appointment['dateTime'] as DateTime;
        final status = appointment['status'] as String;
        final patientName = appointment['patientName'] as String;
        final type = appointment['type'] as String;
        final notes = appointment['notes'] as String;
        
        // Colors for status badges
        Color statusBgColor;
        Color statusIconColor;
        IconData statusIcon;
        
        switch (status.toLowerCase()) {
          case 'confirmed':
            statusBgColor = Colors.green.shade100;
            statusIconColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'pending':
            statusBgColor = Colors.orange.shade100;
            statusIconColor = Colors.orange;
            statusIcon = Icons.pending;
            break;
          case 'completed':
            statusBgColor = Colors.blue.shade100;
            statusIconColor = Colors.blue;
            statusIcon = Icons.done_all;
            break;
          case 'cancelled':
            statusBgColor = Colors.red.shade100;
            statusIconColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
          default:
            statusBgColor = Colors.grey.shade100;
            statusIconColor = Colors.grey;
            statusIcon = Icons.error_outline;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date badge, patient info and status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date badge
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Color(0xFFFEEAED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dt.day.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(dt),
                            style: TextStyle(
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Patient info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            type,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('h:mm a').format(dt),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusIconColor),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusIconColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Notes
                Container(
                  padding: const EdgeInsets.only(left: 8, top: 12, bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action buttons - match the screenshot exactly
                if (isUpcoming)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.video_call),
                          label: const Text('Start Session'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        child: Text(
                          'Records',
                          style: TextStyle(color: _accentColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _accentColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert),
                        color: Colors.grey,
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