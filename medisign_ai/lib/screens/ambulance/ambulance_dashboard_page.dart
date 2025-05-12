// lib/screens/ambulance/ambulance_dashboard_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/accessibility_provider.dart';
import '../../providers/theme_provider.dart';
import '../login/login_page.dart';

class AmbulanceDashboardPage extends StatefulWidget {
  const AmbulanceDashboardPage({Key? key}) : super(key: key);

  @override
  State<AmbulanceDashboardPage> createState() => _AmbulanceDashboardPageState();
}

class _AmbulanceDashboardPageState extends State<AmbulanceDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User data variables - will be filled from Firebase if available
  String _staffName = 'Aisha Khalid'; // Default value
  String _staffEmail = 'aisha.khalid@medisign.com'; // Default value
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
    {
      'id': 'call2',
      'patientName': 'Fatima Rahman',
      'location': '789 Cedar Ave',
      'emergency': 'Chest Pain',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 25)),
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
    {
      'id': 'trip2',
      'patientName': 'Ibrahim Khan',
      'startLocation': '123 Main St',
      'destination': 'Memorial Hospital',
      'startTime': DateTime.now().subtract(const Duration(hours: 4)),
      'endTime': DateTime.now().subtract(const Duration(hours: 3, minutes: 40)),
      'emergency': 'Car Accident',
      'status': 'completed',
      'distance': 6.8,
    },
    {
      'id': 'trip3',
      'patientName': 'Zahra Ahmed',
      'startLocation': '567 Pine Rd',
      'destination': 'General Hospital',
      'startTime': DateTime.now().subtract(const Duration(hours: 6)),
      'endTime': DateTime.now().subtract(const Duration(hours: 5, minutes: 25)),
      'emergency': 'Pregnancy',
      'status': 'completed',
      'distance': 3.5,
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
    {
      'id': 'inc2',
      'title': 'Building Fire',
      'location': '450 Maple Street',
      'description': 'Small commercial building fire',
      'reportTime': DateTime.now().subtract(const Duration(minutes: 30)),
      'severity': 'critical',
      'type': 'fire',
      'resourcesNeeded': ['Fire Truck', 'Ambulance'],
    },
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load user data from Firebase
    _loadUserData();

    // Load accessibility & theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final acc = Provider.of<AccessibilityProvider>(context, listen: false);
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      acc.loadSettings().then((_) => theme.setTheme(acc.theme));
    });
  }
  
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get email from Firebase Auth
        if (user.email != null && user.email!.isNotEmpty) {
          setState(() => _staffEmail = user.email!);
        }
        
        // Try to get additional data from Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            setState(() {
              // Use data from Firestore if available, otherwise keep defaults
              _staffName = userData['displayName'] as String? ?? 
                          user.displayName ?? 
                          _staffName;
              
              // If there's ambulance-specific data
              if (userData.containsKey('assignedAmbulanceId')) {
                _assignedAmbulanceId = userData['assignedAmbulanceId'] as String? ?? _assignedAmbulanceId;
              }
              
              if (userData.containsKey('ambulanceStatus')) {
                _ambulanceStatus = userData['ambulanceStatus'] as String? ?? _ambulanceStatus;
              }
            });
          }
        } else {
          // If no Firestore document exists but we have displayName from Auth
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            setState(() => _staffName = user.displayName!);
          }
        }
      }
    } catch (e) {
      // On error, we'll just use the hardcoded defaults
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      await _auth.signOut();
      if (!mounted) return;
      
      Navigator.pop(context); // Close loading dialog
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const LoginPage())
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = Provider.of<AccessibilityProvider>(context);
    final primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ambulance Dashboard', 
          style: acc.getTextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing data...'))
              );
              // Reload user data and refresh UI
              _loadUserData().then((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data refreshed'))
                  );
                }
              });
            }
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: _buildDrawer(acc, primaryColor),
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

  Widget _buildDrawer(AccessibilityProvider acc, Color primaryColor) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.local_hospital, size: 30, color: primaryColor),
                ),
                const SizedBox(height: 10),
                Text(
                  _staffName,
                  style: acc.getTextStyle(
                    sizeMultiplier: 1.2,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _staffEmail,
                  style: acc.getTextStyle(
                    color: Colors.white70,
                    sizeMultiplier: 0.9,
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: () => Navigator.pop(context),
            acc: acc,
          ),
          _drawerItem(
            icon: Icons.notifications,
            label: 'Alerts & Notifications',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alerts coming soon')),
              );
            },
            acc: acc,
          ),
          _drawerItem(
            icon: Icons.calendar_today,
            label: 'Schedule',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Schedule coming soon')),
              );
            },
            acc: acc,
          ),
          _drawerItem(
            icon: Icons.map,
            label: 'Maps & Navigation',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Maps coming soon')),
              );
            },
            acc: acc,
          ),
          _drawerItem(
            icon: Icons.inventory,
            label: 'Inventory',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inventory coming soon')),
              );
            },
            acc: acc,
          ),
          const Divider(),
          _drawerItem(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
            acc: acc,
          ),
          _drawerItem(
            icon: Icons.help,
            label: 'Help & Support',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help coming soon')),
              );
            },
            acc: acc,
          ),
          _drawerItem(
            icon: Icons.logout,
            label: 'Logout',
            onTap: _handleLogout,
            acc: acc,
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AccessibilityProvider acc,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: acc.getTextStyle()),
      onTap: onTap,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: acc.getTextStyle(fontWeight: FontWeight.bold, sizeMultiplier: 1.2)),
              const SizedBox(height: 4),
              Text(title,
                  style: acc.getTextStyle(color: Colors.grey.shade700, sizeMultiplier: 0.8),
                  textAlign: TextAlign.center),
            ],
          ),
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
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Handle emergency call tap
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Responding to ${call['patientName']}\'s emergency'))
              );
            },
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: sevColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: Text(severity.toUpperCase(),
                            style: acc.getTextStyle(color: sevColor, fontWeight: FontWeight.bold, sizeMultiplier: 0.8)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Handle response button
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Responding to ${call['patientName']}\'s emergency'))
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sevColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Respond'),
                      ),
                    ],
                  ),
                ],
              ),
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
              Text(inc['description'], style: acc.getTextStyle(sizeMultiplier: 0.9)),
              const SizedBox(height: 12),
              
              // Display resources needed
              if (inc.containsKey('resourcesNeeded') && (inc['resourcesNeeded'] as List).isNotEmpty) ...[
                const Divider(height: 24),
                Text('Resources Needed:', style: acc.getTextStyle(fontWeight: FontWeight.w500, sizeMultiplier: 0.9)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (inc['resourcesNeeded'] as List).map((resource) => 
                    Chip(
                      backgroundColor: sevColor.withOpacity(0.1),
                      label: Text(resource.toString(), 
                        style: acc.getTextStyle(color: sevColor, sizeMultiplier: 0.8)
                      ),
                    )
                  ).toList(),
                ),
              ],
              
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('View Map'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening map for ${inc['location']}'))
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Responding to incident at ${inc['location']}'))
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sevColor,
                    ),
                    child: const Text('Respond'),
                  ),
                ],
              ),
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