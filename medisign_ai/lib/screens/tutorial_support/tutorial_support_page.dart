import 'package:flutter/material.dart';

class TutorialSupportPage extends StatelessWidget {
  const TutorialSupportPage({super.key});

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
          'Tutorial & Support',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionHeader('Step-by-Step User Onboarding', primaryColor),
            _carouselPlaceholder(),
            const SizedBox(height: 16),

            _sectionHeader('Voice-Over Demonstration Videos', primaryColor),
            _videoPlaceholder('Sign Language Recognition Demo'),
            _videoPlaceholder('Accessible Appointment Center Tutorial'),
            _videoPlaceholder('Navigating the Medical Records Hub'),
            _videoPlaceholder('Managing Prescriptions & Refills'),
            _videoPlaceholder('Using Hospital Wayfinding Features'),
            _videoPlaceholder('Making Accessible Payments'),
            const SizedBox(height: 16),

            _sectionHeader('FAQ', primaryColor),
            _faqTile('General', 'This app helps patients communicate using sign, Braille, and text.'),
            _faqTile('Sign Language', 'Point the camera clearly at your hands and ensure good lighting.'),
            _faqTile('Braille', 'Enable Braille Mode in settings; use compatible hardware if needed.'),
            _faqTile('Appointments', 'Visit the Appointment Center to view, book, or manage your appointments.'),
            _faqTile('Prescriptions', 'Go to the Prescriptions section to request refills or check status.'),
            _faqTile('Wayfinding', 'Use the Hospital Guide to find accessible routes, quiet areas, or wheelchair paths.'),
            _faqTile('Payments', 'Access the Payments section for secure, accessible billing.'),
            const SizedBox(height: 16),

            _sectionHeader('Braille Display Pairing Instructions', primaryColor),
            _simpleGuide('1. Turn on your Braille device.'),
            _simpleGuide('2. Open your phone Bluetooth settings.'),
            _simpleGuide('3. Select the device from the list to pair.'),
            ElevatedButton(
              onPressed: () {},
              style: _buttonStyle(primaryColor),
              child: const Text('Open Bluetooth Settings'),
            ),
            const SizedBox(height: 16),

            _sectionHeader('Using Braille Mode On-Screen', primaryColor),
            _simpleGuide('• Tap virtual Braille dots on screen.'),
            _simpleGuide('• Use swipe gestures for space, backspace, and enter.'),
            const SizedBox(height: 16),

            _sectionHeader('Troubleshooting Guide', primaryColor),
            _simpleGuide('• Camera not working → Check app permissions.'),
            _simpleGuide('• Mic access denied → Re-enable mic permissions in system settings.'),
            _simpleGuide('• Translation errors → Ensure correct language selection.'),
            _simpleGuide('• Accessibility features not responding → Restart the app.'),
            const SizedBox(height: 16),

            _sectionHeader('Contact & Feedback', primaryColor),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Color(0xFFF45B69)),
              title: const Text('Contact Hospital IT Support'),
              subtitle: const Text('Email: support@hospital.com\nPhone: +60-123-456-789'),
            ),
            ElevatedButton(
              onPressed: () {
                _openFeedbackForm(context);
              },
              style: _buttonStyle(primaryColor),
              child: const Text('Send Feedback'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _carouselPlaceholder() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Text('Onboarding Carousel Placeholder')),
    );
  }

  Widget _videoPlaceholder(String label) {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ondemand_video, size: 40, color: Colors.black54),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(answer),
        ),
      ],
    );
  }

  Widget _simpleGuide(String step) {
    return ListTile(
      leading: const Icon(Icons.check_circle_outline, color: Color(0xFFF45B69)),
      title: Text(step),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size.fromHeight(45),
    );
  }

  void _openFeedbackForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Feedback Type'),
              items: const [
                DropdownMenuItem(value: 'Bug', child: Text('Bug')),
                DropdownMenuItem(value: 'Suggestion', child: Text('Suggestion')),
                DropdownMenuItem(value: 'Compliment', child: Text('Compliment')),
              ],
              onChanged: (val) {},
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback submitted')),
                );
              },
              style: _buttonStyle(const Color(0xFFF45B69)),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}