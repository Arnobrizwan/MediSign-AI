import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? chartUrls;
  bool isLoading = true;

  final Color primaryColor = const Color(0xFFF45B69);

  final Map<String, IconData> iconMap = {
    'gesture': Icons.gesture,
    'chat': Icons.chat,
    'history': Icons.history,
    'health': Icons.health_and_safety,
    'video': Icons.video_call,
    'school': Icons.school,
    'hospital': Icons.local_hospital,
    'help': Icons.help,
    'group': Icons.group,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final chartsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('dashboardCharts')
          .doc('charts')
          .get();

      setState(() {
        userData = userDoc.data();
        chartUrls = chartsDoc.data();
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> handleLogout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${userData?['displayName'] ?? 'Patient'}!'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings')),
          IconButton(icon: const Icon(Icons.logout), onPressed: handleLogout),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildChartSection('Progress Tracking', chartUrls?['progressChart']),
            _buildChartSection('Recent Interactions', chartUrls?['interactionChart']),
            _buildChartSection('Medication Overview', chartUrls?['medicationChart']),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final items = [
      {'label': 'Translate Sign Language', 'icon': 'gesture', 'route': '/translate'},
      {'label': 'Patient-Doctor Conversation', 'icon': 'chat', 'route': '/conversation'},
      {'label': 'Medical History', 'icon': 'history', 'route': '/history'},
      {'label': 'AI Health Check-In', 'icon': 'health', 'route': '/checkin'},
      {'label': 'Telemedicine', 'icon': 'video', 'route': '/telemedicine'},
      {'label': 'Learn & Practice', 'icon': 'school', 'route': '/learn'},
      {'label': 'Hospital Services', 'icon': 'hospital', 'route': '/services'},
      {'label': 'Tutorial & Support', 'icon': 'help', 'route': '/tutorial'},
      {'label': 'Family Portal', 'icon': 'group', 'route': '/family'},
    ];

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 30, backgroundImage: userData?['photoUrl'] != null ? NetworkImage(userData!['photoUrl']) : null),
                const SizedBox(height: 8),
                Text(userData?['displayName'] ?? 'Patient', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(userData?['email'] ?? '', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ...items.map((item) => ListTile(
                leading: Icon(iconMap[item['icon'].toString()] ?? Icons.help, color: primaryColor),
                title: Text(item['label'].toString()),
                onTap: () => Navigator.pushNamed(context, item['route'].toString()),
              )),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(radius: 30, backgroundImage: userData?['photoUrl'] != null ? NetworkImage(userData!['photoUrl']) : null),
        title: Text(userData?['displayName'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('ID: ${userData?['patientId'] ?? 'N/A'}'),
        trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.pushNamed(context, '/editProfile')),
      ),
    );
  }

  Widget _buildChartSection(String title, String? imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 200,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                  )
                : const Center(child: Text('No chart available')),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}