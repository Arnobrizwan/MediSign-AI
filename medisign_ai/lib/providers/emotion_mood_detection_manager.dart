import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

// Service class for the overlay that appears when emotion is detected
class EmotionMoodOverlay extends StatelessWidget {
  final String detectedMood;
  final VoidCallback onShowCalming;
  final VoidCallback onConnectHelpline;
  final VoidCallback onAlertCaregiver;
  final VoidCallback onDismiss;
  
  const EmotionMoodOverlay({
    super.key,
    required this.detectedMood,
    required this.onShowCalming,
    required this.onConnectHelpline,
    required this.onAlertCaregiver,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color primaryColor = const Color(0xFFF45B69);
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getMoodIcon(detectedMood, primaryColor),
            const SizedBox(height: 12),
            Text(
              'It seems like you might be feeling $detectedMood.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Would you like some help?',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onShowCalming,
              icon: const Icon(Icons.self_improvement),
              label: const Text('Yes, show calming suggestions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onConnectHelpline,
              icon: const Icon(Icons.phone),
              label: const Text('Connect to Helpline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onAlertCaregiver,
              icon: const Icon(Icons.warning),
              label: const Text('Alert Caregiver/Staff'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onDismiss,
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _getMoodIcon(String mood, Color color) {
    IconData iconData;
    
    switch (mood.toLowerCase()) {
      case 'sad':
      case 'depressed':
      case 'unhappy':
        iconData = Icons.sentiment_very_dissatisfied;
        break;
      case 'anxious':
      case 'worried':
      case 'nervous':
        iconData = Icons.psychology;
        break;
      case 'angry':
      case 'frustrated':
        iconData = Icons.mood_bad;
        break;
      case 'distressed':
      case 'overwhelmed':
        // Fixed: replaced non-existent icon with valid ones
        iconData = Icons.warning_amber;
        break;
      default:
        iconData = Icons.face;
    }
    
    return Icon(iconData, color: color, size: 48);
  }
}

// Manager class to handle the emotion detection system
class EmotionMoodDetectionManager {
  static final EmotionMoodDetectionManager _instance = EmotionMoodDetectionManager._internal();
  
  factory EmotionMoodDetectionManager() {
    return _instance;
  }
  
  EmotionMoodDetectionManager._internal();
  
  bool _isEnabled = false;
  String _helplineNumber = "+0123456789"; // Default number
  String _caregiverContact = ""; // Default is empty
  Timer? _analysisTimer;
  
  // Initialize from saved preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('emotion_detection_enabled') ?? false;
    _helplineNumber = prefs.getString('helpline_number') ?? _helplineNumber;
    _caregiverContact = prefs.getString('caregiver_contact') ?? _caregiverContact;
  }
  
  // Check if the feature is enabled
  bool get isEnabled => _isEnabled;
  
  // Enable or disable the feature
  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emotion_detection_enabled', value);
  }
  
  // Set the helpline number
  Future<void> setHelplineNumber(String number) async {
    _helplineNumber = number;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('helpline_number', number);
  }
  
  // Set the caregiver contact
  Future<void> setCaregiverContact(String contact) async {
    _caregiverContact = contact;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('caregiver_contact', contact);
  }
  
  String get helplineNumber => _helplineNumber;
  String get caregiverContact => _caregiverContact;
  
  // Start monitoring for emotions across the app
  void startMonitoring(BuildContext context, {bool reducedFrequency = false}) {
    if (!_isEnabled) return;
    
    // Cancel existing timer if any
    _analysisTimer?.cancel();
    
    // Set monitoring frequency based on the page type
    final frequency = reducedFrequency ? const Duration(minutes: 2) : const Duration(seconds: 30);
    
    // Simulating periodic emotion analysis (in a real app, this would be tied to ML processing)
    _analysisTimer = Timer.periodic(frequency, (timer) {
      // This is a mock detection - in a real app, this would be ML-based analysis
      final random = DateTime.now().millisecond % 20; // 5% chance on regular pages, higher on camera pages
      final threshold = reducedFrequency ? 1 : 3; // Lower threshold (more detections) for camera pages
      
      if (random < threshold) {
        final moods = ['sad', 'anxious', 'distressed', 'frustrated'];
        final detectedMood = moods[DateTime.now().second % moods.length];
        _showEmotionOverlay(context, detectedMood);
      }
    });
  }
  
  // Stop monitoring
  void stopMonitoring() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
  }
  
  // Analyze text for emotional content
  void analyzeText(BuildContext context, String text) {
    if (!_isEnabled) return;
    
    // Simple keywords for demonstration - in a real app, use NLP
    final distressKeywords = ['sad', 'anxious', 'worried', 'depressed', 'scared', 'afraid', 
                             'unhappy', 'miserable', 'terrible', 'upset', 'distressed',
                             'overwhelmed', 'hopeless', 'helpless', 'fearful', 'desperate'];
    
    final lowerText = text.toLowerCase();
    for (final keyword in distressKeywords) {
      if (lowerText.contains(keyword)) {
        _showEmotionOverlay(context, keyword);
        break;
      }
    }
  }
  
  // Show the overlay when emotion is detected
  void _showEmotionOverlay(BuildContext context, String mood) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EmotionMoodOverlay(
          detectedMood: mood,
          onShowCalming: () {
            Navigator.of(context).pop();
            _showCalmingTechniques(context);
          },
          onConnectHelpline: () {
            Navigator.of(context).pop();
            _connectToHelpline();
          },
          onAlertCaregiver: () {
            Navigator.of(context).pop();
            _alertCaregiver(context);
          },
          onDismiss: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
  
  // Show calming techniques dialog
  void _showCalmingTechniques(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CalmingTechniquesSheet();
      },
    );
  }
  
  // Connect to helpline
  Future<void> _connectToHelpline() async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: _helplineNumber,
    );
    
    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    }
  }
  
  // Alert caregiver
  void _alertCaregiver(BuildContext context) {
    if (_caregiverContact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No caregiver contact set. Please configure in Accessibility Settings.'),
        ),
      );
      return;
    }
    
    // In a real app, this would send a notification via SMS, app notification, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert sent to caregiver: $_caregiverContact'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Widget for calming techniques
class CalmingTechniquesSheet extends StatefulWidget {
  @override
  _CalmingTechniquesSheetState createState() => _CalmingTechniquesSheetState();
}

class _CalmingTechniquesSheetState extends State<CalmingTechniquesSheet> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _breathingController;
  int _breathCount = 0;
  bool _isBreathing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _breathCount++;
        if (_isBreathing && _breathCount < 10) {
          _breathingController.forward();
        } else {
          setState(() {
            _isBreathing = false;
          });
        }
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _breathingController.dispose();
    super.dispose();
  }
  
  void _startBreathingExercise() {
    setState(() {
      _isBreathing = true;
      _breathCount = 0;
    });
    _breathingController.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    final Animation<double> _breathingAnimation = CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    );
    
    Color primaryColor = const Color(0xFFF45B69);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calming Techniques',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'Breathing'),
              Tab(text: 'Grounding'),
              Tab(text: 'Affirmations'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Breathing exercise tab
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Deep Breathing Exercise',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _breathingAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 150 + (100 * _breathingAnimation.value),
                            height: 150 + (100 * _breathingAnimation.value),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _isBreathing 
                                    ? (_breathingController.status == AnimationStatus.forward 
                                        ? 'Breathe In...' 
                                        : 'Breathe Out...')
                                    : 'Tap to Start',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_isBreathing)
                        Text(
                          'Breath ${_breathCount + 1}/10',
                          style: const TextStyle(fontSize: 16),
                        )
                      else
                        ElevatedButton(
                          onPressed: _startBreathingExercise,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Start Breathing Exercise'),
                        ),
                    ],
                  ),
                ),
                
                // Grounding techniques tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      '5-4-3-2-1 Grounding Technique',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGroundingItem(
                      '5 things you can SEE', 
                      Icons.visibility, 
                      'Look around you and name 5 things you can see right now'
                    ),
                    _buildGroundingItem(
                      '4 things you can TOUCH', 
                      Icons.touch_app, 
                      'Find 4 things around you that you can feel or touch'
                    ),
                    _buildGroundingItem(
                      '3 things you can HEAR', 
                      Icons.hearing, 
                      'Focus on 3 sounds you can hear right now'
                    ),
                    _buildGroundingItem(
                      '2 things you can SMELL', 
                      Icons.air, 
                      'Notice 2 scents around you, or things you like the smell of'
                    ),
                    _buildGroundingItem(
                      '1 thing you can TASTE', 
                      Icons.restaurant, 
                      'Notice 1 taste in your mouth, or something you enjoy tasting'
                    ),
                  ],
                ),
                
                // Positive affirmations tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Positive Affirmations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAffirmationCard('I am safe right now'),
                    _buildAffirmationCard('This feeling will pass'),
                    _buildAffirmationCard('I am doing the best I can'),
                    _buildAffirmationCard('I am strong and capable'),
                    _buildAffirmationCard('I deserve kindness and care'),
                    _buildAffirmationCard('One step at a time'),
                    _buildAffirmationCard('I am not alone'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGroundingItem(String title, IconData icon, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFF45B69)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAffirmationCard(String affirmation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            affirmation,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// Settings UI for the Emotion Detection feature in Accessibility Settings
class EmotionDetectionSettingsSection extends StatefulWidget {
  @override
  _EmotionDetectionSettingsSectionState createState() => _EmotionDetectionSettingsSectionState();
}

class _EmotionDetectionSettingsSectionState extends State<EmotionDetectionSettingsSection> {
  final EmotionMoodDetectionManager _manager = EmotionMoodDetectionManager();
  bool _isLoading = true;
  late bool _isEnabled;
  late TextEditingController _helplineController;
  late TextEditingController _caregiverController;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    await _manager.initialize();
    setState(() {
      _isEnabled = _manager.isEnabled;
      _helplineController = TextEditingController(text: _manager.helplineNumber);
      _caregiverController = TextEditingController(text: _manager.caregiverContact);
      _isLoading = false;
    });
  }
  
  @override
  void dispose() {
    _helplineController.dispose();
    _caregiverController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emotion & Mood Detection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'This feature uses AI to detect emotional distress and offer support',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        
        // Enable/disable toggle
        SwitchListTile(
          title: const Text('Enable Emotion & Mood Detection'),
          value: _isEnabled,
          onChanged: (value) async {
            await _manager.setEnabled(value);
            setState(() {
              _isEnabled = value;
            });
          },
          activeColor: const Color(0xFFF45B69),
        ),
        
        const Divider(),
        const SizedBox(height: 8),
        
        // Helpline number
        const Text(
          'Helpline Number',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _helplineController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter helpline phone number',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          enabled: _isEnabled,
        ),
        
        const SizedBox(height: 16),
        
        // Caregiver contact
        const Text(
          'Caregiver/Staff Contact',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _caregiverController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter caregiver phone or email',
            prefixIcon: Icon(Icons.contact_phone),
          ),
          enabled: _isEnabled,
        ),
        
        const SizedBox(height: 16),
        
        // Save button
        ElevatedButton.icon(
          onPressed: _isEnabled ? () async {
            await _manager.setHelplineNumber(_helplineController.text);
            await _manager.setCaregiverContact(_caregiverController.text);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } : null,
          icon: const Icon(Icons.save),
          label: const Text('Save Contact Information'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF45B69),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
            minimumSize: const Size.fromHeight(45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Test the feature
        if (_isEnabled)
          OutlinedButton.icon(
            onPressed: () {
              // Show a demonstration of the emotional detection
              _manager._showEmotionOverlay(context, 'anxious');
            },
            icon: const Icon(Icons.psychology),
            label: const Text('Test Detection Feature'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF45B69),
              side: const BorderSide(color: Color(0xFFF45B69)),
              minimumSize: const Size.fromHeight(45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }
}