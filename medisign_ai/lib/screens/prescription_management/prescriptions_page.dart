// lib/screens/prescription_management/prescriptions_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medisign_ai/screens/conversation_mode/conversation_mode_page.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({Key? key}) : super(key: key);

  @override
  State<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid     => _auth.currentUser!.uid;
  Color  get _primary => const Color(0xFFF45B69);

  // Demo entries if Firestore is empty
  final _demoList = [
    {
      'id':         'demo1',
      'name':       'Paracetamol 500mg Tablet',
      'instructions':'Take 1 tablet every 6 hours if needed.',
      'refills':    '2',
      'doctor':     'Dr. Mim',
      'pharmacy':   'City Pharmacy',
      'nextRefill': 'May 15, 2025',
    },
    {
      'id':         'demo2',
      'name':       'Atorvastatin 10mg Tablet',
      'instructions':'Take 1 tablet daily at night.',
      'refills':    '1',
      'doctor':     'Dr. Helal',
      'pharmacy':   'WellCare Pharmacy',
      'nextRefill': 'May 20, 2025',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _primary, fontWeight: FontWeight.bold, fontSize: 20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Current Prescriptions'),
          const SizedBox(height: 12),
          _buildCurrent(),
          const SizedBox(height: 24),
          _sectionHeader('Refill Request History'),
          const SizedBox(height: 12),
          _simpleCard('Paracetamol • Approved • May 1, 2025'),
          _simpleCard('Atorvastatin • Pending • May 3, 2025'),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
  );

  Widget _buildCurrent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
        .collection('users')
        .doc(_uid)
        .collection('prescriptions')
        .orderBy('nextRefillDate')
        .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Column(
            children: _demoList.map((m) => _card(m, demo: true)).toList(),
          );
        }

        return Column(
          children: docs.map((doc) {
            final d = doc.data()! as Map<String, dynamic>;
            return _card({
              'id':           doc.id,
              'name':         d['name']              ?? '',
              'instructions': d['instructions']      ?? '',
              'refills':      (d['refillsRemaining']?.toString() ?? '0'),
              'doctor':       d['prescribingDoctor'] ?? '',
              'pharmacy':     d['pharmacy']          ?? '',
              'nextRefill':   DateFormat.yMMMd()
                                .format((d['nextRefillDate'] as Timestamp).toDate()),
            }, demo: false);
          }).toList(),
        );
      },
    );
  }

  Widget _card(Map<String,String> m, { required bool demo }) {
    final name    = m['name']!;
    final refills = int.tryParse(m['refills']!) ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(m['instructions']!),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 4, children: [
            _pill('🌀 Refills: ${m['refills']}'),
            _pill('👩‍⚕️ Doctor: ${m['doctor']}'),
            _pill('🏥 Pharmacy: ${m['pharmacy']}'),
            _pill('⏱ Next: ${m['nextRefill']}'),
          ]),
          const SizedBox(height: 16),

          // ——— buttons — clearly visible and full-width ———
          Row(children: [
            if (refills > 0)
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConversationModePage(
                          initialPrompt:
                            'I’d like to request a refill for $name.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Request Refill',
                    style: TextStyle(fontSize: 16)),
                ),
              ),

            if (refills > 0) const SizedBox(width: 12),

            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _primary, width: 2),
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationModePage(
                        initialPrompt:
                          'Show me detailed information about $name.',
                      ),
                    ),
                  );
                },
                child: const Text('View Info',
                  style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(width: 12),

            IconButton(
              icon: const Icon(Icons.alarm, size: 28, color: Color(0xFFF45B69)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reminder set for $name')),
                );
              },
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text),
  );

  Widget _simpleCard(String content) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(padding: const EdgeInsets.all(12), child: Text(content)),
  );
}