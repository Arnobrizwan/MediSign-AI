import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  Map<String, dynamic>? userData;
  List<dynamic> recentInteractions = [];
  List<dynamic> savedPhrases = [];
  List<dynamic> medicationReminders = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    user = _auth.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final interactions = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('interactions')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    final phrases = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('savedPhrases')
        .get();

    final reminders = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('medications')
        .where('upcoming', isEqualTo: true)
        .get();

    setState(() {
      userData = doc.data();
      recentInteractions = interactions.docs.map((d) => d.data()).toList();
      savedPhrases = phrases.docs.map((d) => d.data()).toList();
      medicationReminders = reminders.docs.map((d) => d.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${userData?['displayName'] ?? 'Patient'}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildNavigationGrid(),
          const SizedBox(height: 16),
          _buildSectionTitle('Recent Interactions'),
          ...recentInteractions.map((item) => ListTile(
                title: Text(item['summary'] ?? 'Interaction'),
                subtitle: Text(item['date'] ?? ''),
                onTap: () {
                  Navigator.pushNamed(context, '/transcript', arguments: item);
                },
              )),
          const SizedBox(height: 16),
          _buildSectionTitle('Saved Phrases'),
          Wrap(
            spacing: 8,
            children: savedPhrases
                .map((phrase) => ActionChip(
                      label: Text(phrase['text'] ?? ''),
                      onPressed: () {
                        // Copy or use phrase
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Medication Reminders'),
          ...medicationReminders.map((med) => ListTile(
                title: Text('${med['name']} at ${med['time']}'),
                trailing: ElevatedButton(
                  child: const Text('Confirm Taken'),
                  onPressed: () {
                    // Confirm taken action
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: userData?['photoUrl'] != null
                  ? NetworkImage(userData!['photoUrl'])
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userData?['displayName'] ?? 'Patient',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('ID: ${userData?['patientId'] ?? 'N/A'}'),
                  Text('Languages: ${userData?['preferredLanguages']?.join(', ') ?? 'N/A'}'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(context, '/editProfile');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationGrid() {
    final items = [
      {'label': 'Translate Sign Language', 'icon': Icons.gesture, 'route': '/translate'},
      {'label': 'Patient-Doctor Conversation', 'icon': Icons.chat, 'route': '/conversation'},
      {'label': 'Medical History', 'icon': Icons.history, 'route': '/history'},
      {'label': 'AI Health Check-In', 'icon': Icons.health_and_safety, 'route': '/checkin'},
      {'label': 'Telemedicine', 'icon': Icons.video_call, 'route': '/telemedicine'},
      {'label': 'Learn & Practice', 'icon': Icons.school, 'route': '/learn'},
      {'label': 'Hospital Services', 'icon': Icons.local_hospital, 'route': '/services'},
      {'label': 'Tutorial & Support', 'icon': Icons.help, 'route': '/tutorial'},
      {'label': 'Family Portal', 'icon': Icons.group, 'route': '/family'},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 3 / 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF45B69),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.pushNamed(context, item['route']);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'], size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(item['label'], style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }
}