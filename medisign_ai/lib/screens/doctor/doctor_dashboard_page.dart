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
  
  // Using hardcoded values instead of starting with zeros
  int pendingAppointments = 8;
  int todayAppointments = 5;
  int totalPatients = 42;

  bool _loadingProfile = true;
  bool _loadingStats = true;
  bool _loadingAppointments = true;

  // Demo fallback for upcoming
  final List<Map<String, dynamic>> _hardcodedAppointments = [
    {
      'patientName': 'Sarah Johnson',
      'appointmentDate': DateTime.now().add(const Duration(hours: 2)),
      'appointmentType': 'Check-up',
      'status': 'confirmed',
    },
    {
      'patientName': 'Michael Brown',
      'appointmentDate': DateTime.now().add(const Duration(hours: 4)),
      'appointmentType': 'Follow-up',
      'status': 'confirmed',
    },
    {
      'patientName': 'Emily Davis',
      'appointmentDate': DateTime.now().add(const Duration(days: 1)),
      'appointmentType': 'Consultation',
      'status': 'pending',
    },
    {
      'patientName': 'Robert Wilson',
      'appointmentDate': DateTime.now().add(const Duration(days: 1, hours: 3)),
      'appointmentType': 'Laboratory Results',
      'status': 'pending',
    },
    {
      'patientName': 'Jennifer Taylor',
      'appointmentDate': DateTime.now().add(const Duration(days: 2)),
      'appointmentType': 'Prescription Renewal',
      'status': 'confirmed',
    },
  ];
  List<Map<String, dynamic>> _upcomingAppointments = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
    _loadDashboardStats();
    _loadUpcomingAppointments();

    // accessibility + theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final acc = Provider.of<AccessibilityProvider>(context, listen: false);
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      acc.loadSettings().then((_) => theme.setTheme(acc.theme));
    });
  }

  Future<void> _loadDoctorProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('doctors').doc(user.uid).get();
      final data = doc.data() ?? {};
      setState(() {
        doctorEmail = user.email ?? '';
        doctorProfileUrl = data['photoUrl'] as String? ?? user.photoURL ?? '';
        doctorName = data['displayName'] as String? ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'Doctor';
        doctorSpecialty = data['specialty'] as String? ?? 'General Practice';
      });
    } catch (e) {
      // silent fallback to basic auth info
      setState(() {
        doctorEmail = user.email ?? '';
        doctorProfileUrl = user.photoURL ?? '';
        doctorName = user.displayName ?? 'Doctor';
        doctorSpecialty = 'General Practice';
      });
    } finally {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadDashboardStats() async {
    // We're using hardcoded values, but still simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _loadingStats = false);
    
    // The original Firebase code is kept but not used since we're using hardcoded values
    // This would normally fetch real data from Firestore
  }

  Future<void> _loadUpcomingAppointments() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _upcomingAppointments = _hardcodedAppointments;
        _loadingAppointments = false;
      });
      return;
    }
    try {
      final snap = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('status', whereIn: ['confirmed', 'pending'])
          .orderBy('appointmentDate')
          .limit(5)
          .get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'patientName': d['patientName'] as String? ?? 'Patient',
          'appointmentDate': (d['appointmentDate'] as Timestamp).toDate(),
          'appointmentType': d['appointmentType'] as String? ?? 'Consultation',
          'status': d['status'] as String? ?? 'pending',
        };
      }).toList();
      setState(() {
        _upcomingAppointments = list.isNotEmpty ? list : _hardcodedAppointments;
      });
    } catch (_) {
      setState(() {
        _upcomingAppointments = _hardcodedAppointments;
      });
    } finally {
      setState(() => _loadingAppointments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = Provider.of<AccessibilityProvider>(context);
    const primaryColor = Color(0xFFF45B69);
    final size = MediaQuery.of(context).size;

    // overall loading if any
    final loading = _loadingProfile || _loadingStats || _loadingAppointments;
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: _buildDrawer(acc),
      appBar: AppBar(
        title: Text('Welcome, $doctorName', style: acc.getTextStyle(sizeMultiplier: 1.25)),
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
          await Future.wait([
            _loadDoctorProfile(),
            _loadDashboardStats(),
            _loadUpcomingAppointments(),
          ]);
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsRow(acc),
              const SizedBox(height: 24),
              _buildQuickActions(acc),
              const SizedBox(height: 24),
              _buildUpcomingSection(acc, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(AccessibilityProvider acc) {
    return Row(children: [
      Expanded(child: _statCard("Today's Appointments", todayAppointments.toString(), Icons.calendar_today, Colors.blue, acc)),
      const SizedBox(width: 12),
      Expanded(child: _statCard('Pending', pendingAppointments.toString(), Icons.pending_actions, Colors.orange, acc)),
      const SizedBox(width: 12),
      Expanded(child: _statCard('Patients', totalPatients.toString(), Icons.people, Colors.green, acc)),
    ]);
  }

  Widget _statCard(String title, String value, IconData icon, Color color, AccessibilityProvider acc) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value, style: acc.getTextStyle(fontWeight: FontWeight.bold, sizeMultiplier: 1.5)),
          const SizedBox(height: 4),
          Text(title, style: acc.getTextStyle(color: Colors.grey.shade700)),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(AccessibilityProvider acc) {
    const primaryColor = Color(0xFFF45B69);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Quick Actions', style: acc.getTextStyle(sizeMultiplier: 1.2, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      // Changed to a ListView instead of GridView to create rectangular cards
      SizedBox(
        height: 120, // Fixed height for the row of rectangles
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _actionCard('Appointments', Icons.calendar_today, primaryColor, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorAppointmentsPage()));
            }, acc),
            _actionCard('Telemedicine', Icons.video_call, primaryColor, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorTelemedicinePage()));
            }, acc),
            _actionCard('Conversations', Icons.chat, primaryColor, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorConversationPage(doctorName: doctorName)));
            }, acc),
            _actionCard('Records', Icons.folder_open, primaryColor, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorMedicalRecordsPage()));
            }, acc),
          ],
        ),
      ),
    ]);
  }

  Widget _actionCard(String label, IconData icon, Color color, VoidCallback onTap, AccessibilityProvider acc) {
    // Changed from square to rectangle shape
    return Container(
      width: 160, // Fixed width to make it rectangular
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: acc.getTextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(AccessibilityProvider acc, Color primaryColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Upcoming Appointments', style: acc.getTextStyle(sizeMultiplier: 1.2, fontWeight: FontWeight.bold, color: primaryColor)),
      const SizedBox(height: 12),
      ..._upcomingAppointments.map((appt) {
        final dt = appt['appointmentDate'] as DateTime;
        final status = appt['status'] as String;
        final badgeColor = status == 'confirmed' ? Colors.green : Colors.orange;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: badgeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text('${dt.day}', style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appt['patientName'], style: acc.getTextStyle(fontWeight: FontWeight.bold)),
              Text(appt['appointmentType'], style: acc.getTextStyle(color: Colors.grey.shade700)),
              Text('${_formatTime(dt)}', style: acc.getTextStyle(color: Colors.grey.shade600, sizeMultiplier: 0.9)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Text(status.capitalize(), style: acc.getTextStyle(color: badgeColor)),
            ),
          ]),
        );
      }).toList(),
    ]);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  Drawer _buildDrawer(AccessibilityProvider acc) {
    const primaryColor = Color(0xFFF45B69);
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: primaryColor),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              backgroundImage: doctorProfileUrl.isNotEmpty ? NetworkImage(doctorProfileUrl) : null,
              child: doctorProfileUrl.isEmpty ? const Icon(Icons.person, size: 32, color: primaryColor) : null,
            ),
            const SizedBox(height: 12),
            Text(doctorName, style: acc.getTextStyle(sizeMultiplier: 1.2, color: Colors.white)),
            Text(doctorSpecialty, style: acc.getTextStyle(sizeMultiplier: 0.9, color: Colors.white70)),
          ]),
        ),
        _drawerItem(Icons.dashboard, 'Dashboard', () => Navigator.pop(context), acc),
        _drawerItem(Icons.calendar_today, 'Appointments', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorAppointmentsPage()));
        }, acc),
        _drawerItem(Icons.video_call, 'Telemedicine', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorTelemedicinePage()));
        }, acc),
        _drawerItem(Icons.chat, 'Conversations', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorConversationPage(doctorName: doctorName)));
        }, acc),
        _drawerItem(Icons.folder_open, 'Records', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorMedicalRecordsPage()));
        }, acc),
        _drawerItem(Icons.medical_services, 'Prescriptions', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorPrescriptionsPage()));
        }, acc),
        const Divider(),
        _drawerItem(Icons.settings, 'Accessibility', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()));
        }, acc),
        _drawerItem(Icons.account_circle, 'Edit Profile', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()))
              .then((_) => _loadDoctorProfile());
        }, acc),
        _drawerItem(Icons.logout, 'Logout', _handleLogout, acc),
      ]),
    );
  }

  ListTile _drawerItem(IconData icon, String label, VoidCallback onTap, AccessibilityProvider acc) {
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
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF45B69))),
    );
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error signing out: $e'), backgroundColor: Colors.red));
    }
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}