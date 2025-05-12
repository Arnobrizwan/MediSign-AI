import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pay/pay.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import '../billing/payment_service.dart';
import '../appointment_center/appointment_center_page.dart';
//import '../billing/custom_card.dart';
/// Payment Service to manage bill data across the app
class PaymentService with ChangeNotifier {
  // Private static instance for singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  
  // Factory constructor to return the same instance
  factory PaymentService() => _instance;
  
  // Internal constructor
  PaymentService._internal();
  
  // Static access to the singleton instance
  static PaymentService get instance => _instance;
  
  // Keep the original color
  static const primaryColor = Color(0xFFF45B69);
  
  // Outstanding bills data for different patients
  final Map<String, List<Map<String, dynamic>>> _outstandingBills = {
    'arnob': [
      {'id': 'A100', 'amount': 120.00, 'due': 'Jun 1, 2025', 'description': 'General Consultation'},
      {'id': 'A101', 'amount':  75.50, 'due': 'Jun 10, 2025', 'description': 'Laboratory Tests'},
    ],
    'bornil': [
      {'id': 'B200', 'amount': 200.00, 'due': 'May 20, 2025', 'description': 'Specialist Consultation'},
      {'id': 'B201', 'amount':  50.00, 'due': 'Jun 5, 2025', 'description': 'Prescription Medication'},
    ],
  };
  
  // Payment history data
  final Map<String, List<Map<String, dynamic>>> _paymentHistory = {
    'arnob': [
      {'id': 'A090', 'amount': 50.00, 'paidOn': 'Apr 30, 2025', 'method': 'Google Pay'},
      {'id': 'A089', 'amount': 80.75, 'paidOn': 'Mar 15, 2025', 'method': 'Credit Card'},
    ],
    'bornil': [
      {'id': 'B190', 'amount': 60.00, 'paidOn': 'May 1, 2025', 'method': 'Google Pay'},
      {'id': 'B189', 'amount': 45.25, 'paidOn': 'Apr 5, 2025', 'method': 'Bank Transfer'},
    ],
  };
  
  // Getters for bills and history
  List<Map<String, dynamic>> getOutstandingBills(String patientId) {
    return _outstandingBills[patientId.toLowerCase()] ?? [];
  }
  
  List<Map<String, dynamic>> getPaymentHistory(String patientId) {
    return _paymentHistory[patientId.toLowerCase()] ?? [];
  }
  
  // Process a payment and move it to history
  void processPayment(String patientId, String invoiceId, double amount, String paymentMethod) {
    final key = patientId.toLowerCase();
    
    // Create payment record
    final newPayment = {
      'id': invoiceId,
      'amount': amount,
      'paidOn': DateFormat.yMMMd().format(DateTime.now()),
      'method': paymentMethod,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    // Add to payment history
    if (_paymentHistory.containsKey(key)) {
      _paymentHistory[key]!.insert(0, newPayment);
    } else {
      _paymentHistory[key] = [newPayment];
    }
    
    // Remove from outstanding bills
    if (_outstandingBills.containsKey(key)) {
      _outstandingBills[key]!.removeWhere((bill) => bill['id'] == invoiceId);
    }
    
    // Update appointment status if this is an appointment payment
    if (invoiceId.startsWith('APT')) {
      FirebaseFirestore.instance
          .collection('appointments')
          .doc(invoiceId)
          .update({'status': 'Confirmed'})
          .catchError((e) => print('Error updating appointment: $e'));
    }
    
    // Notify listeners about changes
    notifyListeners();
  }
  
  // Add a new bill for a patient
  void addBill(String patientId, Map<String, dynamic> bill) {
    final key = patientId.toLowerCase();
    
    if (_outstandingBills.containsKey(key)) {
      _outstandingBills[key]!.add(bill);
    } else {
      _outstandingBills[key] = [bill];
    }
    
    notifyListeners();
  }
}

// Custom Card Widget
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  
  const CustomCard({
    Key? key, 
    required this.child, 
    this.margin, 
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Use this class to handle payments from anywhere in the app without needing context
class GlobalPaymentHandler {
  static final GlobalPaymentHandler _instance = GlobalPaymentHandler._internal();
  factory GlobalPaymentHandler() => _instance;
  GlobalPaymentHandler._internal();
  
  static const primaryColor = Color(0xFFF45B69);
  
  // Process payment without requiring Provider context
  Future<bool> processExternalPayment({
    required String patientId,
    required String invoiceId,
    required double amount,
    required String description,
    required String paymentMethod,
    BuildContext? context,
  }) async {
    try {
      // Process the payment using the PaymentService singleton
      PaymentService.instance.processPayment(
        patientId,
        invoiceId,
        amount,
        paymentMethod
      );
      
      // Show success message if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Payment successful'),
              ],
            ),
            backgroundColor: primaryColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      return true;
    } catch (e) {
      // Show error message if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Payment processing error: $e');
      return false;
    }
  }
  
  // Add a new bill without requiring Provider context
  Future<bool> addNewBill({
    required String patientId,
    required String invoiceId,
    required double amount,
    required String dueDate,
    required String description,
    BuildContext? context,
  }) async {
    try {
      final newBill = {
        'id': invoiceId,
        'amount': amount,
        'due': dueDate,
        'description': description,
      };
      
      PaymentService.instance.addBill(patientId, newBill);
      
      // Show confirmation message if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New bill added to your account'),
            backgroundColor: primaryColor,
          ),
        );
      }
      
      return true;
    } catch (e) {
      // Show error if context is provided
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add bill: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Add bill error: $e');
      return false;
    }
  }
}

/// Launch this page with patientId (e.g. "arnob" or "bornil")
class BillingPage extends StatelessWidget {
  final String patientId;
  const BillingPage({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using the original primary color
    const primaryColor = Color(0xFFF45B69);
    
    Widget sectionTile(IconData icon, String title, Widget page) {
      return CustomCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, 
                  size: 18, color: Colors.grey.shade600),
            ],
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: PaymentService.instance,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Bills & Payments',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          color: Colors.grey.shade50,
          child: ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            children: [
              sectionTile(
                Icons.receipt_long,
                'Outstanding Bills',
                OutstandingBillsPage(patientId: patientId),
              ),
              sectionTile(
                Icons.history,
                'Payment History',
                PaymentHistoryPage(patientId: patientId),
              ),
              sectionTile(
                Icons.shield,
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
        ),
      ),
    );
  }
}

/// Outstanding bills page
class OutstandingBillsPage extends StatefulWidget {
  final String patientId;
  const OutstandingBillsPage({Key? key, required this.patientId}) : super(key: key);

  @override
  State<OutstandingBillsPage> createState() => _OutstandingBillsPageState();
}

class _OutstandingBillsPageState extends State<OutstandingBillsPage> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);
    final bills = PaymentService.instance.getOutstandingBills(widget.patientId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'Outstanding Bills',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _processing
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : bills.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'You have no outstanding invoices',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final inv = bills[i];
                    final amt = inv['amount'] as double;
                    final desc = inv['description'] as String;
                    final isApt = inv['id'].toString().startsWith('APT');

                    return CustomCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Invoice ${inv['id']}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Due ${inv['due']}',
                                    style: const TextStyle(
                                        color: primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(desc),
                            const SizedBox(height: 8),
                            Text(
                              'RM ${amt.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor),
                            ),
                            const SizedBox(height: 20),

                            // ─── Pay Now ────────────────────────────────
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() => _processing = true);
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(
                                        builder: (_) =>
                                            ChangeNotifierProvider.value(
                                          value: PaymentService.instance,
                                          child: AppointmentPaymentPage(
                                            patientId: widget.patientId,
                                            invoiceId: inv['id'] as String,
                                            amount: amt,
                                            description: desc,
                                          ),
                                        ),
                                      ))
                                      .then((_) {
                                        if (!mounted) return;
                                        setState(() => _processing = false);
                                      });
                                },
                                child: const Text(
                                  'Pay Now',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                            if (isApt) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // your cancel appointment logic
                                },
                                icon: const Icon(Icons.cancel,
                                    color: primaryColor),
                                label: const Text(
                                  'Cancel Appointment',
                                  style: TextStyle(color: primaryColor),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: primaryColor),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// Payment history page
class PaymentHistoryPage extends StatelessWidget {
  final String patientId;
  const PaymentHistoryPage({Key? key, required this.patientId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);
 // Direct access to singleton
final history = PaymentService.instance.getPaymentHistory(patientId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: history.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No payment history',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: history.length,
                itemBuilder: (_, i) {
                  final payment = history[i];
                  final amount = payment['amount'] as double;
                  final method = payment['method'] as String? ?? 'Online Payment';
                  final isAppointment = payment['id'].toString().startsWith('APT');
                  
                  return CustomCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isAppointment ? Icons.event_available : Icons.check_circle, 
                              color: Colors.green.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invoice ${payment['id']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Paid on ${payment['paidOn']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Via $method',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'RM ${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
        title: const Text(
          'Insurance Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield, 
                            color: primaryColor, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Insurance Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow(context, 'Provider', 'ABC Health'),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Policy Number', '1234-5678-90'),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Coverage', '80% outpatient'),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Renewal Date', 'December 31, 2025'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Coverage Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCoverageItem(
                        context, 
                        'Outpatient Services', 
                        '80%', 
                        Icons.medical_services
                      ),
                      const Divider(height: 30),
                      _buildCoverageItem(
                        context, 
                        'Inpatient Services', 
                        '90%', 
                        Icons.local_hospital
                      ),
                      const Divider(height: 30),
                      _buildCoverageItem(
                        context, 
                        'Prescription Drugs', 
                        '70%', 
                        Icons.medication
                      ),
                      const Divider(height: 30),
                      _buildCoverageItem(
                        context, 
                        'Emergency Care', 
                        '100%', 
                        Icons.emergency
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
 Widget _buildCoverageItem(
    BuildContext context, String title, String coverage, IconData icon) {
    const primaryColor = Color(0xFFF45B69);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            coverage,
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
        title: const Text(
          'Financial Assistance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Eligibility Criteria',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCriteriaItem(
                        context, 
                        'Household income below RM 3000/month'
                      ),
                      _buildCriteriaItem(
                        context, 
                        'No outstanding government debts'
                      ),
                      _buildCriteriaItem(
                        context, 
                        'Provide proof of income'
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to Apply',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStepItem(
                        context, 
                        '1', 
                        'Complete the financial assistance application form'
                      ),
                      _buildStepItem(
                        context, 
                        '2', 
                        'Submit required documentation (proof of income, ID, etc.)'
                      ),
                      _buildStepItem(
                        context, 
                        '3', 
                        'Schedule an interview with our financial counselor'
                      ),
                      _buildStepItem(
                        context, 
                        '4', 
                        'Receive decision within 10 business days'
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Open application form
                            _showApplicationForm(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Start Application Process',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showApplicationForm(BuildContext context) {
    const primaryColor = Color(0xFFF45B69);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Application Form'),
        content: const Text(
          'Our financial assistance team will contact you to start the application process.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showConfirmation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
  
  void _showConfirmation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your request has been submitted. A representative will contact you shortly.'),
        backgroundColor: Color(0xFFF45B69),
        duration: Duration(seconds: 4),
      ),
    );
  }
  
  Widget _buildCriteriaItem(BuildContext context, String text) {
    const primaryColor = Color(0xFFF45B69);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, 
              color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepItem(BuildContext context, String step, String text) {
    const primaryColor = Color(0xFFF45B69);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to format Google Pay JSON
String getGooglePayJson(double amount) {
  return '''
{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "parameters": {
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "allowedCardNetworks": ["AMEX", "DISCOVER", "JCB", "MASTERCARD", "VISA"],
          "billingAddressRequired": false
        },
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "example",
            "gatewayMerchantId": "exampleGatewayMerchantId"
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "01234567890123456789",
      "merchantName": "MediSign AI"
    },
    "transactionInfo": {
      "totalPriceStatus": "FINAL",
      "totalPrice": "${amount.toStringAsFixed(2)}",
      "countryCode": "MY",
      "currencyCode": "MYR"
    }
  }
}
''';
}

