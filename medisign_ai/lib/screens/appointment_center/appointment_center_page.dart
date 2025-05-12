import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    await _firestore.collection('appointments').add({
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
      'status': 'Confirmed',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booked successfully')),
    );
    setState(() {
      _bookCountry = null;
      _bookHospital = null;
      _bookDept = null;
      _bookDoctor = null;
      _bookType = null;
      _bookDate = DateTime.now().add(const Duration(days: 1));
      _remindersOn = false;
      _reminderMins = 30;
      _reasonCtrl.clear();
    });
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
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        '${d['hospital']}\n'
                        '${d['doctorName']} • ${d['type']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${DateFormat.yMMMd().add_jm().format(dt)}\n'
                        'Status: ${d['status']}',
                      ),
                      isThreeLine: true,
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
                    }),
                    _pastAppointmentCard({
                      'doctorName': 'Dr. Chen',
                      'dateTime': Timestamp.fromDate(
                          DateTime.now().subtract(const Duration(days: 14))),
                      'notes': 'Lab Test: All within normal range.',
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
                  'Doctor (optional)',
                  _bookDoctor,
                  _bookHospital == null
                      ? []
                      : _doctorsByHospital[_bookHospital!] ?? [],
                  (v) => setState(() => _bookDoctor = v),
                ),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  'Type',
                  _bookType,
                  _types,
                  (v) => setState(() => _bookType = v),
                ),
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
                // Align “Set a reminder” fully left
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
                // Full-width buttons
                ElevatedButton(
                  onPressed: _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm Booking'),
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
  child: const Text('Pay Bill'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          d['doctorName'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${DateFormat.yMMMd().add_jm().format(dt)}'
          '${notes != null ? '\nNotes: $notes' : ''}',
        ),
        isThreeLine: notes != null,
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