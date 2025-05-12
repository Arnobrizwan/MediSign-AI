// lib/screens/billing/billing_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pay/pay.dart';

/// Launch this page with patientId (e.g. "arnob" or "bornil")
class BillingPage extends StatelessWidget {
  final String patientId;
  const BillingPage({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);

    Widget sectionTile(IconData icon, String title, Widget page) {
      return Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListTile(
          leading: Icon(icon, color: primaryColor, size: 28),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills & Payments',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: const TextStyle(color: primaryColor, fontSize: 20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          sectionTile(
            Icons.attach_money,
            'Outstanding Bills',
            OutstandingBillsPage(patientId: patientId),
          ),
          sectionTile(
            Icons.history,
            'Payment History',
            PaymentHistoryPage(patientId: patientId),
          ),
          sectionTile(
            Icons.policy,
            'Insurance Information',
            const InsuranceInfoPage(),
          ),
          sectionTile(
            Icons.handshake,
            'Financial Assistance',
            const FinancialAssistancePage(),
          ),
        ],
      ),
    );
  }
}

/// Outstanding bills—two different dummy sets keyed by lowercase patientId.
class OutstandingBillsPage extends StatelessWidget {
  final String patientId;
  const OutstandingBillsPage({Key? key, required this.patientId})
      : super(key: key);

  static const _dummy = {
    'arnob': [
      {'id': 'A100', 'amount': 120.00, 'due': 'Jun 1, 2025'},
      {'id': 'A101', 'amount':  75.50, 'due': 'Jun 10, 2025'},
    ],
    'bornil': [
      {'id': 'B200', 'amount': 200.00, 'due': 'May 20, 2025'},
      {'id': 'B201', 'amount':  50.00, 'due': 'Jun 5, 2025'},
    ],
  };

  void _onGooglePayResult(
      BuildContext ctx, Map<String, dynamic> result, Map inv) {
    // 1. Show confirmation
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Payment successful!')),
    );

    // 2. Move this invoice into payment history
    final history = PaymentHistoryPage._paymentHistory;
    final key = patientId.toLowerCase();
    final amount = (inv['amount'] as double);
    final newEntry = {
      'id': inv['id'],
      'amount': amount,
      'paidOn': DateFormat.yMMMd().format(DateTime.now()),
    };
    history[key] = [newEntry, ...?history[key]];
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);
    final bills = _dummy[patientId.toLowerCase()] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outstanding Bills'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle:
            const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: bills.isEmpty
          ? const Center(child: Text('You have no outstanding invoices.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final inv = bills[i];
                final amount = inv['amount'] as double;
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Invoice ${inv['id']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Amount: RM ${amount.toStringAsFixed(2)}'),
                        Text('Due: ${inv['due']}'),
                        const SizedBox(height: 16),
                     GooglePayButton(
  paymentConfigurationAsset: 'assets/gpay_service.json',
  paymentItems: [
    PaymentItem(
      label: 'Invoice ${inv['id']}',
      amount: amount.toStringAsFixed(2),
      status: PaymentItemStatus.final_price,
    )
  ],
  type: GooglePayButtonType.pay,
  onPaymentResult: (r) => _onGooglePayResult(ctx, r, inv),
  loadingIndicator: const Center(child: CircularProgressIndicator()),
),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Payment history (hard-coded initial + dynamic)
class PaymentHistoryPage extends StatelessWidget {
  final String patientId;
  const PaymentHistoryPage({Key? key, required this.patientId})
      : super(key: key);

  /// starts with two sample paid‐invoices, can grow on Google Pay success
  static final Map<String, List<Map<String, dynamic>>> _paymentHistory = {
    'arnob': [
      {'id': 'A090', 'amount': 50.00, 'paidOn': 'Apr 30, 2025'},
      {'id': 'A089', 'amount': 80.75, 'paidOn': 'Mar 15, 2025'},
    ],
    'bornil': [
      {'id': 'B190', 'amount': 60.00, 'paidOn': 'May 1, 2025'},
      {'id': 'B189', 'amount': 45.25, 'paidOn': 'Apr 5, 2025'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);
    final key = patientId.toLowerCase();
    final history = _paymentHistory[key] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle:
            const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: history.isEmpty
          ? const Center(child: Text('No payment history.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: history.length,
              itemBuilder: (_, i) {
                final p = history[i];
                final amount = p['amount'] as double;
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: ListTile(
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Invoice ${p['id']}'),
                    subtitle: Text(
                        'Paid RM ${amount.toStringAsFixed(2)} on ${p['paidOn']}'),
                  ),
                );
              },
            ),
    );
  }
}

/// Insurance info
class InsuranceInfoPage extends StatelessWidget {
  const InsuranceInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Information'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle:
            const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Provider: ABC Health\nPolicy #: 1234-5678-90\nCoverage: 80% outpatient',
          style: TextStyle(color: primaryColor, fontSize: 16),
        ),
      ),
    );
  }
}

/// Financial assistance info
class FinancialAssistancePage extends StatelessWidget {
  const FinancialAssistancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Assistance'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle:
            const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Apply for assistance if you meet these criteria:\n\n'
          '• Household income below RM 3000/month\n'
          '• No outstanding government debts\n'
          '• Provide proof of income',
          style: TextStyle(color: primaryColor, fontSize: 16),
        ),
      ),
    );
  }
}