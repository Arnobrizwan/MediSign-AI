import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui; // Import for PointMode

class LearningGamifiedPage extends StatefulWidget {
  const LearningGamifiedPage({super.key});

  @override
  _LearningGamifiedPageState createState() => _LearningGamifiedPageState();
}

class _LearningGamifiedPageState extends State<LearningGamifiedPage> {
  static const Color primaryColor = Color(0xFFF45B69);
  static const Color accentColor = Color(0xFF6B778D);
  static const Color darkColor = Color(0xFF2D3142);
  
  // User progress data (simulated backend data)
  double progressValue = 0.6;
  int streakDays = 7;
  int totalPoints = 375;
  int dailyGoal = 50;
  int todayPoints = 30;
  List<bool> achievementUnlocked = [true, true, false, false, true];
  
  // Simulated tutorials data
  final List<Map<String, dynamic>> tutorials = [
    {
      'title': 'BIM Basics',
      'progress': 0.8,
      'lessons': 5,
      'completedLessons': 4,
      'icon': Icons.sign_language,
    },
    {
      'title': 'BISINDO Common Phrases',
      'progress': 0.4,
      'lessons': 10,
      'completedLessons': 4,
      'icon': Icons.record_voice_over,
    },
    {
      'title': 'Introduction to Braille Reading',
      'progress': 1.0,
      'lessons': 8,
      'completedLessons': 8,
      'icon': Icons.text_fields,  // Changed from Icons.braille which doesn't exist
    },
    {
      'title': 'Braille Writing',
      'progress': 0.25,
      'lessons': 12,
      'completedLessons': 3,
      'icon': Icons.edit,
    },
  ];
  
  // Simulated achievements
  final List<Map<String, dynamic>> achievements = [
    {
      'title': 'BIM Alphabet Master',
      'description': 'Complete all BIM alphabet lessons',
      'unlocked': true,
      'icon': Icons.military_tech,
    },
    {
      'title': 'Braille Beginner Pro',
      'description': 'Read 20 Braille characters correctly',
      'unlocked': true,
      'icon': Icons.stars,
    },
    {
      'title': '7-Day Learning Streak',
      'description': 'Practice for 7 consecutive days',
      'unlocked': true,
      'icon': Icons.local_fire_department,
    },
    {
      'title': 'Speed Typer',
      'description': 'Type 10 Braille characters in under 30 seconds',
      'unlocked': false,
      'icon': Icons.timer,
    },
    {
      'title': 'Communication Expert',
      'description': 'Complete all basic communication modules',
      'unlocked': false,
      'icon': Icons.emoji_people,
    },
  ];
  
  // For the Braille Speed Typing Test
  bool isPlayingBrailleGame = false;
  int brailleGameScore = 0;
  int brailleGameTimeLeft = 30;
  Timer? brailleGameTimer;
  
  // For the emoji communication board
  bool showEmojiBoard = false;
  
  // For the drawing pad
  bool showDrawingPad = false;
  List<DrawingPoint?> drawingPoints = [];
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;
  
  @override
  void dispose() {
    brailleGameTimer?.cancel();
    super.dispose();
  }
  
  void _startBrailleGame() {
    setState(() {
      isPlayingBrailleGame = true;
      brailleGameScore = 0;
      brailleGameTimeLeft = 30;
    });
    
    brailleGameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (brailleGameTimeLeft > 0) {
          brailleGameTimeLeft--;
        } else {
          _endBrailleGame();
        }
      });
    });
  }
  
  void _endBrailleGame() {
    brailleGameTimer?.cancel();
    
    // Update achievements if score is high enough
    if (brailleGameScore >= 10) {
      setState(() {
        achievements[3]['unlocked'] = true;
        totalPoints += 50;
        todayPoints += 50;
        
        // Show congratulation dialog
        Future.delayed(Duration.zero, () {
          _showAchievementDialog('Speed Typer', 'You typed ${brailleGameScore} characters in 30 seconds!');
        });
      });
    }
    
    setState(() {
      isPlayingBrailleGame = false;
    });
  }
  
  void _showAchievementDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🏆 $title Unlocked!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: primaryColor, size: 50),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 8),
              Text('+50 points!', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Awesome!'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  void _submitDrawing() {
    // Simulate sending to backend
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Drawing Submitted!'),
          content: const Text('Your drawing has been sent to your healthcare provider.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  showDrawingPad = false;
                  drawingPoints = [];
                  totalPoints += 20;
                  todayPoints += 20;
                });
              },
            ),
          ],
        );
      },
    );
  }
  
  void _onEmojiSelected(String emoji) {
    // Simulate adding to conversation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$emoji" to conversation'),
        backgroundColor: primaryColor,
      ),
    );
    
    setState(() {
      totalPoints += 5;
      todayPoints += 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Learn & Practice',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  totalPoints.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: isPlayingBrailleGame
          ? _buildBrailleGame()
          : showEmojiBoard
              ? _buildEmojiBoard()
              : showDrawingPad
                  ? _buildDrawingPad()
                  : _buildMainContent(),
    );
  }
  
  Widget _buildMainContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily streak card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Streak',
                      style: TextStyle(
                        fontSize: 14,
                        color: accentColor,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange),
                        Text(
                          ' $streakDays days',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      '$todayPoints/$dailyGoal points',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: todayPoints >= dailyGoal ? Colors.green : darkColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        _sectionHeader('Mini Tutorials'),
        
        // Tutorials list
        ...tutorials.map((tutorial) => _buildEnhancedTutorialCard(tutorial)),
        
        const SizedBox(height: 24),
        _sectionHeader('Daily Challenges & Interactive Tasks'),
        
        _buildEnhancedChallengeCard(
          'Today\'s Challenge: Sign "Hello, How Are You?"',
          Icons.record_voice_over,
          'Record yourself signing and get AI feedback',
          Colors.purpleAccent,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening camera for sign language recording...')),
            );
          },
        ),
        
        _buildEnhancedChallengeCard(
          'Braille Speed Typing Test',
          Icons.speed,
          'Type as many Braille characters as you can in 30 seconds',
          Colors.orange,
          () {
            _startBrailleGame();
          },
        ),
        
        _buildEnhancedChallengeCard(
          'Translate These 5 Phrases',
          Icons.translate,
          'Test your translation skills between English and Braille',
          Colors.blue,
          () {
            _showTranslationChallenge();
          },
        ),
        
        const SizedBox(height: 24),
        _sectionHeader('Rewards & Achievements'),
        
        // Achievements grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: achievement['unlocked'] ? Colors.white : Colors.grey[200],
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(achievement['description']),
                      backgroundColor: primaryColor,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        achievement['icon'],
                        color: achievement['unlocked'] ? primaryColor : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        achievement['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: achievement['unlocked'] ? darkColor : Colors.grey,
                        ),
                      ),
                      Icon(
                        achievement['unlocked'] ? Icons.lock_open : Icons.lock,
                        color: achievement['unlocked'] ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        // Progress towards next level
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Progress towards next level'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey.shade300,
                color: primaryColor,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text('${(progressValue * 100).toInt()}% towards Level ${(totalPoints / 100).floor() + 1}')),
          ],
        ),
        
        const SizedBox(height: 24),
        _sectionHeader('Creative Communication'),
        
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              setState(() {
                showEmojiBoard = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_emotions, color: Colors.amber),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Emoji-Based Communication Board',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Express yourself with emojis',
                          style: TextStyle(
                            fontSize: 14,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              setState(() {
                showDrawingPad = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.brush, color: Colors.purple),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Drawing/Sketch Pad',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Communicate through drawings',
                          style: TextStyle(
                            fontSize: 14,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBrailleGame() {
    // Braille dots to display
    final List<bool> brailleDots = List.generate(6, (_) => Random().nextBool());
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Braille Speed Typing Test',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Time left: $brailleGameTimeLeft seconds',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: brailleGameTimeLeft < 10 ? Colors.red : accentColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Score: $brailleGameScore',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 40),
          
          // Current Braille pattern to type
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Type this Braille pattern:'),
                const SizedBox(height: 20),
                SizedBox(
                  width: 100,
                  height: 150,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: brailleDots[index] ? primaryColor : Colors.grey[300],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Braille input buttons
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                onPressed: () {
                  // Simulate correct answer
                  if (Random().nextBool()) {
                    setState(() {
                      brailleGameScore++;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Correct!'),
                        backgroundColor: Colors.green,
                        duration: Duration(milliseconds: 500),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Try again!'),
                        backgroundColor: Colors.red,
                        duration: Duration(milliseconds: 500),
                      ),
                    );
                  }
                },
                child: Text('Dot ${index + 1}'),
              );
            },
          ),
          
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _endBrailleGame,
            child: const Text('End Game'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmojiBoard() {
    final List<String> emojis = [
      '😀', '😊', '🙂', '😍', '😢', '😡', '😴', '😷', '👍', '👎', 
      '👋', '🙏', '💪', '🫂', '❤️', '🩹', '🧠', '👨‍⚕️', '👩‍⚕️', '🏥',
      '💊', '💉', '🍲', '🥤', '🚽', '🚶', '🧍', '🦮', '⌚', '📱',
      '❓', '❗', '⚠️', '🆘', '🆕', '🔄', '📝', '🔍', '🕒', '📆'
    ];
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkColor,
        elevation: 0,
        title: const Text('Emoji Communication Board'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              showEmojiBoard = false;
            });
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tap on an emoji to communicate:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'These will be added to your conversation and spoken aloud',
              style: TextStyle(color: accentColor),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => _onEmojiSelected(emojis[index]),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          emojis[index],
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Tip: Combine multiple emojis to express more complex messages!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawingPad() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkColor,
        elevation: 0,
        title: const Text('Drawing Pad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              showDrawingPad = false;
              drawingPoints = [];
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                drawingPoints = [];
              });
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Color and stroke width selectors
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      for (var color in [
                        Colors.black,
                        Colors.red,
                        Colors.blue,
                        Colors.green,
                        Colors.yellow,
                        Colors.purple
                      ])
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: selectedColor == color
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                                width: selectedColor == color ? 2 : 1,
                              ),
                            ),
                            width: 30,
                            height: 30,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Stroke: '),
                      Slider(
                        value: strokeWidth,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: strokeWidth.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            strokeWidth = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Drawing canvas
            Expanded(
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    drawingPoints.add(
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color = selectedColor
                          ..isAntiAlias = true
                          ..strokeWidth = strokeWidth
                          ..strokeCap = StrokeCap.round,
                      ),
                    );
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    drawingPoints.add(
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color = selectedColor
                          ..isAntiAlias = true
                          ..strokeWidth = strokeWidth
                          ..strokeCap = StrokeCap.round,
                      ),
                    );
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    drawingPoints.add(null); // Add null to indicate end of line
                  });
                },
                child: CustomPaint(
                  painter: DrawingPainter(drawingPoints),
                  size: Size.infinite,
                ),
              ),
            ),
            // Submit button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: drawingPoints.isEmpty ? null : _submitDrawing,
                child: const Text('Send Drawing to Healthcare Provider'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showTranslationChallenge() {
    final List<Map<String, String>> phrases = [
      {'text': 'I need water', 'braille': '⠠⠊ ⠝⠑⠑⠙ ⠺⠁⠞⠑⠗'},
      {'text': 'How are you feeling?', 'braille': '⠠⠓⠕⠺ ⠁⠗⠑ ⠽⠕⠥ ⠋⠑⠑⠇⠊⠝⠛⠦'},
      {'text': 'I need pain medication', 'braille': '⠠⠊ ⠝⠑⠑⠙ ⠏⠁⠊⠝ ⠍⠑⠙⠊⠉⠁⠞⠊⠕⠝'},
      {'text': 'Thank you', 'braille': '⠠⠞⠓⠁⠝⠅ ⠽⠕⠥'},
      {'text': 'Call the nurse', 'braille': '⠠⠉⠁⠇⠇ ⠞⠓⠑ ⠝⠥⠗⠎⠑'},
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Track completed translations
            List<bool> completed = List.generate(phrases.length, (_) => false);
            
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Translation Challenge',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Match the text phrases with their Braille equivalents:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: phrases.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: completed[index] ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: completed[index] ? Colors.green : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Phrase ${index + 1}:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (completed[index])
                                      const Icon(Icons.check_circle, color: Colors.green),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  phrases[index]['text']!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Tap to select matching Braille:',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(
                                    phrases.length,
                                    (buttonIndex) => ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: completed[index]
                                          ? null
                                          : () {
                                              if (buttonIndex == index) {
                                                // Correct match
                                                setModalState(() {
                                                  completed[index] = true;
                                                });
                                                
                                                // Check if all completed
                                                if (completed.every((item) => item)) {
                                                  Navigator.pop(context);
                                                  
                                                  // Update points and show achievement
                                                  setState(() {
                                                    totalPoints += 25;
                                                    todayPoints += 25;
                                                  });
                                                  
                                                  // Show congratulation
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Challenge completed! +25 points'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                }
                                              } else {
                                                // Incorrect match
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Try again!'),
                                                    backgroundColor: Colors.red,
                                                    duration: Duration(seconds: 1),
                                                  ),
                                                );
                                              }
                                            },
                                      child: Text(phrases[buttonIndex]['braille']!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildEnhancedTutorialCard(Map<String, dynamic> tutorial) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showTutorialDetails(tutorial);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tutorial['icon'], color: primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tutorial['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${tutorial['completedLessons']}/${tutorial['lessons']} lessons completed',
                          style: const TextStyle(
                            fontSize: 14,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  tutorial['progress'] == 1.0
                      ? const Icon(Icons.verified, color: Colors.green)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(tutorial['progress'] * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: tutorial['progress'],
                  backgroundColor: Colors.grey.shade300,
                  color: primaryColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEnhancedChallengeCard(
    String title,
    IconData icon,
    String description,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showTutorialDetails(Map<String, dynamic> tutorial) {
    // Create fake lesson data
    final List<Map<String, dynamic>> lessons = List.generate(
      tutorial['lessons'],
      (index) => {
        'title': 'Lesson ${index + 1}',
        'description': 'Learn about ${tutorial['title']} basics - part ${index + 1}',
        'completed': index < tutorial['completedLessons'],
        'duration': '${5 + index * 2} min',
      },
    );
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tutorial['icon'], color: primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tutorial['title'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${tutorial['completedLessons']}/${tutorial['lessons']} lessons completed',
                          style: const TextStyle(
                            fontSize: 14,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: tutorial['progress'],
                  backgroundColor: Colors.grey.shade300,
                  color: primaryColor,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Course Content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final Map<String, dynamic> lesson = lessons[index];
                    final bool isCompleted = lesson['completed'] as bool;
                    final String title = lesson['title'] as String;
                    final String description = lesson['description'] as String;
                    final String duration = lesson['duration'] as String;
                    
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (!isCompleted) {
                          _startLessonSimulation(tutorial, index);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lesson ${index + 1} already completed!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted ? Colors.green : Colors.grey.shade200,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  duration,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  isCompleted ? Icons.play_circle : Icons.lock_open_outlined,
                                  color: isCompleted ? Colors.green : primaryColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _startLessonSimulation(Map<String, dynamic> tutorial, int lessonIndex) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Starting ${tutorial['title']} - Lesson ${lessonIndex + 1}'),
          content: const Text('This is a simulation. In a real app, this would start an interactive lesson with videos and exercises.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Start Anyway'),
              onPressed: () {
                Navigator.of(context).pop();
                _simulateCompletingLesson(tutorial, lessonIndex);
              },
            ),
          ],
        );
      },
    );
  }
  
  void _simulateCompletingLesson(Map<String, dynamic> tutorial, int lessonIndex) {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Simulating lesson completion...'),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    // Simulate lesson completion after a delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close loading dialog
      
      // Update the tutorial progress
      setState(() {
        if (lessonIndex >= tutorial['completedLessons']) {
          tutorial['completedLessons']++;
          tutorial['progress'] = tutorial['completedLessons'] / tutorial['lessons'];
          
          // Add points
          totalPoints += 20;
          todayPoints += 20;
          
          // Update progress
          progressValue = (progressValue * 0.8) + 0.05;
          if (progressValue > 1.0) progressValue = 1.0;
        }
      });
      
      // Show completion message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson completed! +20 points'),
          backgroundColor: Colors.green,
        ),
      );
      
      // If all lessons completed, show achievement
      if (tutorial['completedLessons'] == tutorial['lessons']) {
        _showAchievementDialog(
          tutorial['title'] + ' Master',
          'You\'ve completed all lessons in ' + tutorial['title'] + '!',
        );
        
        // Unlock achievement if it's the Communication Expert one
        if (tutorial['title'] == 'Introduction to Braille Reading') {
          setState(() {
            achievements[4]['unlocked'] = true;
          });
        }
      }
    });
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;
  
  DrawingPainter(this.drawingPoints);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < drawingPoints.length - 1; i++) {
      if (drawingPoints[i] != null && drawingPoints[i + 1] != null) {
        canvas.drawLine(
          drawingPoints[i]!.offset,
          drawingPoints[i + 1]!.offset,
          drawingPoints[i]!.paint,
        );
      } else if (drawingPoints[i] != null && drawingPoints[i + 1] == null) {
        // Use Points mode instead of PointMode
        canvas.drawPoints(
          ui.PointMode.points,
          [drawingPoints[i]!.offset],
          drawingPoints[i]!.paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  
  DrawingPoint(this.offset, this.paint);
}