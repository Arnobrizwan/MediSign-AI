// lib/screens/telemedicine/telemedicine_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;         // for web-only iframe
import 'dart:ui' as ui;             // for platform view registry

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TelemedicinePage extends StatefulWidget {
  const TelemedicinePage({Key? key}) : super(key: key);

  @override
  State<TelemedicinePage> createState() => _TelemedicinePageState();
}

class _TelemedicinePageState extends State<TelemedicinePage> {
  bool _inCall = false;
  final String _roomName = 'consult';
  final String _apiKey = '9ae30efd1d8b91afe901d72da2142f53fad4a767105ae9c02014544c34ec3637';
  late final String _iframeUrl;
  bool _isProvisioning = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iframeUrl = Uri.https(
      'msai.daily.co',
      '/$_roomName',
      {'t': _apiKey},
    ).toString();

    // provision the room, then unhide UI
    _ensureRoomExists().whenComplete(() {
      setState(() => _isProvisioning = false);
      // register the iframe factory (web only)
      if (kIsWeb) {
        // ignore: undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(
          'daily-iframe',
          (int viewId) {
            final el = html.IFrameElement()
              ..src = _iframeUrl
              ..style.border = 'none'
              ..style.width = '100%'
              ..style.height = '100%';
            return el;
          },
        );
      }
    });
  }

  Future<void> _ensureRoomExists() async {
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    // 1) Try GET /rooms/{name}
    final getRes = await http.get(
      Uri.https('api.daily.co', '/v1/rooms/$_roomName'),
      headers: headers,
    );
    if (getRes.statusCode == 200) return;

    // 2) If 404, create it
    if (getRes.statusCode == 404) {
      final createRes = await http.post(
        Uri.https('api.daily.co', '/v1/rooms'),
        headers: headers,
        body: jsonEncode({
          'name': _roomName,
          // optional: you can set properties here
          // 'properties': {'enable_recording': true}
        }),
      );
      if (createRes.statusCode != 200 && createRes.statusCode != 201) {
        _error = 'Failed to create room: ${createRes.body}';
      }
      return;
    }

    // any other error
    _error = 'Error checking room: ${getRes.body}';
  }

  void _toggleCall() {
    setState(() => _inCall = !_inCall);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFF45B69);

    // while we’re provisioning/showing error:
    if (_isProvisioning) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Telemedicine'), backgroundColor: Colors.white, elevation: 1, leading: BackButton(color: primaryColor)),
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
          _inCall ? 'Telemedicine Call ($_roomName)' : 'Telemedicine Consultations',
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
      body: _inCall ? _buildWebCallView() : _buildPreCallScreen(primaryColor),
    );
  }

  Widget _buildPreCallScreen(Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Upcoming Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _appointmentCard('Dr. Mim', 'Today at 3:00 PM', primaryColor),
        const SizedBox(height: 12),
        _appointmentCard('Dr. Helal', 'Tomorrow at 11:00 AM', primaryColor),
      ],
    );
  }

  Widget _appointmentCard(String doctor, String time, Color primaryColor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.grey),
        title: Text(doctor),
        subtitle: Text(time),
        trailing: ElevatedButton(
          onPressed: _toggleCall,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            minimumSize: const Size(100, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Join Call'),
        ),
      ),
    );
  }

  Widget _buildWebCallView() {
    if (!kIsWeb) {
      return const Center(child: Text('Video calls only supported on web in this demo.'));
    }
    return const HtmlElementView(viewType: 'daily-iframe');
  }
}