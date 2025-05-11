// lib/screens/billing/billing_page.dart

import 'package:flutter/material.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bills & Payments',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTile(
            context,
            primaryColor,
            Icons.attach_money,
            'Outstanding Bills',
            OutstandingBillsPage(),
          ),
          _sectionTile(
            context,
            primaryColor,
            Icons.history,
            'Payment History',
            PaymentHistoryPage(),
          ),
          _sectionTile(
            context,
            primaryColor,
            Icons.policy,
            'Insurance Information',
            InsuranceInfoPage(),
          ),
          _sectionTile(
            context,
            primaryColor,
            Icons.handshake,
            'Financial Assistance',
            FinancialAssistancePage(),
          ),
        ],
      ),
    );
  }

  Widget _sectionTile(
    BuildContext context,
    Color primaryColor,
    IconData icon,
    String title,
    Widget page,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: primaryColor, size: 32),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}

/// Placeholder screens:

class OutstandingBillsPage extends StatelessWidget {
  const OutstandingBillsPage({super.key});
  @override
  Widget build(BuildContext context) {
    const pc = Color(0xFFF45B69);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outstanding Bills'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Text(
          'You have 2 pending invoices totaling RM 350.',
          style: TextStyle(color: pc, fontSize: 16),
        ),
      ),
    );
  }
}

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    const pc = Color(0xFFF45B69);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.check, color: Colors.green),
            title: const Text('Paid RM 150'),
            subtitle: const Text('Mar 10, 2025'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.check, color: Colors.green),
            title: const Text('Paid RM 200'),
            subtitle: const Text('Feb 20, 2025'),
          ),
        ],
      ),
    );
  }
}

class InsuranceInfoPage extends StatelessWidget {
  const InsuranceInfoPage({super.key});
  @override
  Widget build(BuildContext context) {
    const pc = Color(0xFFF45B69);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Information'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Provider: ABC Health\nPolicy #: 1234-5678-90\nCoverage: 80% outpatient',
          style: TextStyle(color: pc, fontSize: 16),
        ),
      ),
    );
  }
}

class FinancialAssistancePage extends StatelessWidget {
  const FinancialAssistancePage({super.key});
  @override
  Widget build(BuildContext context) {
    const pc = Color(0xFFF45B69);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Assistance'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Apply for assistance if you meet the criteria:\n\n'
          '• Household income below RM 3000/month\n'
          '• No outstanding government debts\n'
          '• Provide proof of income',
          style: TextStyle(color: pc, fontSize: 16),
        ),
      ),
    );
  }
}