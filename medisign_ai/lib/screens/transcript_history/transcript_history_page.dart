import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TranscriptHistoryPage extends StatefulWidget {
  const TranscriptHistoryPage({super.key});

  @override
  State<TranscriptHistoryPage> createState() => _TranscriptHistoryPageState();
}

class _TranscriptHistoryPageState extends State<TranscriptHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  List<DocumentSnapshot> allTranscripts = [];
  List<DocumentSnapshot> importantTranscripts = [];
  bool isLoading = true;
  bool showImportantOnly = false;

  @override
  void initState() {
    super.initState();
    _loadTranscripts();
  }

  Future<void> _loadTranscripts() async {
    user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('interactions')
        .doc(user!.uid)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      allTranscripts = snapshot.docs;
      importantTranscripts =
          snapshot.docs.where((doc) => doc['isImportant'] == true).toList();
      isLoading = false;
    });
  }

  Future<void> toggleImportant(DocumentSnapshot doc) async {
    final currentStatus = doc['isImportant'] ?? false;
    await doc.reference.update({'isImportant': !currentStatus});
    _loadTranscripts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Marked as ${!currentStatus ? 'important' : 'not important'}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transcriptsToShow =
        showImportantOnly ? importantTranscripts : allTranscripts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Transcripts'),
        actions: [
          IconButton(
            icon: Icon(
              showImportantOnly ? Icons.star : Icons.star_border,
              color: Colors.yellow[700],
            ),
            onPressed: () {
              setState(() => showImportantOnly = !showImportantOnly);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transcriptsToShow.isEmpty
              ? const Center(child: Text('No transcripts found.'))
              : ListView.builder(
                  itemCount: transcriptsToShow.length,
                  itemBuilder: (context, index) {
                    final doc = transcriptsToShow[index];
                    final timestamp = doc['timestamp']?.toDate();
                    final formattedDate = timestamp != null
                        ? '${timestamp.toLocal()}'
                        : 'No date';

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('${doc['type']} - $formattedDate'),
                        subtitle: Text(doc['summary'] ?? ''),
                        trailing: IconButton(
                          icon: Icon(
                            doc['isImportant'] == true
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.yellow[700],
                          ),
                          onPressed: () => toggleImportant(doc),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/transcript',
                              arguments: doc.data());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}