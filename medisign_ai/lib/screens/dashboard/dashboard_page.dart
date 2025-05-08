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
  Map<String, dynamic>? progressData;
  List<dynamic> recentInteractions = [];
  List<dynamic> importantTranscripts = [];
  List<dynamic> savedPhrases = [];
  List<dynamic> medicationReminders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> handleLogout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _loadUserData() async {
    try {
      user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

      final interactionsSnap = await FirebaseFirestore.instance
          .collection('interactions')
          .doc(user!.uid)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final importantSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('importantTranscripts')
          .get();

      final phrasesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('savedPhrases')
          .get();

      final medsSnap = await FirebaseFirestore.instance
          .collection('medications')
          .doc(user!.uid)
          .collection('reminders')
          .where('status', isEqualTo: 'Scheduled')
          .orderBy('scheduledTime')
          .get();

      final progressDoc = await FirebaseFirestore.instance
          .collection('progress')
          .doc(user!.uid)
          .get();

      setState(() {
        userData = userDoc.data();
        progressData = progressDoc.data();
        recentInteractions = interactionsSnap.docs.map((d) => d.data()).toList();
        importantTranscripts = importantSnap.docs.map((d) => d.data()).toList();
        savedPhrases = phrasesSnap.docs.map((d) => d.data()).toList();
        medicationReminders = medsSnap.docs.map((d) => {
          ...d.data(),
          'reminderId': d.id,
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load data. Please try again later.')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final langs = (userData?['preferredLanguages'] as List<dynamic>?) ?? [];
    final langString = langs.isNotEmpty ? langs.join(', ') : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${userData?['displayName'] ?? 'Patient'}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: handleLogout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(langString),
          const SizedBox(height: 16),
          _buildNavigationGrid(),
          const SizedBox(height: 16),
          _buildSectionTitle('Progress Tracking'),
          _buildProgressSection(),
          const SizedBox(height: 16),
          _buildSectionTitle('Recent Interactions'),
          _buildInteractionList(recentInteractions),
          const SizedBox(height: 16),
          _buildSectionTitle('Important Transcripts'),
          _buildInteractionList(importantTranscripts),
          const SizedBox(height: 16),
          _buildSectionTitle('Saved Phrases'),
          _buildSavedPhrases(),
          const SizedBox(height: 16),
          _buildSectionTitle('Medication Reminders'),
          _buildMedicationReminders(),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String langString) {
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
                  Text('Languages: $langString'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.pushNamed(context, '/editProfile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    if (progressData == null) {
      return const Text('No progress data available.');
    }

    final steps = progressData?['stepsCompleted'] ?? 0;
    final streak = progressData?['checkinStreak'] ?? 0;
    final badges = (progressData?['badges'] as List<dynamic>? ?? []).join(', ');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Steps Completed: $steps'),
            const SizedBox(height: 4),
            Text('Check-in Streak: $streak days'),
            const SizedBox(height: 4),
            Text('Badges: ${badges.isNotEmpty ? badges : 'None'}'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInteractionList(List<dynamic> list) {
    if (list.isEmpty) {
      return const Text('No data available.');
    }
    return Column(
      children: list.map((item) {
        return ListTile(
          title: Text(item['summary'] ?? 'No summary'),
          subtitle: Text(item['timestamp'] != null
              ? (item['timestamp'] as Timestamp).toDate().toLocal().toString()
              : ''),
          onTap: () {
            Navigator.pushNamed(context, '/transcript', arguments: item);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSavedPhrases() {
    if (savedPhrases.isEmpty) {
      return const Text('No saved phrases yet.');
    }
    return Wrap(
      spacing: 8,
      children: savedPhrases.map((phrase) {
        return ActionChip(
          label: Text(phrase['text'] ?? ''),
          onPressed: () {
            // TODO: Add copy or insert logic
          },
        );
      }).toList(),
    );
  }

  Widget _buildMedicationReminders() {
    if (medicationReminders.isEmpty) {
      return const Text('No upcoming medications.');
    }
    return Column(
      children: medicationReminders.map((med) {
        return ListTile(
          title: Text('${med['name']} at ${med['scheduledTime']}'),
          trailing: ElevatedButton(
            child: const Text('Confirm Taken'),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('medications')
                  .doc(user!.uid)
                  .collection('reminders')
                  .doc(med['reminderId'])
                  .update({'status': 'Taken'});
              _loadUserData();
            },
          ),
        );
      }).toList(),
    );
  }
}