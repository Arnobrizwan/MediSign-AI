import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../billing/billing_page.dart';
 

class AppointmentCenterPage extends StatefulWidget {
  const AppointmentCenterPage({Key? key}) : super(key: key);

  @override
  _AppointmentCenterPageState createState() => _AppointmentCenterPageState();
}

class _AppointmentCenterPageState extends State<AppointmentCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _reasonCtrl = TextEditingController();
  final Color _primaryColor = const Color(0xFFF45B69);

  // — Book New form state —
  String? _bookCountry;
  String? _bookHospital;
  String? _bookDept;
  String? _bookDoctor;
  String? _bookType;
  DateTime _bookDate = DateTime.now().add(const Duration(days: 1));
  bool _remindersOn = false;
  int _reminderMins = 30;
  double _appointmentFee = 0.0;

  final _countries = ['Malaysia', 'Indonesia'];
  final _hospitalsByCountry = {
    'Malaysia': [
      'Hospital Sultanah Aminah (Johor Bahru)',
      'KPJ Pasir Gudang',
      'Sultan Ismail Hospital',
    ],
    'Indonesia': [
      'RSUP Dr. Hasan Sadikin',
      'RS Pondok Indah',
      'RS Mitra Keluarga',
    ],
  };

  final _doctorsByHospital = {
    'Hospital Sultanah Aminah (Johor Bahru)': ['Dr. Mim', 'Dr. Aziz'],
    'KPJ Pasir Gudang': ['Dr. Lee', 'Dr. Chen'],
    'Sultan Ismail Hospital': ['Dr. Lim', 'Dr. Tan'],
    'RSUP Dr. Hasan Sadikin': ['Dr. Budi', 'Dr. Sari'],
    'RS Pondok Indah': ['Dr. Dewi', 'Dr. Ari'],
    'RS Mitra Keluarga': ['Dr. Agus', 'Dr. Maya'],
  };

  // Doctor fees map
  final _doctorFees = {
    'Dr. Mim': 120.00,
    'Dr. Aziz': 150.00,
    'Dr. Lee': 200.00,
    'Dr. Chen': 180.00,
    'Dr. Lim': 160.00,
    'Dr. Tan': 190.00,
    'Dr. Budi': 100.00,
    'Dr. Sari': 110.00,
    'Dr. Dewi': 130.00,
    'Dr. Ari': 140.00,
    'Dr. Agus': 120.00,
    'Dr. Maya': 160.00,
  };

  final _types = ['Consultation', 'Follow-up', 'Lab Test'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
  final user = _auth.currentUser;
  if (user == null) return;

  if (_bookHospital == null || _bookDept == null || _bookType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please complete all required fields.')),
    );
    return;
  }

  // Generate appointment ID for reference
  final appointmentId = 'APT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

  // Show payment options dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Appointment Fee: RM ${_appointmentFee.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Doctor: $_bookDoctor'),
          const SizedBox(height: 4),
          Text('Hospital: $_bookHospital'),
          const SizedBox(height: 4),
          Text('Date: ${DateFormat.yMMMd().add_jm().format(_bookDate)}'),
          const SizedBox(height: 16),
          const Text('Would you like to pay now?', 
            style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              // Save appointment with "Pending Payment" status
              await _firestore.collection('appointments').doc(appointmentId).set({
                'id': appointmentId,
                'userid': user.uid,
                'country': _bookCountry,
                'hospital': _bookHospital,
                'speciality': _bookDept,
                'doctorName': _bookDoctor,
                'type': _bookType,
                'dateTime': Timestamp.fromDate(_bookDate),
                'reminderOn': _remindersOn,
                'reminderMinutes': _reminderMins,
                'reason': _reasonCtrl.text,
                'status': 'Pending Payment',
                'fee': _appointmentFee,
              });

              // Add to outstanding bills in payment service
              // Direct access to singleton
              final paymentService = PaymentService.instance;
              final newBill = {
                'id': appointmentId,
                'amount': _appointmentFee,
                'due': DateFormat.yMMMd().format(DateTime.now().add(const Duration(days: 7))),
                'description': 'Appointment with $_bookDoctor at $_bookHospital',
              };
              
              // Make sure this call actually adds the bill
              paymentService.addBill(user.uid, newBill);
              
              // Debug output to verify bill was added
              print('Added bill to outstanding bills. Current count: ${paymentService.getOutstandingBills(user.uid).length}');

              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment booked - Payment pending'),
                  backgroundColor: Color(0xFFF45B69),
                ),
              );
              
              // Reset form
              _resetForm();
              
              // Close dialog
              Navigator.of(ctx).pop();
              
              // Force update UI to reflect the changes
              setState(() {});
              
              // Navigate to the billing page to show the outstanding bill
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BillingPage(patientId: user.uid),
                ),
              );
            } catch (e) {
              // Add error handling
              print('Error in Pay Later: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Pay Later', 
            style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              // Save appointment with "Pending Payment" status first
              // (we'll update it to confirmed after successful payment)
              await _firestore.collection('appointments').doc(appointmentId).set({
                'id': appointmentId,
                'userid': user.uid,
                'country': _bookCountry,
                'hospital': _bookHospital,
                'speciality': _bookDept,
                'doctorName': _bookDoctor,
                'type': _bookType,
                'dateTime': Timestamp.fromDate(_bookDate),
                'reminderOn': _remindersOn,
                'reminderMinutes': _reminderMins,
                'reason': _reasonCtrl.text,
                'status': 'Pending Payment', // Will be updated to Confirmed after payment
                'fee': _appointmentFee,
              });
              
              // Close dialog
              Navigator.of(ctx).pop();
              
              // Reset form
              _resetForm();
              
              // Navigate to payment page
              _proceedToPayment(user.uid, appointmentId, _appointmentFee, 
                'Appointment with $_bookDoctor at $_bookHospital');
            } catch (e) {
              print('Error in Pay Now: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Pay Now',
            style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
  void _resetForm() {
    setState(() {
      _bookCountry = null;
      _bookHospital = null;
      _bookDept = null;
      _bookDoctor = null;
      _bookType = null;
      _bookDate = DateTime.now().add(const Duration(days: 1));
      _remindersOn = false;
      _reminderMins = 30;
      _appointmentFee = 0.0;
      _reasonCtrl.clear();
    });
  }

 void _proceedToPayment(String patientId, String invoiceId, double amount, String description) {
  // Navigate to payment page with ChangeNotifierProvider to prevent Provider errors
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: PaymentService.instance,
        child: AppointmentPaymentPage(
          patientId: patientId,
          invoiceId: invoiceId,
          amount: amount,
          description: description,
        ),
      ),
    ),
  );
}

  Future<void> _pickDateTime() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _bookDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (dt != null) {
      final tm = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_bookDate),
      );
      if (tm != null) {
        setState(() {
          _bookDate = DateTime(dt.year, dt.month, dt.day, tm.hour, tm.minute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Please sign in'));
    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Center',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Book New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── Upcoming ─────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('appointments')
                .where('userid', isEqualTo: uid)
                .snapshots(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());

              final docs = snap.data!.docs;
              final now = DateTime.now();
              final upcoming = docs.where((d) {
                final dt = (d['dateTime'] as Timestamp).toDate();
                return dt.isAfter(now);
              }).toList();
              if (upcoming.isEmpty)
                return const Center(child: Text('No upcoming appointments'));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: upcoming.length,
                itemBuilder: (_, i) {
                  final d = upcoming[i].data()! as Map<String, dynamic>;
                  final dt = (d['dateTime'] as Timestamp).toDate();
                  final status = d['status'] as String;
                  final fee = d['fee'] as double? ?? 0.0;
                  
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${d['hospital']}\n'
                                  '${d['doctorName']} • ${d['type']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'Confirmed' 
                                    ? Colors.green.shade50 
                                    : _primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: status == 'Confirmed' 
                                      ? Colors.green.shade700 
                                      : _primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat.yMMMd().add_jm().format(dt),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (fee > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Fee: RM ${fee.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          
                          if (status == 'Pending Payment') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BillingPage(patientId: uid),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: _primaryColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('View Bill', 
                                      style: TextStyle(color: Color(0xFFF45B69))),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _proceedToPayment(
                                        uid, 
                                        d['id'] as String, 
                                        fee,
                                        'Appointment with ${d['doctorName']} at ${d['hospital']}',
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Pay Now', 
                                      style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ─── Past ──────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('appointments')
                .where('userid', isEqualTo: uid)
                .snapshots(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());

              final docs = snap.data!.docs;
              final now = DateTime.now();
              final past = docs.where((d) {
                final dt = (d['dateTime'] as Timestamp).toDate();
                return dt.isBefore(now);
              }).toList();

              if (past.isEmpty) {
                // two hard-coded entries
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _pastAppointmentCard({
                      'doctorName': 'Dr. Mim',
                      'dateTime': Timestamp.fromDate(
                          DateTime.now().subtract(const Duration(days: 7))),
                      'notes': 'Follow-up: Reviewed blood test.',
                      'status': 'Completed',
                      'fee': 120.00,
                    }),
                    _pastAppointmentCard({
                      'doctorName': 'Dr. Chen',
                      'dateTime': Timestamp.fromDate(
                          DateTime.now().subtract(const Duration(days: 14))),
                      'notes': 'Lab Test: All within normal range.',
                      'status': 'Completed',
                      'fee': 180.00,
                    }),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: past.length,
                itemBuilder: (_, i) {
                  final d = past[i].data()! as Map<String, dynamic>;
                  return _pastAppointmentCard(d);
                },
              );
            },
          ),

          // ─── Book New ──────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Country & Hospital
                _buildDropdown<String>(
                  'Country',
                  _bookCountry,
                  _countries,
                  (v) {
                    setState(() {
                      _bookCountry = v;
                      _bookHospital = null;
                      _bookDoctor = null;
                      _appointmentFee = 0.0;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  'Hospital',
                  _bookHospital,
                  _bookCountry == null
                      ? []
                      : _hospitalsByCountry[_bookCountry!]!,
                  (v) {
                    setState(() {
                      _bookHospital = v;
                      _bookDoctor = null;
                      _appointmentFee = 0.0;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Specialty & Doctor
                _buildDropdown<String>(
                  'Specialty',
                  _bookDept,
                  ['Cardiology', 'Neurology', 'Oncology'],
                  (v) => setState(() => _bookDept = v),
                ),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  'Doctor',
                  _bookDoctor,
                  _bookHospital == null
                      ? []
                      : _doctorsByHospital[_bookHospital!] ?? [],
                  (v) => setState(() {
                    _bookDoctor = v;
                    _appointmentFee = v != null ? _doctorFees[v] ?? 0.0 : 0.0;
                  }),
                ),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  'Type',
                  _bookType,
                  _types,
                  (v) => setState(() => _bookType = v),
                ),
                
                // Appointment Fee display
                if (_appointmentFee > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Appointment Fee:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'RM ${_appointmentFee.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                // Date & Time picker
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date & Time',
                    hintText: DateFormat.yMd().add_jm().format(_bookDate),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 12),
                // Reason
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reason (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),

                const SizedBox(height: 16),
                // Align "Set a reminder" fully left
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Set a reminder'),
                    Switch(
                      value: _remindersOn,
                      activeColor: _primaryColor,
                      onChanged: (v) => setState(() => _remindersOn = v),
                    ),
                  ],
                ),
                if (_remindersOn) ...[
                  const SizedBox(height: 8),
                  _buildDropdown<int>(
                    'Minutes before',
                    _reminderMins,
                    [5, 15, 30, 60],
                    (v) => setState(() => _reminderMins = v!),
                  ),
                ],

                const SizedBox(height: 24),
                // Confirm booking button
                ElevatedButton(
                  onPressed: _bookDoctor != null ? _confirmBooking : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    final uid = _auth.currentUser?.uid ?? '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BillingPage(patientId: uid),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View My Bills'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pastAppointmentCard(Map<String, dynamic> d) {
    final dt = (d['dateTime'] as Timestamp).toDate();
    final notes = d['notes'] as String?;
    final fee = d['fee'] as double? ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  d['doctorName'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'RM ${fee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat.yMMMd().add_jm().format(dt),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (notes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: $notes',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            if (d['hospital'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '${d['hospital']}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(
      String label, T? value, List<T> items, ValueChanged<T?> onChanged) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      value: items.contains(value) ? value : null,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// Dedicated Appointment Payment Page
class AppointmentPaymentPage extends StatefulWidget {
  final String patientId;
  final String invoiceId;
  final double amount;
  final String description;
  
  const AppointmentPaymentPage({
    Key? key,
    required this.patientId,
    required this.invoiceId,
    required this.amount,
    required this.description,
  }) : super(key: key);

  @override
  _AppointmentPaymentPageState createState() => _AppointmentPaymentPageState();
}

class _AppointmentPaymentPageState extends State<AppointmentPaymentPage> {
  final Color _primaryColor = const Color(0xFFF45B69);
  bool _processingPayment = false;
  String _selectedPaymentMethod = 'Credit Card';
  
  final List<String> _paymentMethods = [
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Google Pay'
  ];
  
  Future<void> _processPayment() async {
  setState(() {
    _processingPayment = true;
  });
  
  try {
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    // Direct access to singleton instead of using Provider
    final paymentService = PaymentService.instance;
    paymentService.processPayment(
      widget.patientId,
      widget.invoiceId,
      widget.amount,
      _selectedPaymentMethod,
    );
    
    // Update appointment status to Confirmed
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.invoiceId)
        .update({
      'status': 'Confirmed',
    });
    
    if (mounted) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
              const SizedBox(width: 8),
              const Text('Payment Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice: ${widget.invoiceId}'),
              const SizedBox(height: 4),
              Text('Amount: RM ${widget.amount.toStringAsFixed(2)}'),
              const SizedBox(height: 4),
              Text('Date: ${DateFormat.yMMMd().format(DateTime.now())}'),
              const SizedBox(height: 16),
              const Text('Your appointment has been confirmed!'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Navigate back to appointment center
                Navigator.of(context).pop();
                
                // Optional: Show payment history
                // You could navigate to payment history here if you want
                /*
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BillingPage(
                      patientId: widget.patientId,
                      initialSection: 'paymentHistory',
                    ),
                  ),
                );
                */
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _processingPayment = false;
      });
    }
  }
}
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
      ),
      body: _processingPayment
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Processing payment...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Payment summary card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Invoice ID:'),
                              Text(
                                widget.invoiceId,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Description:'),
                              Flexible(
                                child: Text(
                                  widget.description,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Date:'),
                              Text(
                                DateFormat.yMMMd().format(DateTime.now()),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'RM ${widget.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Payment method selection
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // List of payment methods
                  ...List.generate(
                    _paymentMethods.length,
                    (index) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _selectedPaymentMethod == _paymentMethods[index]
                              ? _primaryColor
                              : Colors.grey.shade300,
                          width: _selectedPaymentMethod == _paymentMethods[index] ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = _paymentMethods[index];
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                _getPaymentIcon(_paymentMethods[index]),
                                color: _selectedPaymentMethod == _paymentMethods[index]
                                    ? _primaryColor
                                    : Colors.grey.shade600,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _paymentMethods[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: _selectedPaymentMethod == _paymentMethods[index]
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _selectedPaymentMethod == _paymentMethods[index]
                                        ? _primaryColor
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              Radio(
                                value: _paymentMethods[index],
                                groupValue: _selectedPaymentMethod,
                                activeColor: _primaryColor,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value as String;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Pay now button
                  ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Complete Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Cancel button
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Credit Card':
        return Icons.credit_card;
      case 'Debit Card':
        return Icons.credit_card;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'Google Pay':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }
} 