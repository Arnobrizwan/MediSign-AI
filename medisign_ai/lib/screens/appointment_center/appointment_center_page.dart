// lib/screens/appointment_center/appointment_center_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentCenterPage extends StatefulWidget {
  const AppointmentCenterPage({Key? key}) : super(key: key);

  @override
  State<AppointmentCenterPage> createState() => _AppointmentCenterPageState();
}

class _AppointmentCenterPageState extends State<AppointmentCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _primaryColor = const Color(0xFFF45B69);
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // — Form state for Book New —
  String? _bookDept;
  String? _bookDoctor;
  String? _bookType;
  DateTime _bookDate = DateTime.now().add(const Duration(days: 1));
  final _reasonCtrl = TextEditingController();

  // — Reminder prefs —
  bool _remindersOn = false;
  int _reminderMins = 30;
  final _reminderOptions = [5, 15, 30, 60];

  // A static list of doctors for the dropdown
  final List<String> _allDoctors = [
    'Dr. Mim',
    'Dr. Lee',
    'Dr. Aziz',
    'Dr. Chen',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReminderPrefs();
  }

  Future<void> _loadReminderPrefs() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('appointmentReminders')
        .get();
    if (doc.exists) {
      final d = doc.data()!;
      setState(() {
        _remindersOn = d['enabled'] as bool? ?? false;
        _reminderMins = d['reminderMinutes'] as int? ?? _reminderMins;
      });
    }
  }

  Future<void> _saveReminderPrefs() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('appointmentReminders')
        .set({
      'enabled': _remindersOn,
      'reminderMinutes': _reminderMins,
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  /// Pull booking logic into its own method
  Future<void> _confirmBooking() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final displayName = user.displayName ?? user.uid;

    if (_bookDept == null || _bookType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick specialty & type')),
      );
      return;
    }

    await _firestore.collection('appointments').add({
      'userid': displayName,
      'speciality': _bookDept,
      'doctorName': _bookDoctor,
      'type': _bookType,
      'location': 'Wing B, Level 3',
      'dateTime': Timestamp.fromDate(_bookDate),
      'reminderMinutes': _reminderMins,
      'status': 'Confirmed',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booked successfully')),
    );

    setState(() {
      _bookDept = null;
      _bookDoctor = null;
      _bookType = null;
      _bookDate = DateTime.now().add(const Duration(days: 1));
      _reasonCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
          body: Center(child: Text('Please sign in to view appointments')));
    }
    final displayName = user.displayName ?? user.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appointment Center',
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primaryColor,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Book New'),
            Tab(text: 'Reminders'),
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
                .where('userid', isEqualTo: displayName)
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              final now = DateTime.now();
              final upcomingDocs = docs.where((d) {
                final ts = (d['dateTime'] as Timestamp).toDate();
                return ts.isAfter(now);
              }).toList();

              if (upcomingDocs.isEmpty) {
                return const Center(child: Text('No upcoming appointments'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: upcomingDocs.length,
                itemBuilder: (_, i) => _appointmentCard(upcomingDocs[i]),
              );
            },
          ),

          // ─── Past ──────────────────────────────────────
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Two sample past entries for testing
              _pastAppointmentCard({
                'doctorName': 'Dr. Mim',
                'dateTime': Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(days: 2))),
                'notes': 'Follow-up notes here'
              }),
              _pastAppointmentCard({
                'doctorName': 'Dr. Mim',
                'dateTime': Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(days: 10))),
                'notes': null
              }),
            ],
          ),

          // ─── Book New ──────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDropdown<String>(
                  label: 'Specialty',
                  value: _bookDept,
                  items: ['Cardiology', 'Neurology', 'Oncology'],
                  onChanged: (v) => setState(() => _bookDept = v),
                ),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  label: 'Doctor (opt.)',
                  value: _bookDoctor,
                  items: _allDoctors,
                  onChanged: (v) => setState(() => _bookDoctor = v),
                ),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  label: 'Type',
                  value: _bookType,
                  items: ['Consultation', 'Follow-up', 'Lab Test'],
                  onChanged: (v) => setState(() => _bookType = v),
                ),
                const SizedBox(height: 12),

                // Date & Time picker styled like a filled input
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date & Time',
                    hintText: DateFormat.yMd().add_jm().format(_bookDate),
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onTap: () async {
                    final dt = await showDatePicker(
                      context: context,
                      initialDate: _bookDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (dt != null) {
                      final tm = await showTimePicker(
                        context: context,
                        initialTime:
                            TimeOfDay.fromDateTime(_bookDate),
                      );
                      if (tm != null) {
                        setState(() {
                          _bookDate = DateTime(
                            dt.year, dt.month, dt.day, tm.hour, tm.minute);
                        });
                      }
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Reason field with same filled style
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reason (opt.)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _confirmBooking,
                  child: const Text('Confirm Booking'),
                ),
              ],
            ),
          ),

          // ─── Reminders ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Reminders'),
                  value: _remindersOn,
                  activeColor: _primaryColor,
                  onChanged: (v) {
                    setState(() => _remindersOn = v);
                    _saveReminderPrefs();
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdown<int>(
                  label: 'Minutes before',
                  value: _reminderMins,
                  items: _reminderOptions,
                  onChanged: (v) {
                    setState(() => _reminderMins = v!);
                    _saveReminderPrefs();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      value: items.contains(value) ? value : null,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _appointmentCard(QueryDocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    final dt = (d['dateTime'] as Timestamp).toDate();
    final status = d['status'] as String? ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          '${d['doctorName'] ?? ''} • ${d['type'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${DateFormat.yMMMd().add_jm().format(dt)}\n'
          '${d['location'] ?? ''}\n'
          'Status: $status',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (choice) async {
            if (choice == 'Reschedule' || choice == 'Cancel') {
              final newStatus =
                  choice == 'Reschedule' ? 'Rescheduled' : 'Cancelled';
              await doc.reference.update({'status': newStatus});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Marked $newStatus')),
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'Details', child: Text('View Details')),
            PopupMenuItem(value: 'Reschedule', child: Text('Reschedule')),
            PopupMenuItem(value: 'Cancel', child: Text('Cancel')),
          ],
        ),
      ),
    );
  }

  Widget _pastAppointmentCard(Map<String, dynamic> d) {
    final dt = (d['dateTime'] as Timestamp).toDate();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          d['doctorName'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(DateFormat.yMMMd().add_jm().format(dt)),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(v))),
          itemBuilder: (_) {
            final hasNotes = (d['notes'] != null);
            return [
              if (hasNotes)
                const PopupMenuItem(value: 'Summary', child: Text('View Summary')),
              const PopupMenuItem(value: 'Follow-Up', child: Text('Book Follow-Up')),
            ];
          },
        ),
      ),
    );
  }
}