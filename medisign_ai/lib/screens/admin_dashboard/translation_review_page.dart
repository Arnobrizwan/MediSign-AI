import 'package:flutter/material.dart';

class TranslationReviewPage extends StatelessWidget {
  const TranslationReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        title: Text('Translation Accuracy Review', style: TextStyle(color: primaryColor)),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Flagged Translations', primaryColor),
          _placeholderCard('Review Queue, Star Ratings, Correction Forms'),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _placeholderCard(String label) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.checklist, color: Color(0xFFF45B69)),
        title: Text(label),
      ),
    );
  }
}