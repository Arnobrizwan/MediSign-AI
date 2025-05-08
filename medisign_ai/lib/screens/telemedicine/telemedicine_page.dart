import 'package:flutter/material.dart';

class TelemedicinePage extends StatefulWidget {
  const TelemedicinePage({super.key});

  @override
  State<TelemedicinePage> createState() => _TelemedicinePageState();
}

class _TelemedicinePageState extends State<TelemedicinePage> {
  bool inCall = false;
  bool micOn = true;
  bool videoOn = true;
  bool recording = false;
  List<String> chatLog = [
    '[Doctor]: Hello, can you describe your symptoms?',
    '[Patient]: I have a rash on my arm.',
  ];

  void toggleCall() {
    setState(() {
      inCall = !inCall;
    });
  }

  void toggleMic() {
    setState(() {
      micOn = !micOn;
    });
  }

  void toggleVideo() {
    setState(() {
      videoOn = !videoOn;
    });
  }

  void toggleRecording() {
    setState(() {
      recording = !recording;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(recording ? 'Recording started' : 'Recording stopped and saved')),
    );
  }

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
          inCall ? 'Telemedicine with Dr. Smith' : 'Telemedicine Consultations',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (inCall)
            TextButton(
              onPressed: toggleCall,
              child: const Text('End Call', style: TextStyle(color: Color(0xFFF45B69))),
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: inCall ? _buildCallScreen(primaryColor) : _buildPreCallScreen(primaryColor),
    );
  }

  Widget _buildPreCallScreen(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('Upcoming Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: const Text('Dr. Smith'),
              subtitle: const Text('Today at 3:00 PM'),
              trailing: ElevatedButton(
                onPressed: toggleCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Join Call'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: const Text('Dr. Lee'),
              subtitle: const Text('Tomorrow at 11:00 AM'),
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Inactive'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallScreen(Color primaryColor) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                color: Colors.grey.shade300,
                child: const Center(child: Text('Doctor Video Feed')),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('Your Camera View')),
                ),
              ),
            ],
          ),
        ),

        // Communication Aids Section
        Container(
          height: 120,
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            itemCount: chatLog.length,
            itemBuilder: (context, index) {
              return Text(chatLog[index]);
            },
          ),
        ),

        // Controls Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(micOn ? Icons.mic : Icons.mic_off, color: primaryColor),
                onPressed: toggleMic,
              ),
              IconButton(
                icon: Icon(videoOn ? Icons.videocam : Icons.videocam_off, color: primaryColor),
                onPressed: toggleVideo,
              ),
              IconButton(
                icon: const Icon(Icons.insert_drive_file, color: Color(0xFFF45B69)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select and upload a document...')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.screen_share, color: Color(0xFFF45B69)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Screen sharing started...')),
                  );
                },
              ),
              IconButton(
                icon: Icon(recording ? Icons.stop_circle : Icons.fiber_manual_record, color: Colors.red),
                onPressed: toggleRecording,
              ),
              const Icon(Icons.lock, color: Colors.green), // Secure icon
            ],
          ),
        ),
      ],
    );
  }
}