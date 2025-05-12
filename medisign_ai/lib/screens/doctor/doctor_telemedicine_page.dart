// lib/screens/telemedicine/doctor_telemedicine_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;         // for web-only iframe
import 'dart:ui' as ui;             // for platform view registry

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorTelemedicinePage extends StatefulWidget {
  const DoctorTelemedicinePage({Key? key}) : super(key: key);

  @override
  State<DoctorTelemedicinePage> createState() => _DoctorTelemedicinePageState();
}

class _DoctorTelemedicinePageState extends State<DoctorTelemedicinePage> {
  bool _inCall = false;
  final String _roomName = 'consult';  
  final String _apiKey = '9ae30efd1d8b91afe901d72da2142f53fad4a767105ae9c02014544c34ec3637';
  late final String _iframeUrl;
  bool _isProvisioning = true;
  String? _error;

  // will load upcoming patients for this doctor:
  List<Map<String, dynamic>> _todayAppointments = [];
  List<Map<String, dynamic>> _previousSessions = [];

  @override
  void initState() {
    super.initState();
    _iframeUrl = Uri.https('msai.daily.co', '/$_roomName', {'t': _apiKey}).toString();
    _provisionRoom();
    _loadAppointments();
  }

  Future<void> _provisionRoom() async {
    await _ensureRoomExists();
    setState(() => _isProvisioning = false);
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory('daily-iframe', (int viewId) {
        final el = html.IFrameElement()
          ..src = _iframeUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return el;
      });
    }
  }

  Future<void> _ensureRoomExists() async {
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    final getRes = await http.get(Uri.https('api.daily.co', '/v1/rooms/$_roomName'), headers: headers);
    if (getRes.statusCode == 200) return;
    if (getRes.statusCode == 404) {
      final createRes = await http.post(
        Uri.https('api.daily.co', '/v1/rooms'),
        headers: headers,
        body: jsonEncode({'name': _roomName}),
      );
      if (createRes.statusCode != 200 && createRes.statusCode != 201) {
        _error = 'Failed to create room: ${createRes.body}';
      }
      return;
    }
    _error = 'Error checking room: ${getRes.body}';
  }

  Future<void> _loadAppointments() async {
    final doc = FirebaseAuth.instance.currentUser;
    if (doc == null) return;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Upcoming today's appointments
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doc.uid)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('appointmentDate')
        .get();

    _todayAppointments = snap.docs.map((d) {
      final data = d.data();
      return {
        'patientName': data['patientName'] ?? 'Patient',
        'time': (data['appointmentDate'] as Timestamp).toDate(),
        'appointmentId': d.id,
      };
    }).toList();

    // Load last 5 sessions
    final prevSnap = await FirebaseFirestore.instance
        .collection('conversations')
        .where('doctorUid', isEqualTo: doc.uid)
        .where('status', isEqualTo: 'closed_by_doctor')
        .orderBy('endedAt', descending: true)
        .limit(5)
        .get();

    _previousSessions = prevSnap.docs.map((d) {
      final data = d.data();
      return {
        'patientName': data['patientName'] ?? 'Patient',
        'endedAt': (data['endedAt'] as Timestamp).toDate(),
      };
    }).toList();

    setState(() {});
  }

  void _toggleCall() {
    setState(() => _inCall = !_inCall);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFF45B69);

    if (_isProvisioning) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Telemedicine'),
          backgroundColor: Colors.white,
          elevation: 1,
          leading: BackButton(color: primaryColor),
        ),
        body: Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_inCall) _toggleCall();
            else Navigator.pop(context);
          },
        ),
        title: Text(
          _inCall ? 'In Call ($_roomName)' : 'Telemedicine Sessions',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: _inCall
            ? [
                TextButton(
                  onPressed: _toggleCall,
                  child: const Text('End Call', style: TextStyle(color: Color(0xFFF45B69))),
                )
              ]
            : null,
      ),
      body: _inCall ? _buildCallView() : _buildDashboard(primaryColor),
    );
  }

  Widget _buildDashboard(Color primary) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Today's Appointments
      const Text('Today\'s Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (_todayAppointments.isEmpty)
        const Text('No appointments for today.')
      else
        ..._todayAppointments.map((a) {
          final time = a['time'] as DateTime;
          final timeStr = '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}';
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(a['patientName']),
              subtitle: Text(timeStr),
              trailing: ElevatedButton(
                onPressed: _toggleCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start'),
              ),
            ),
          );
        }),
      const SizedBox(height: 24),

      // Previous Sessions
      const Text('Recent Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (_previousSessions.isEmpty)
        const Text('No recent sessions.')
      else
        ..._previousSessions.map((s) {
          final dt = s['endedAt'] as DateTime;
          final dateStr = '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(s['patientName']),
            subtitle: Text(dateStr),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Review session with ${s['patientName']}')),
            ),
          );
        }),
    ]);
  }

  Widget _buildCallView() {
    if (!kIsWeb) {
      return const Center(child: Text('Video calls only supported on web.'));
    }
    return const HtmlElementView(viewType: 'daily-iframe');
  }
}