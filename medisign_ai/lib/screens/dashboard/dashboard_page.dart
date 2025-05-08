import 'package:flutter/material.dart';
import '../login/login_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    String patientName = 'John Doe';
    String patientId = 'P12345';
    String preferredLanguages = 'BIM, English (Text), Braille Output';
    List<String> recentInteractions = [
      'Conversation with Dr. Smith - May 7',
      'AI Check-in - May 6',
    ];
    List<String> savedPhrases = [
      'I need assistance',
      'Please explain again',
    ];
    List<String> badges = [
      '7 Days Check-in Streak!',
      'Learned 10 BIM Phrases!',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Welcome, $patientName!',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/accessibility_settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Patient Profile Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  leading: const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/avatar_placeholder.png'),
                  ),
                  title: Text('ID: $patientId'),
                  subtitle: Text('Preferred: $preferredLanguages'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFF45B69)),
                    onPressed: () {
                      Navigator.pushNamed(context, '/edit_profile');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Main Navigation Grid (including new features)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildNavCard(context, primaryColor, Icons.gesture, 'Translate Sign Language', '/sign_translate'),
                  _buildNavCard(context, primaryColor, Icons.forum, 'Patient-Doctor Conversation', '/conversation_mode'),
                  _buildNavCard(context, primaryColor, Icons.history, 'Medical Transcript History', '/transcript_history'),
                  _buildNavCard(context, primaryColor, Icons.health_and_safety, 'AI Health Check-In', '/health_checkin'),
                  _buildNavCard(context, primaryColor, Icons.video_call, 'Telemedicine Consultations', '/telemedicine'),
                  _buildNavCard(context, primaryColor, Icons.school, 'Learn & Practice', '/learning_gamified'),
                  _buildNavCard(context, primaryColor, Icons.local_hospital, 'Hospital Services', '/patient_locator'),
                  _buildNavCard(context, primaryColor, Icons.help_outline, 'Tutorial & Support', '/tutorial_support'),
                  _buildNavCard(context, primaryColor, Icons.family_restroom, 'Family & Caregiver Portal', '/family_portal'),
                  _buildNavCard(context, primaryColor, Icons.calendar_today, 'Appointments', '/appointments'),
                  _buildNavCard(context, primaryColor, Icons.folder_shared, 'My Health Records', '/health_records'),
                  _buildNavCard(context, primaryColor, Icons.medical_services, 'Prescriptions', '/prescriptions'),
                  _buildNavCard(context, primaryColor, Icons.map, 'Hospital Guide & Wayfinding', '/hospital_guide'),
                  _buildNavCard(context, primaryColor, Icons.payment, 'Bills & Payments', '/bills_payments'),
                ],
              ),
              const SizedBox(height: 20),

              // Recent Interactions
              _buildSectionHeader('Recent Interactions', primaryColor),
              ...recentInteractions.map((item) => ListTile(
                    title: Text(item),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/transcript_history');
                    },
                  )),
              const SizedBox(height: 20),

              // Saved Phrases
              _buildSectionHeader('Saved Phrases', primaryColor),
              Wrap(
                spacing: 8,
                children: savedPhrases.map((phrase) {
                  return ActionChip(
                    label: Text(phrase),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied: $phrase')),
                      );
                    },
                    backgroundColor: Colors.grey.shade200,
                  );
                }).toList(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/transcript_history');
                  },
                  child: const Text('View All Saved', style: TextStyle(color: Color(0xFFF45B69))),
                ),
              ),
              const SizedBox(height: 20),

              // Medication Reminder
              _buildSectionHeader('Medication Reminder', primaryColor),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  title: const Text('Upcoming: Vitamin D at 8:00 PM'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Confirm Taken'),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Snooze'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Health Progress & Badges
              _buildSectionHeader('Your Progress', primaryColor),
              ...badges.map((badge) => ListTile(
                    leading: const Icon(Icons.emoji_events, color: Color(0xFFF45B69)),
                    title: Text(badge),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard(BuildContext context, Color color, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }
}