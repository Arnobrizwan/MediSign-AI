import 'package:flutter/material.dart';

class ContentManagementPage extends StatelessWidget {
  const ContentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFF45B69);
    const Color darkColor = Color(0xFF2D3142);
    const Color accentColor = Color(0xFF6B778D);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Content Management',
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
            icon: const Icon(Icons.search),
            onPressed: () {},
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
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
              _buildHeaderWithActions(),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildSection(
                      title: 'Appointments',
                      icon: Icons.calendar_today,
                      items: [
                        _ContentItem(
                          title: 'Doctor Schedules',
                          description: 'Manage doctor availability and working hours',
                          icon: Icons.schedule,
                          actionText: 'Configure',
                          hasBadge: true,
                        ),
                        _ContentItem(
                          title: 'Appointment Rules',
                          description: 'Set up scheduling rules and constraints',
                          icon: Icons.rule,
                          actionText: 'Edit',
                        ),
                        _ContentItem(
                          title: 'Reminder Templates',
                          description: 'Configure SMS and email reminder templates',
                          icon: Icons.notifications_active,
                          actionText: 'Manage',
                        ),
                        _ContentItem(
                          title: 'Slot Management',
                          description: 'Configure time slot duration and availability',
                          icon: Icons.access_time,
                          actionText: 'Settings',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      title: 'Hospital Content',
                      icon: Icons.local_hospital,
                      items: [
                        _ContentItem(
                          title: 'Doctor Directory',
                          description: 'Manage doctor profiles and specialties',
                          icon: Icons.people,
                          actionText: 'Edit',
                        ),
                        _ContentItem(
                          title: 'Departments & Services',
                          description: 'Add, update or remove department information',
                          icon: Icons.business,
                          actionText: 'Manage',
                        ),
                        _ContentItem(
                          title: 'Hospital Maps',
                          description: 'Update interactive hospital floor plans',
                          icon: Icons.map,
                          actionText: 'Configure',
                          hasBadge: true,
                        ),
                        _ContentItem(
                          title: 'News & Announcements',
                          description: 'Manage public and internal announcements',
                          icon: Icons.campaign,
                          actionText: 'Publish',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      title: 'Medical Records Display',
                      icon: Icons.folder_shared,
                      items: [
                        _ContentItem(
                          title: 'Record Templates',
                          description: 'Configure how medical records are displayed',
                          icon: Icons.description,
                          actionText: 'Design',
                        ),
                        _ContentItem(
                          title: 'Jargon Simplification',
                          description: 'Manage medical terminology simplification rules',
                          icon: Icons.translate,
                          actionText: 'Configure',
                        ),
                        _ContentItem(
                          title: 'Consent Forms',
                          description: 'Manage digital consent form templates',
                          icon: Icons.assignment,
                          actionText: 'Edit',
                        ),
                        _ContentItem(
                          title: 'Record Accessibility',
                          description: 'Configure accessibility features for records',
                          icon: Icons.accessibility,
                          actionText: 'Settings',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      title: 'Prescription Workflow',
                      icon: Icons.medication,
                      items: [
                        _ContentItem(
                          title: 'Refill Flow',
                          description: 'Configure medication refill request workflow',
                          icon: Icons.loop,
                          actionText: 'Configure',
                          hasBadge: true,
                        ),
                        _ContentItem(
                          title: 'Prescription Queues',
                          description: 'Manage pharmacy queue system and alerts',
                          icon: Icons.queue,
                          actionText: 'Settings',
                        ),
                        _ContentItem(
                          title: 'Status Tracking',
                          description: 'Configure prescription status steps and notifications',
                          icon: Icons.track_changes,
                          actionText: 'Edit',
                        ),
                        _ContentItem(
                          title: 'Medication Database',
                          description: 'Update medication information and dosage guidelines',
                          icon: Icons.medication_liquid,
                          actionText: 'Manage',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      title: 'Billing & Financial',
                      icon: Icons.payments,
                      items: [
                        _ContentItem(
                          title: 'Bill Templates',
                          description: 'Configure invoice and receipt templates',
                          icon: Icons.receipt_long,
                          actionText: 'Design',
                        ),
                        _ContentItem(
                          title: 'Financial Assistance',
                          description: 'Manage financial aid application forms and rules',
                          icon: Icons.handshake,
                          actionText: 'Configure',
                        ),
                        _ContentItem(
                          title: 'Payment Gateway',
                          description: 'Configure online payment methods and settings',
                          icon: Icons.credit_card,
                          actionText: 'Manage',
                          hasBadge: true,
                        ),
                        _ContentItem(
                          title: 'Insurance Integration',
                          description: 'Configure insurance provider integration settings',
                          icon: Icons.health_and_safety,
                          actionText: 'Settings',
                        ),
                      ],
                    ),
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
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeaderWithActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Systems & Content',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.history, size: 16),
              label: const Text('History'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B778D),
                side: const BorderSide(color: Color(0xFF6B778D)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Content'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF45B69),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_ContentItem> items,
  }) {
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
                      child: Icon(icon, color: const Color(0xFFF45B69), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Color(0xFF6B778D),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => items[index],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: Color(0xFF6B778D),
                ),
                label: const Text(
                  'Add New Item',
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
}

class _ContentItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String actionText;
  final bool hasBadge;

  const _ContentItem({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.actionText,
    this.hasBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6B778D).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6B778D)),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          if (hasBadge) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF45B69).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Updated',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF45B69),
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          description,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ),
      trailing: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B778D).withOpacity(0.1),
          foregroundColor: const Color(0xFF6B778D),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(actionText),
      ),
    );
  }
}