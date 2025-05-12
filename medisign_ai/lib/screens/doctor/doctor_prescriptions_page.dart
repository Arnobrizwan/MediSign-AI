// lib/screens/prescription_management/doctor_prescriptions_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorPrescriptionsPage extends StatefulWidget {
  const DoctorPrescriptionsPage({Key? key}) : super(key: key);

  @override
  State<DoctorPrescriptionsPage> createState() => _DoctorPrescriptionsPageState();
}

class _DoctorPrescriptionsPageState extends State<DoctorPrescriptionsPage> with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  // Get doctor ID safely
  String? get _doctorId => _auth.currentUser?.uid;
  
  // Updated color palette
  Color get _primary => const Color(0xFFF45B69);
  
  // Tab controller for the two sections
  late TabController _tabController;
  
  // Flag to use hardcoded data (set to false to use Firestore)
  final bool _useHardcodedData = true;
  
  // Loading state
  bool _isLoading = false;
  
  // Hardcoded prescription requests for testing
  final List<Map<String, dynamic>> _pendingRequests = [
    {
      'id': 'req1',
      'patientName': 'Sarah Johnson',
      'name': 'Lisinopril 10mg',
      'requestedAt': DateTime.now().subtract(const Duration(hours: 3)),
      'notes': 'Patient requests renewal of blood pressure medication',
      'type': 'Renewal'
    },
    {
      'id': 'req2',
      'patientName': 'Michael Brown',
      'name': 'Amoxicillin 500mg',
      'requestedAt': DateTime.now().subtract(const Duration(hours: 8)),
      'notes': 'For sinus infection, no known allergies to antibiotics',
      'type': 'New'
    },
    {
      'id': 'req3',
      'patientName': 'Emily Davis',
      'name': 'Metformin 500mg',
      'requestedAt': DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      'notes': 'Diabetes medication, previous prescription expired',
      'type': 'Renewal'
    },
    {
      'id': 'req4',
      'patientName': 'Robert Wilson',
      'name': 'Albuterol Inhaler',
      'requestedAt': DateTime.now().subtract(const Duration(days: 1, hours: 7)),
      'notes': 'For asthma symptoms that have been worsening recently',
      'type': 'New'
    },
  ];
  
  // Hardcoded processed prescriptions
  final List<Map<String, dynamic>> _processedRequests = [
    {
      'id': 'req5',
      'patientName': 'Jennifer Taylor',
      'name': 'Atorvastatin 20mg',
      'requestedAt': DateTime.now().subtract(const Duration(days: 2)),
      'handledAt': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'approved',
      'notes': 'Cholesterol medication',
      'type': 'Renewal'
    },
    {
      'id': 'req6',
      'patientName': 'David Miller',
      'name': 'Oxycodone 5mg',
      'requestedAt': DateTime.now().subtract(const Duration(days: 3)),
      'handledAt': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'declined',
      'notes': 'Patient requested stronger pain medication',
      'type': 'New'
    },
    {
      'id': 'req7',
      'patientName': 'Lisa Garcia',
      'name': 'Levothyroxine 50mcg',
      'requestedAt': DateTime.now().subtract(const Duration(days: 5)),
      'handledAt': DateTime.now().subtract(const Duration(days: 4)),
      'status': 'approved',
      'notes': 'Thyroid medication',
      'type': 'Renewal'
    },
  ];
  
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prescription Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Processed'),
          ],
        ),
      ),
      body: _useHardcodedData
          ? _buildHardcodedView()
          : _buildFirestoreView(),
    );
  }
  
  Widget _buildHardcodedView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Pending Tab
        _pendingRequests.isEmpty
            ? Center(child: Text('No pending requests.'))
            : _buildRequestsList(_pendingRequests, isPending: true),
        
        // Processed Tab
        _processedRequests.isEmpty
            ? Center(child: Text('No processed requests.'))
            : _buildRequestsList(_processedRequests, isPending: false),
      ],
    );
  }
  
  Widget _buildFirestoreView() {
    // Check if doctorId is available
    if (_doctorId == null) {
      return const Center(
        child: Text('Please log in to view prescription requests.'),
      );
    }
    
    return TabBarView(
      controller: _tabController,
      children: [
        // Pending Tab
        StreamBuilder<QuerySnapshot>(
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
            
            if (!snap.hasData || snap.data == null || snap.data!.docs.isEmpty) {
              return const Center(child: Text('No pending requests.'));
            }
            
            final docs = snap.data!.docs;
            return _buildFirestoreList(docs, isPending: true);
          },
        ),
        
        // Processed Tab
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('prescriptionRequests')
              .where('doctorId', isEqualTo: _doctorId)
              .where('status', whereIn: ['approved', 'declined'])
              .orderBy('handledAt', descending: true)
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snap.hasData || snap.data == null || snap.data!.docs.isEmpty) {
              return const Center(child: Text('No processed requests.'));
            }
            
            final docs = snap.data!.docs;
            return _buildFirestoreList(docs, isPending: false);
          },
        ),
      ],
    );
  }
  
  Widget _buildFirestoreList(List<QueryDocumentSnapshot> docs, {required bool isPending}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final d = docs[i].data() as Map<String, dynamic>;
        final requestedAt = (d['requestedAt'] as Timestamp).toDate();
        final patientName = d['patientName'] as String? ?? 'Patient';
        final prescriptionName = d['name'] as String? ?? '';
        final docId = docs[i].id;
        
        // For processed requests
        final status = d['status'] as String? ?? 'pending';
        final handledAt = d['handledAt'] != null
            ? (d['handledAt'] as Timestamp).toDate()
            : null;
        
        return _buildRequestCard(
          id: docId,
          name: prescriptionName,
          patientName: patientName,
          requestedAt: requestedAt,
          status: status,
          handledAt: handledAt,
          isPending: isPending,
        );
      },
    );
  }
  
  Widget _buildRequestsList(List<Map<String, dynamic>> requests, {required bool isPending}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final req = requests[i];
        
        return _buildRequestCard(
          id: req['id'] as String,
          name: req['name'] as String,
          patientName: req['patientName'] as String,
          requestedAt: req['requestedAt'] as DateTime,
          type: req['type'] as String? ?? 'Unknown',
          notes: req['notes'] as String? ?? '',
          status: req['status'] as String? ?? 'pending',
          handledAt: req['handledAt'] as DateTime?,
          isPending: isPending,
        );
      },
    );
  }
  
  Widget _buildRequestCard({
    required String id,
    required String name,
    required String patientName,
    required DateTime requestedAt,
    required bool isPending,
    String? type,
    String? notes,
    String? status,
    DateTime? handledAt,
  }) {
    // Card appearance based on status
    Color statusColor = _primary;
    IconData statusIcon = Icons.pending;
    
    if (!isPending) {
      if (status == 'approved') {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      } else if (status == 'declined') {
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ),
                if (type != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: type == 'New' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: type == 'New' ? Colors.blue : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey.shade600, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Patient: $patientName',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey.shade600, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Requested: ${DateFormat.yMMMd().add_jm().format(requestedAt)}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
                
                // Show handled time for processed requests
                if (!isPending && handledAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_capitalizeStatus(status ?? "")}: ${DateFormat.yMMMd().add_jm().format(handledAt)}',
                        style: TextStyle(color: statusColor, fontSize: 13),
                      ),
                    ],
                  ),
                ],
                
                // Notes section if available
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.grey.shade600, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Notes:',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notes,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action buttons for pending requests
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _updateRequestStatus(id, 'approved'),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _updateRequestStatus(id, 'declined'),
                          child: Text(
                            'Decline',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateRequestStatus(String requestId, String newStatus) async {
    setState(() => _isLoading = true);
    
    try {
      if (_useHardcodedData) {
        // Simulate API call for hardcoded data
        await Future.delayed(const Duration(milliseconds: 300));
        
        // For demo, move the item from pending to processed
        final index = _pendingRequests.indexWhere((req) => req['id'] == requestId);
        if (index != -1) {
          final request = Map<String, dynamic>.from(_pendingRequests[index]);
          request['status'] = newStatus;
          request['handledAt'] = DateTime.now();
          
          setState(() {
            _pendingRequests.removeAt(index);
            _processedRequests.insert(0, request);
          });
        }
      } else {
        // Real Firestore update
        await _db
            .collection('prescriptionRequests')
            .doc(requestId)
            .update({'status': newStatus, 'handledAt': FieldValue.serverTimestamp()});
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'approved'
                ? 'Prescription request approved.'
                : 'Prescription request declined.',
          ),
          backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red.shade700,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating request: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

  // Helper method to capitalize status text
  String _capitalizeStatus(String text) {
    if (text.isEmpty) return '';
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }