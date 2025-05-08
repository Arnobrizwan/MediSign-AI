import 'package:flutter/material.dart';

class LearningGamifiedPage extends StatelessWidget {
  const LearningGamifiedPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Learn & Practice',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Mini Tutorials', primaryColor),
          _tutorialCard('BIM Basics'),
          _tutorialCard('BISINDO Common Phrases'),
          _tutorialCard('Introduction to Braille Reading'),
          _tutorialCard('Braille Writing'),

          const SizedBox(height: 24),
          _sectionHeader('Daily Challenges & Interactive Tasks', primaryColor),
          _challengeCard('Today\'s Challenge: Sign "Hello, How Are You?"'),
          _challengeCard('Braille Speed Typing Test'),
          _challengeCard('Translate These 5 Phrases'),

          const SizedBox(height: 24),
          _sectionHeader('Rewards & Achievements', primaryColor),
          _badgeRow(['BIM Alphabet Master', 'Braille Beginner Pro', '7-Day Learning Streak']),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.6,
            backgroundColor: Colors.grey.shade300,
            color: primaryColor,
            minHeight: 10,
          ),
          const SizedBox(height: 8),
          const Center(child: Text('60% towards next achievement')),

          const SizedBox(height: 24),
          _sectionHeader('Creative Communication', primaryColor),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Emoji Communication Board...')),
              );
            },
            icon: const Icon(Icons.emoji_emotions),
            label: const Text('Emoji-Based Communication Board'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Drawing Pad...')),
              );
            },
            icon: const Icon(Icons.brush),
            label: const Text('Drawing/Sketch Pad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _tutorialCard(String title) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.play_circle_fill, color: Color(0xFFF45B69)),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate to detailed tutorial (placeholder)
        },
      ),
    );
  }

  Widget _challengeCard(String title) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.flash_on, color: Color(0xFFF45B69)),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate to challenge (placeholder)
        },
      ),
    );
  }

  Widget _badgeRow(List<String> badges) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges
          .map((badge) => Chip(
                label: Text(badge),
                backgroundColor: Colors.grey.shade200,
              ))
          .toList(),
    );
  }
}