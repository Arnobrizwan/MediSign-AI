// lib/screens/ambulance/ambulance_dashboard_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/accessibility_provider.dart';
import '../../providers/theme_provider.dart';

class AmbulanceDashboardPage extends StatefulWidget {
  const AmbulanceDashboardPage({Key? key}) : super(key: key);

  @override
  State<AmbulanceDashboardPage> createState() => _AmbulanceDashboardPageState();
}

class _AmbulanceDashboardPageState extends State<AmbulanceDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Hardcoded/demo data with Muslim names
  String _staffName = 'Aisha Khalid';
  String _assignedAmbulanceId = 'AMB-001';
  String _ambulanceStatus = 'OnCall';

  // Stats
  int _totalTripsToday = 3;
  int _activeCallsCount = 1;
  double _averageResponseTime = 7.5;

  // Demo lists
  final List<Map<String, dynamic>> _emergencyCalls = [
    {
      'id': 'call1',
      'patientName': 'Muhammad Hassan',
      'location': '456 Elm St',
      'emergency': 'Severe Allergic Reaction',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
      'status': 'pending',
      'severity': 'critical',
    },
  ];

  final List<Map<String, dynamic>> _recentTrips = [
    {
      'id': 'trip1',
      'patientName': 'Amina Yusuf',
      'startLocation': '789 Oak Ave',
      'destination': 'City Hospital',
      'startTime': DateTime.now().subtract(const Duration(hours: 2)),
      'endTime': DateTime.now().subtract(const Duration(hours:1, minutes: 30)),
      'emergency': 'Stroke',
      'status': 'completed',
      'distance': 4.2,
    },
  ];

  final List<Map<String, dynamic>> _activeIncidents = [
    {
      'id': 'inc1',
      'title': 'Traffic Accident',
      'location': '5th & Pine',
      'description': 'Multiple vehicle collision',
      'reportTime': DateTime.now().subtract(const Duration(minutes: 15)),
      'severity': 'moderate',
      'type': 'accident',
      'resourcesNeeded': ['Tow Truck', 'Fire Unit'],
    },
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load accessibility & theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final acc = Provider.of<AccessibilityProvider>(context, listen: false);
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      acc.loadSettings().then((_) => theme.setTheme(acc.theme));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acc = Provider.of<AccessibilityProvider>(context);
    final primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ambulance Dashboard', style: acc.getTextStyle()),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.emergency), text: 'Emergencies'),
            Tab(icon: Icon(Icons.history), text: 'Recent Trips'),
            Tab(icon: Icon(Icons.warning), text: 'Incidents'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildAmbulanceStatusCard(primaryColor, acc),
                _buildStatsRow(acc),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEmergencyCallsList(acc),
                      _buildRecentTripsList(acc),
                      _buildActiveIncidentsList(acc),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAmbulanceStatusCard(Color primaryColor, AccessibilityProvider acc) {
    Color statusColor;
    IconData statusIcon;
    switch (_ambulanceStatus) {
      case 'Available':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'OnCall':
        statusColor = Colors.orange;
        statusIcon = Icons.directions_car;
        break;
      case 'Maintenance':
        statusColor = Colors.blue;
        statusIcon = Icons.build;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.error;
    }
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.2),
              radius: 24,
              child: Icon(Icons.local_hospital, color: primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ambulance #$_assignedAmbulanceId',
                    style: acc.getTextStyle(fontWeight: FontWeight.bold, sizeMultiplier: 1.1),
                  ),
                  const SizedBox(height: 4),
                  Text('Staff: $_staffName', style: acc.getTextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(_ambulanceStatus,
                      style: acc.getTextStyle(color: statusColor, fontWeight: FontWeight.bold, sizeMultiplier: 0.9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(AccessibilityProvider acc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard('Trips Today', '$_totalTripsToday', Icons.directions, Colors.blue, acc),
          _buildStatCard('Active Calls', '$_activeCallsCount', Icons.phone_in_talk, Colors.orange, acc),
          _buildStatCard('Avg. Response', '${_averageResponseTime.toStringAsFixed(1)} min', Icons.timer, Colors.green, acc),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, AccessibilityProvider acc) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: acc.getTextStyle(fontWeight: FontWeight.bold, sizeMultiplier: 1.2)),
            const SizedBox(height: 4),
            Text(title,
                style: acc.getTextStyle(color: Colors.grey.shade700, sizeMultiplier: 0.8),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCallsList(AccessibilityProvider acc) {
    if (_emergencyCalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_missed, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No emergency calls', style: acc.getTextStyle(color: Colors.grey.shade700)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emergencyCalls.length,
      itemBuilder: (context, index) {
        final call = _emergencyCalls[index];
        final timestamp = call['timestamp'] as DateTime;
        final severity = call['severity'] as String;
        Color sevColor = severity == 'critical' ? Colors.red : (severity == 'moderate' ? Colors.orange : Colors.blue);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: sevColor.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(Icons.priority_high, color: sevColor),
                      ),
                      const SizedBox(width: 12),
                      Text(call['patientName'], style: acc.getTextStyle(fontWeight: FontWeight.bold, sizeMultiplier: 1.1)),
                    ]),
                    Text(DateFormat('h:mm a').format(timestamp),
                        style: acc.getTextStyle(color: Colors.grey.shade600, sizeMultiplier: 0.8)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(call['emergency'], style: acc.getTextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(call['location'],
                        style: acc.getTextStyle(color: Colors.grey.shade700, sizeMultiplier: 0.9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: sevColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text(severity.toUpperCase(),
                      style: acc.getTextStyle(color: sevColor, fontWeight: FontWeight.bold, sizeMultiplier: 0.8)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTripsList(AccessibilityProvider acc) {
    if (_recentTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No recent trips', style: acc.getTextStyle(color: Colors.grey.shade700)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentTrips.length,
      itemBuilder: (context, index) {
        final trip = _recentTrips[index];
        final start = trip['startTime'] as DateTime;
        final end = trip['endTime'] as DateTime?;
        final duration = end != null
            ? end.difference(start).inMinutes
            : DateTime.now().difference(start).inMinutes;
        final isDone = trip['status'] == 'completed';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trip['patientName'], style: acc.getTextStyle(fontWeight: FontWeight.bold, sizeMultiplier: 1.1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDone ? Colors.green : Colors.orange).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(isDone ? 'Completed' : 'In Progress',
                          style: acc.getTextStyle(
                              color: isDone ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                              sizeMultiplier: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(trip['emergency'], style: acc.getTextStyle(fontWeight: FontWeight.w500)),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('From:', style: acc.getTextStyle(color: Colors.grey.shade600, sizeMultiplier: 0.8)),
                        const SizedBox(height: 4),
                        Text(trip['startLocation'], style: acc.getTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('To:', style: acc.getTextStyle(color: Colors.grey.shade600, sizeMultiplier: 0.8)),
                        const SizedBox(height: 4),
                        Text(trip['destination'], style: acc.getTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _infoItem(Icons.access_time, '$duration min', acc),
                  _infoItem(Icons.speed, '${trip['distance'].toStringAsFixed(1)} km', acc),
                  _infoItem(Icons.calendar_today, DateFormat('MMM d, h:mm a').format(start), acc),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveIncidentsList(AccessibilityProvider acc) {
    if (_activeIncidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_problem_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No active incidents', style: acc.getTextStyle(color: Colors.grey.shade700)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeIncidents.length,
      itemBuilder: (context, index) {
        final inc = _activeIncidents[index];
        final time = inc['reportTime'] as DateTime;
        final sev = inc['severity'] as String;
        Color sevColor = sev == 'critical' ? Colors.red : (sev == 'moderate' ? Colors.orange : Colors.blue);
        IconData icon;
        switch (inc['type']) {
          case 'fire': icon = Icons.local_fire_department; break;
          case 'medical': icon = Icons.medical_services; break;
          case 'accident': icon = Icons.car_crash; break;
          default: icon = Icons.warning;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: sevColor.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: sevColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(inc['title'], style: acc.getTextStyle(fontWeight: FontWeight.bold, sizeMultiplier: 1.1)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: sevColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text(sev.toUpperCase(),
                      style: acc.getTextStyle(color: sevColor, fontWeight: FontWeight.bold, sizeMultiplier: 0.8)),
                ),
              ]),
              const SizedBox(height: 8),
              Text('Reported ${DateFormat('h:mm a').format(time)}', style: acc.getTextStyle(color: Colors.grey.shade600, sizeMultiplier: 0.8)),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(child: Text(inc['location'], style: acc.getTextStyle(color: Colors.grey.shade700, sizeMultiplier: 0.9), overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 8),
              Text(inc['description'], style: acc.getTextStyle(sizeMultiplier: 0.9), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      },
    );
  }

  Widget _infoItem(IconData icon, String text, AccessibilityProvider acc) {
    return Row(children: [
      Icon(icon, size: 16, color: Colors.grey.shade600),
      const SizedBox(width: 4),
      Text(text, style: acc.getTextStyle(color: Colors.grey.shade700, sizeMultiplier: 0.8)),
    ]);
  }
}