import 'package:flutter/material.dart';

class SessionMonitoringPage extends StatelessWidget {
  const SessionMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFF45B69);
    const Color darkColor = Color(0xFF2D3142);
    const Color accentColor = Color(0xFF6B778D);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Session Monitoring',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: darkColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            color: Colors.white,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithStatus(),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildActiveSessionsSection(),
                    const SizedBox(height: 24),
                    _buildSupportTicketsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.headset_mic),
        tooltip: 'Start support session',
      ),
    );
  }

  Widget _buildHeaderWithStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Monitoring',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'System operational',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildStatCard('Active Users', '128', Icons.person),
            const SizedBox(width: 16),
            _buildStatCard('Open Tickets', '15', Icons.confirmation_number),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFFF45B69),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF45B69).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.computer,
                        color: Color(0xFFF45B69),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Active Sessions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildFilterButton('All Sessions'),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.filter_list,
                        color: Color(0xFF6B778D),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const _SessionSearchBar(),
          const Divider(height: 1),
          const _SessionTableHeader(),
          const Divider(height: 1),
          const _SessionRow(
            username: 'thomas.wilson',
            role: 'Physician',
            duration: '45:12',
            device: 'iPhone 15',
            location: 'Cardiology Dept',
            isActive: true,
          ),
          const Divider(height: 1),
          const _SessionRow(
            username: 'sarah.murphy',
            role: 'Nurse',
            duration: '32:05',
            device: 'iPad Pro',
            location: 'Emergency Ward',
            isActive: true,
          ),
          const Divider(height: 1),
          const _SessionRow(
            username: 'john.davis',
            role: 'Administrator',
            duration: '15:48',
            device: 'Windows PC',
            location: 'Admin Office',
            isActive: true,
          ),
          const Divider(height: 1),
          const _SessionRow(
            username: 'maria.jackson',
            role: 'Lab Technician',
            duration: '28:33',
            device: 'Android Tablet',
            location: 'Pathology Lab',
            isActive: false,
            isIdle: true,
          ),
          const Divider(height: 1),
          const _SessionRow(
            username: 'robert.chen',
            role: 'Pharmacist',
            duration: '10:17',
            device: 'MacBook Pro',
            location: 'Pharmacy',
            isActive: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.visibility,
                  size: 16,
                  color: Color(0xFF6B778D),
                ),
                label: const Text(
                  'View All Sessions',
                  style: TextStyle(
                    color: Color(0xFF6B778D),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTicketsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF45B69).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: Color(0xFFF45B69),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'User Support Tickets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildFilterButton('Open Tickets'),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF6B778D),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: const [
              _TicketItem(
                ticketId: 'TKT-4853',
                username: 'emma.torres',
                issue: 'Cannot access patient records',
                priority: 'High',
                status: 'Open',
                time: '10 mins ago',
                assigned: true,
              ),
              Divider(height: 1),
              _TicketItem(
                ticketId: 'TKT-4852',
                username: 'david.kumar',
                issue: 'Login error after password reset',
                priority: 'Medium',
                status: 'In Progress',
                time: '25 mins ago',
                assigned: true,
              ),
              Divider(height: 1),
              _TicketItem(
                ticketId: 'TKT-4851',
                username: 'jessica.thompson',
                issue: 'Prescription system unresponsive',
                priority: 'Critical',
                status: 'Open',
                time: '32 mins ago',
                assigned: false,
              ),
              Divider(height: 1),
              _TicketItem(
                ticketId: 'TKT-4850',
                username: 'michael.rodriguez',
                issue: 'Need permissions for lab results',
                priority: 'Low',
                status: 'Open',
                time: '45 mins ago',
                assigned: false,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Create New Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF45B69),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B778D),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: Color(0xFF6B778D),
          ),
        ],
      ),
    );
  }
}

class _SessionSearchBar extends StatelessWidget {
  const _SessionSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search sessions by username, role, or device...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[400],
            size: 20,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _SessionTableHeader extends StatelessWidget {
  const _SessionTableHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: Text(
              'USER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B778D),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'ROLE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B778D),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'DURATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B778D),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'DEVICE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B778D),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'LOCATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B778D),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B778D),
              ),
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String username;
  final String role;
  final String duration;
  final String device;
  final String location;
  final bool isActive;
  final bool isIdle;

  const _SessionRow({
    Key? key,
    required this.username,
    required this.role,
    required this.duration,
    required this.device,
    required this.location,
    required this.isActive,
    this.isIdle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: isActive && !isIdle ? Colors.white : Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFF45B69),
                  child: Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              role,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              duration,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              device,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              location,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? isIdle
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive
                    ? isIdle
                        ? 'Idle'
                        : 'Active'
                    : 'Inactive',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? isIdle
                          ? Colors.amber
                          : Colors.green
                      : Colors.grey,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: Color(0xFF6B778D),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketItem extends StatelessWidget {
  final String ticketId;
  final String username;
  final String issue;
  final String priority;
  final String status;
  final String time;
  final bool assigned;

  const _TicketItem({
    Key? key,
    required this.ticketId,
    required this.username,
    required this.issue,
    required this.priority,
    required this.status,
    required this.time,
    required this.assigned,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'critical':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'medium':
        priorityColor = Colors.amber;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.priority_high,
              color: priorityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ticketId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: status.toLowerCase() == 'open'
                            ? const Color(0xFFF45B69).withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status.toLowerCase() == 'open'
                              ? const Color(0xFFF45B69)
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  issue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Color(0xFF6B778D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B778D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: Color(0xFF6B778D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B778D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: assigned
                      ? Colors.grey[200]
                      : const Color(0xFFF45B69),
                  foregroundColor: assigned
                      ? Colors.grey[700]
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(assigned ? 'Assigned' : 'Assign'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B778D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}