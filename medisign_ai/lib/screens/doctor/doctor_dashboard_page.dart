// lib/screens/doctor/doctor_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../providers/accessibility_provider.dart';
import '../../providers/theme_provider.dart';

// doctor sub-screens (in the same folder)
import 'doctor_appointments_page.dart';
import 'doctor_telemedicine_page.dart';
import 'doctor_conversation_page.dart';
import 'doctor_medical_records_page.dart';
import 'doctor_prescriptions_page.dart';

// other screens
import '../accessibility_settings/accessibility_settings_page.dart';
import '../login/edit_profile_page.dart';
import '../login/login_page.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String doctorName = '';
  String doctorEmail = '';
  String doctorSpecialty = '';
  String doctorProfileUrl = '';
  int pendingAppointments = 0;
  int todayAppointments = 0;
  int totalPatients = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
    _loadDashboardStats();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final acc = Provider.of<AccessibilityProvider>(context, listen: false);
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      acc.loadSettings().then((_) => theme.setTheme(acc.theme));
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadDoctorProfile() async {
    if (_isDisposed) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('doctors').doc(user.uid).get();
      if (_isDisposed) return;
      setState(() {
        doctorEmail = user.email ?? '';
        doctorProfileUrl =
            doc.data()?['photoUrl'] as String? ?? user.photoURL ?? '';
        doctorName = doc.data()?['displayName'] as String? ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'Doctor';
        doctorSpecialty =
            doc.data()?['specialty'] as String? ?? 'General Practice';
      });
    } catch (_) {
      if (_isDisposed) return;
      setState(() {
        doctorName = user.displayName ?? user.email?.split('@')[0] ?? 'Doctor';
        doctorEmail = user.email ?? '';
        doctorSpecialty = 'General Practice';
      });
    }
  }

  Future<void> _loadDashboardStats() async {
    if (_isDisposed) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final pendingQuery = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final todayQuery = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('appointmentDate',
              isLessThan: Timestamp.fromDate(tomorrow))
          .count()
          .get();

      final patientsQuery = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .get();

      final uniquePatients = patientsQuery.docs
          .map((d) => (d.data()['patientId'] as String?))
          .whereType<String>()
          .toSet();

      if (_isDisposed) return;
      setState(() {
        pendingAppointments = pendingQuery.count ?? 0;
        todayAppointments = todayQuery.count ?? 0;
        totalPatients = uniquePatients.length;
      });
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = Provider.of<AccessibilityProvider>(context);
    const primaryColor = Color(0xFF0070BA);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      drawer: _buildDrawer(acc),
      appBar: AppBar(
        title:
            Text('Doctor Dashboard', style: acc.getTextStyle(sizeMultiplier: 1.25)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: doctorProfileUrl.isNotEmpty
                    ? NetworkImage(doctorProfileUrl)
                    : null,
                child: doctorProfileUrl.isEmpty
                    ? const Icon(Icons.person, color: primaryColor)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDoctorProfile();
          await _loadDashboardStats();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenSize.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(acc, primaryColor),
              const SizedBox(height: 24),
              _buildStatsRow(acc),
              const SizedBox(height: 24),
              _buildQuickActions(acc),
              const SizedBox(height: 24),
              _buildRecentAppointments(acc),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AccessibilityProvider acc, Color primaryColor) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: primaryColor.withOpacity(0.1),
            backgroundImage:
                doctorProfileUrl.isNotEmpty ? NetworkImage(doctorProfileUrl) : null,
            child: doctorProfileUrl.isEmpty
                ? Icon(Icons.person, color: primaryColor, size: 40)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. $doctorName',
                      style: acc.getTextStyle(
                          sizeMultiplier: 1.4, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(doctorSpecialty,
                      style: acc.getTextStyle(
                          sizeMultiplier: 1.1, color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text(doctorEmail,
                      style: acc.getTextStyle(color: Colors.grey.shade600)),
                ]),
          )
        ]),
      ),
    );
  }

  Widget _buildStatsRow(AccessibilityProvider acc) {
    return Row(children: [
      Expanded(
        child: _statCard(
            'Today\'s Appointments',
            todayAppointments.toString(),
            Icons.calendar_today,
            Colors.blue,
            acc),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _statCard('Pending Requests', pendingAppointments.toString(),
            Icons.pending_actions, Colors.orange, acc),
      ),
      const SizedBox(width: 12),
      Expanded(
        child:
            _statCard('Total Patients', totalPatients.toString(), Icons.people,
                Colors.green, acc),
      ),
    ]);
  }

  Widget _statCard(String title, String value, IconData icon, Color color,
      AccessibilityProvider acc) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value,
              style:
                  acc.getTextStyle(sizeMultiplier: 1.75, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(title,
              style: acc.getTextStyle(
                  sizeMultiplier: 0.85, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(AccessibilityProvider acc) {
    const primaryColor = Color(0xFF0070BA);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: acc.getTextStyle(sizeMultiplier: 1.25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _actionCard(
              'Appointments',
              Icons.calendar_today,
              Colors.blue,
              'View and manage your appointment schedule',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorAppointmentsPage()),
              ),
              acc,
            ),
            _actionCard(
              'Telemedicine',
              Icons.video_call,
              Colors.purple,
              'Start or join virtual consultations',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorTelemedicinePage()),
              ),
              acc,
            ),
            _actionCard(
              'Patient Conversations',
              Icons.chat,
              Colors.green,
              'Patient-doctor communication',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorConversationPage(doctorName: doctorName),
                ),
              ),
              acc,
            ),
            _actionCard(
              'Medical Records & Prescriptions',
              Icons.medical_services,
              Colors.red,
              'Manage patient records and prescriptions',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorPrescriptionsPage()),
              ),
              acc,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, String desc,
      VoidCallback onTap, AccessibilityProvider acc) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration:
                  BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title,
                style:
                    acc.getTextStyle(sizeMultiplier: 1.1, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(desc,
                  style: acc.getTextStyle(
                      sizeMultiplier: 0.85, color: Colors.grey.shade700),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildRecentAppointments(AccessibilityProvider acc) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _auth.currentUser?.uid)
          .where('status', whereIn: ['confirmed', 'pending'])
          .orderBy('appointmentDate')
          .limit(5)
          .get(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator())),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading appointments',
                  style: acc.getTextStyle(color: Colors.red)),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No upcoming appointments',
                    style: acc.getTextStyle(color: Colors.grey.shade600)),
              ]),
            ),
          );
        }
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Upcoming Appointments',
                    style: acc.getTextStyle(
                        sizeMultiplier: 1.25,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0070BA))),
                TextButton(
                    onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DoctorAppointmentsPage()),
                        ),
                    child: Text('View All',
                        style: acc.getTextStyle(color: const Color(0xFF0070BA)))),
              ]),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final data = doc.data()! as Map<String, dynamic>;
                final date = (data['appointmentDate'] as Timestamp).toDate();
                final patient = data['patientName'] as String? ?? 'Patient';
                final status = data['status'] as String? ?? 'pending';
                final type = data['appointmentType'] as String? ?? 'Consultation';
                final color = status == 'confirmed' ? Colors.green : Colors.orange;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(date.day.toString(),
                            style: acc.getTextStyle(
                                sizeMultiplier: 1.5,
                                fontWeight: FontWeight.bold,
                                color: color)),
                        Text(
                            [
                              '',
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec'
                            ][date.month],
                            style: acc.getTextStyle(color: color)),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient,
                            style: acc.getTextStyle(
                                sizeMultiplier: 1.1, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(type, style: acc.getTextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 4),
                        Text(
                            '${_formatTime(date)} • ${['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][date.weekday-1]}',
                            style: acc.getTextStyle(
                                sizeMultiplier: 0.9, color: Colors.grey.shade600)),
                      ],
                    )),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(status.capitalize(),
                          style: acc.getTextStyle(color: color, sizeMultiplier: 0.85)),
                    ),
                  ]),
                );
              }).toList(),
            ]),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  Drawer _buildDrawer(AccessibilityProvider acc) {
    const primaryColor = Color(0xFF0070BA);
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: primaryColor),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              backgroundImage:
                  doctorProfileUrl.isNotEmpty ? NetworkImage(doctorProfileUrl) : null,
              child:
                  doctorProfileUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
            ),
            const SizedBox(height: 12),
            Text('Dr. $doctorName',
                style:
                    acc.getTextStyle(sizeMultiplier: 1.2, color: Colors.white)),
            Text(doctorSpecialty,
                style:
                    acc.getTextStyle(sizeMultiplier: 0.9, color: Colors.white70)),
          ]),
        ),
        _drawerItem(Icons.dashboard, 'Dashboard', () => Navigator.pop(context), acc),
        _drawerItem(Icons.calendar_today, 'Appointments', () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DoctorAppointmentsPage()));
        }, acc),
        _drawerItem(Icons.video_call, 'Telemedicine', () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DoctorTelemedicinePage()));
        }, acc),
        _drawerItem(Icons.chat, 'Patient Conversations', () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DoctorConversationPage(doctorName: doctorName),
              ));
        }, acc),
        _drawerItem(Icons.folder_shared, 'Medical Records', () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DoctorMedicalRecordsPage()));
        }, acc),
        _drawerItem(Icons.medical_services, 'Prescriptions', () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DoctorPrescriptionsPage()));
        }, acc),
        const Divider(),
        _drawerItem(Icons.settings, 'Accessibility Settings', () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()));
        }, acc),
        _drawerItem(Icons.account_circle, 'Edit Profile', () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()))
            .then((_) => _loadDoctorProfile());
        }, acc),
        _drawerItem(Icons.logout, 'Logout', _handleLogout, acc),
      ]),
    );
  }

  ListTile _drawerItem(
      IconData icon, String label, VoidCallback onTap, AccessibilityProvider acc) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: acc.getTextStyle()),
      onTap: onTap,
    );
  }

  Future<void> _handleLogout() async {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Color(0xFF0070BA))),
    );
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

// small string extension
extension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}