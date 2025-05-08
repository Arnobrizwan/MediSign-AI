import 'package:flutter/material.dart';

class TranscriptHistoryPage extends StatefulWidget {
  const TranscriptHistoryPage({super.key});

  @override
  State<TranscriptHistoryPage> createState() => _TranscriptHistoryPageState();
}

class _TranscriptHistoryPageState extends State<TranscriptHistoryPage> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, String>> sessions = [
    {
      'date': 'May 7, 2025',
      'type': 'Doctor Conversation',
      'snippet': 'Discussed headache symptoms...',
      'patientId': 'P12345',
    },
    {
      'date': 'May 6, 2025',
      'type': 'AI Check-in',
      'snippet': 'Daily mood and pain check...',
      'patientId': 'P12345',
    },
    {
      'date': 'May 5, 2025',
      'type': 'Sign Translation',
      'snippet': 'Translated "help" and "pain"...',
      'patientId': 'P12345',
    },
  ];

  void openFilterOptions() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Filter Options'),
        content: const Text('Filter by date, patient ID, language, or tag.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }

  void exportAllAsPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported all filtered sessions as PDF')),
    );
  }

  void navigateToIndividualTranscript(Map<String, String> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IndividualTranscriptPage(session: session),
      ),
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
          'Communication Transcripts',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFF45B69)),
            onPressed: exportAllAsPDF,
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Link notice to main Medical Records Hub
            Card(
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.folder_shared, color: Color(0xFFF45B69)),
                title: const Text('Looking for all medical records?'),
                subtitle: const Text('Visit the full Medical Records Hub for lab results, visit summaries, and more.'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/health_records');
                  },
                  child: const Text('Go', style: TextStyle(color: Color(0xFFF45B69))),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search / Filter Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search transcripts...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Color(0xFFF45B69)),
                  onPressed: openFilterOptions,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Session List
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  var session = sessions[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text('${session['type']} - ${session['date']}'),
                      subtitle: Text(session['snippet'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.star_border, color: Color(0xFFF45B69)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Toggled favorite')),
                          );
                        },
                      ),
                      onTap: () => navigateToIndividualTranscript(session),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IndividualTranscriptPage extends StatelessWidget {
  final Map<String, String> session;

  const IndividualTranscriptPage({super.key, required this.session});

  void exportAsPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported transcript as PDF')),
    );
  }

  void toggleBrailleView(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Braille view activated')),
    );
  }

  void toggleFavorite(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toggled favorite tag')),
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
          '${session['type']} - ${session['date']}',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFF45B69)),
            onPressed: () => exportAsPDF(context),
          ),
          IconButton(
            icon: const Icon(Icons.blur_on, color: Color(0xFFF45B69)),
            onPressed: () => toggleBrailleView(context),
          ),
          IconButton(
            icon: const Icon(Icons.star_border, color: Color(0xFFF45B69)),
            onPressed: () => toggleFavorite(context),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Full Transcript:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '[10:35 AM] Patient: My head hurts.\n'
              '[10:36 AM] Doctor: Okay, can you describe the pain?\n'
              '[10:38 AM] Patient: It\'s a sharp pain on the left side.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => toggleBrailleView(context),
              icon: const Icon(Icons.blur_on),
              label: const Text('Toggle Braille View'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}