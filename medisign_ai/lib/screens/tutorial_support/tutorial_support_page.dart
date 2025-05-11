

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TutorialSupportPage extends StatefulWidget {
  const TutorialSupportPage({Key? key}) : super(key: key);

  @override
  State<TutorialSupportPage> createState() => _TutorialSupportPageState();
}

class _TutorialSupportPageState extends State<TutorialSupportPage> {
  final Color primaryColor = const Color(0xFFF45B69);

  // 1) Carousel
  late final PageController _pageController;
  final List<Widget> _slides = [
    _buildSlide('Welcome', 'Learn how to use MediSign AI.'),
    _buildSlide('Edit Profile', 'Customize your display name & picture.'),
    _buildSlide('Conversation',
        'Communicate with doctors via speech, text, or sign.'),
  ];
  int _currentSlide = 0;

  // 2) Videos
  final List<String> _videoUrls = [
    // Replace these URLs with actual publicly‐hosted MP4s!
    'https://example.com/sign_language_demo.mp4',
    'https://example.com/appointment_center_tutorial.mp4',
  ];
  late final List<VideoPlayerController> _videoControllers;
  late final List<ChewieController> _chewieControllers;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // initialize video controllers
    _videoControllers = _videoUrls
        .map((url) => VideoPlayerController.network(url)
          ..initialize().then((_) => setState(() {})))
        .toList();

    _chewieControllers = _videoControllers
        .map((vc) => ChewieController(
              videoPlayerController: vc,
              autoPlay: false,
              looping: false,
            ))
        .toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _chewieControllers) c.dispose();
    for (final v in _videoControllers) v.dispose();
    super.dispose();
  }

  static Widget _buildSlide(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(desc, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _openBluetoothSettings() async {
    // iOS scheme
    const ios = 'app-settings:';
    if (await canLaunchUrl(Uri.parse(ios))) {
      await launchUrl(Uri.parse(ios));
      return;
    }
    // Android fallback
    await launchUrl(
      Uri.parse('bluetooth:'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _openFeedbackForm() {
    String feedbackType = 'Bug';
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: feedbackType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'Bug', child: Text('Bug')),
                DropdownMenuItem(value: 'Suggestion', child: Text('Suggestion')),
                DropdownMenuItem(value: 'Compliment', child: Text('Compliment')),
              ],
              onChanged: (v) => feedbackType = v ?? 'Bug',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              await FirebaseFirestore.instance.collection('feedback').add({
                'userUid': user?.uid,
                'type': feedbackType,
                'description': descCtrl.text,
                'timestamp': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback submitted')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:
            IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Tutorial & Support',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // —— Onboarding carousel —— 
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _currentSlide = i),
                    itemBuilder: (_, i) => _slides[i],
                  ),
                  Positioned(
                    left: 8,
                    top: 100,
                    child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          final prev = _currentSlide - 1;
                          if (prev >= 0) {
                            _pageController.animateToPage(prev,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn);
                          }
                        }),
                  ),
                  Positioned(
                    right: 8,
                    top: 100,
                    child: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          final next = _currentSlide + 1;
                          if (next < _slides.length) {
                            _pageController.animateToPage(next,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn);
                          }
                        }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // —— Videos —— 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Voice-Over Demonstrations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _chewieControllers.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                child: _videoControllers[i].value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoControllers[i].value.aspectRatio,
                        child: Chewie(controller: _chewieControllers[i]),
                      )
                    : Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
              ),
            const SizedBox(height: 24),

            // —— FAQ —— 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('FAQ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            ),
            const SizedBox(height: 8),
            ...[
              ['General', 'This app helps patients communicate using sign, Braille, and text.'],
              ['Sign Language', 'Point the camera clearly at your hands and ensure good lighting.'],
              ['Braille', 'Enable Braille Mode in settings; use compatible hardware if needed.'],
            ].map((qa) => ExpansionTile(
                  title: Text(qa[0]),
                  children: [Padding(padding: const EdgeInsets.all(12), child: Text(qa[1]))],
                )),

            const SizedBox(height: 24),

            // —— Braille Display Pairing —— 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Braille Display Pairing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            ),
            ListTile(
              leading: Icon(Icons.bluetooth, color: primaryColor),
              title: const Text('Pair via Bluetooth settings'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _openBluetoothSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size.fromHeight(45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Open Bluetooth Settings'),
              ),
            ),

            const SizedBox(height: 24),

            // —— Braille On-Screen Guide —— 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Using Braille Mode On-Screen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            ),
            ListTile(
              leading: Icon(Icons.keyboard, color: primaryColor),
              title: const Text('Use virtual Braille keyboard with tap gestures.'),
            ),

            const SizedBox(height: 24),

            // —— Troubleshooting —— 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Troubleshooting Guide',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            ),
            ...[
              'Camera not working → Check permissions.',
              'Mic access denied → Re-enable in system settings.',
              'Translation errors → Check language selection.',
            ].map((step) => ListTile(
                  leading: Icon(Icons.check_circle_outline, color: primaryColor),
                  title: Text(step),
                )),

            const SizedBox(height: 24),

            // —— Contact & Feedback —— 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Contact & Feedback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            ),
            ListTile(
              leading: Icon(Icons.support_agent, color: primaryColor),
              title: const Text('Contact Hospital IT Support'),
              subtitle: const Text('Email: support@hospital.com\nPhone: +60-123-456-789'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _openFeedbackForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size.fromHeight(45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Send Feedback'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}