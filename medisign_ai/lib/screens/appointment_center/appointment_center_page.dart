import 'package:flutter/material.dart';

class AppointmentCenterPage extends StatefulWidget {
  const AppointmentCenterPage({super.key});

  @override
  State<AppointmentCenterPage> createState() => _AppointmentCenterPageState();
}

class _AppointmentCenterPageState extends State<AppointmentCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Color primaryColor = const Color(0xFFF45B69);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appointment Center',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Book New'),
            Tab(text: 'Reminders & Forms'),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: TabBarView(
        controller: _tabController,
        children: [
          _upcomingAppointments(),
          _pastAppointments(),
          _bookNewAppointment(),
          _manageRemindersForms(),
        ],
      ),
    );
  }

  Widget _upcomingAppointments() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _appointmentCard(
          date: 'Tuesday, May 20, 2025 at 10:00 AM',
          doctor: 'Dr. Aisha Khan, Cardiology',
          location: 'Wing B, Level 2',
          type: 'Consultation',
          status: 'Confirmed',
        ),
      ],
    );
  }

  Widget _pastAppointments() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _pastAppointmentCard(
          date: 'May 5, 2025',
          doctor: 'Dr. Aisha Khan, Cardiology',
          summaryAvailable: true,
        ),
      ],
    );
  }

  Widget _bookNewAppointment() {
    String? selectedDepartment;
    String? selectedDoctor;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          decoration: _inputDecoration('Select Department/Specialty'),
          items: const [
            DropdownMenuItem(value: 'Cardiology', child: Text('Cardiology')),
            DropdownMenuItem(value: 'Neurology', child: Text('Neurology')),
          ],
          onChanged: (val) => selectedDepartment = val,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: _inputDecoration('Select Doctor (Optional)'),
          items: const [
            DropdownMenuItem(value: 'Dr. Aisha Khan', child: Text('Dr. Aisha Khan')),
            DropdownMenuItem(value: 'Any Available', child: Text('Any Available Doctor')),
          ],
          onChanged: (val) => selectedDoctor = val,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: _inputDecoration('Reason for Visit (Optional)'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking confirmed!')),
            );
          },
          style: _buttonStyle(),
          child: const Text('Confirm Booking'),
        ),
      ],
    );
  }

  Widget _manageRemindersForms() {
    bool reminderOn = true;
    String reminderTime = '24 hours before';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Enable Appointment Reminders'),
          value: reminderOn,
          onChanged: (val) {
            setState(() {
              reminderOn = val;
            });
          },
          activeColor: primaryColor,
        ),
        DropdownButtonFormField<String>(
          value: reminderTime,
          decoration: _inputDecoration('Reminder Timing'),
          items: const [
            DropdownMenuItem(value: '24 hours before', child: Text('24 hours before')),
            DropdownMenuItem(value: '2 hours before', child: Text('2 hours before')),
          ],
          onChanged: (val) {
            setState(() {
              reminderTime = val!;
            });
          },
        ),
        const SizedBox(height: 20),
        ListTile(
          title: const Text('Pre-Appointment Forms'),
          subtitle: const Text('Form: Health History'),
          trailing: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening form...')),
              );
            },
            style: _buttonStyle(),
            child: const Text('Fill Form'),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size.fromHeight(50),
    );
  }

  Widget _appointmentCard({
    required String date,
    required String doctor,
    required String location,
    required String type,
    required String status,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('$doctor\n$type'),
        subtitle: Text('$date\n$location\nStatus: $status'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$value selected')));
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'View Details', child: Text('View Details/Instructions')),
            const PopupMenuItem(value: 'Request Reschedule', child: Text('Request Reschedule')),
            const PopupMenuItem(value: 'Cancel Appointment', child: Text('Cancel Appointment')),
          ],
        ),
      ),
    );
  }

  Widget _pastAppointmentCard({
    required String date,
    required String doctor,
    required bool summaryAvailable,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('$doctor\nPast Appointment'),
        subtitle: Text('Date: $date'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$value selected')));
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'View Summary', child: Text('View Summary/Notes')),
            const PopupMenuItem(value: 'Book Follow-up', child: Text('Book Follow-up')),
          ],
        ),
      ),
    );
  }
}