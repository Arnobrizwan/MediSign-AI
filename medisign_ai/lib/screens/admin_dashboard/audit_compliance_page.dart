import 'package:flutter/material.dart';

class AuditCompliancePage extends StatelessWidget {
  const AuditCompliancePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFF45B69);
    const Color darkColor = Color(0xFF2D3142);
    const Color accentColor = Color(0xFF6B778D);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Audit & Compliance',
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
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
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
                      title: 'User Account Management',
                      icon: Icons.manage_accounts,
                      items: [
                        _ComplianceItem(
                          title: 'User Profiles',
                          description: 'View and edit user profiles and account details',
                          icon: Icons.person,
                          actionText: 'Manage',
                        ),
                        _ComplianceItem(
                          title: 'Caregiver Links',
                          description: 'Manage caregiver associations and permissions',
                          icon: Icons.link,
                          actionText: 'Configure',
                        ),
                        _ComplianceItem(
                          title: 'Password Management',
                          description: 'Reset passwords and manage security settings',
                          icon: Icons.password,
                          actionText: 'Manage',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      title: 'Access Control & Permissions',
                      icon: Icons.security,
                      items: [
                        _ComplianceItem(
                          title: 'Role Settings',
                          description: 'Configure role-based access control for staff',
                          icon: Icons.admin_panel_settings,
                          actionText: 'Configure',
                          hasBadge: true,
                        ),
                        _ComplianceItem(
                          title: 'Consent Management',
                          description: 'Manage patient consent forms and authorizations',
                          icon: Icons.fact_check,
                          actionText: 'Review',
                        ),
                        _ComplianceItem(
                          title: 'Access Groups',
                          description: 'Configure custom access groups for specific departments',
                          icon: Icons.group,
                          actionText: 'Configure',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      title: 'Audit Logs',
                      icon: Icons.history,
                      items: [
                        _ComplianceItem(
                          title: 'Medical Record Access',
                          description: 'View logs of all medical record access events',
                          icon: Icons.folder_shared,
                          actionText: 'View Logs',
                          hasBadge: true,
                        ),
                        _ComplianceItem(
                          title: 'Admin Actions',
                          description: 'Track all administrative actions and changes',
                          icon: Icons.admin_panel_settings,
                          actionText: 'View Logs',
                        ),
                        _ComplianceItem(
                          title: 'Login Activity',
                          description: 'Monitor login attempts and suspicious activity',
                          icon: Icons.login,
                          actionText: 'View Logs',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      title: 'Data & Privacy Compliance',
                      icon: Icons.privacy_tip,
                      items: [
                        _ComplianceItem(
                          title: 'Data Export',
                          description: 'Export user data for legal compliance requests',
                          icon: Icons.download,
                          actionText: 'Export',
                        ),
                        _ComplianceItem(
                          title: 'Data Deletion',
                          description: 'Securely delete user data upon request',
                          icon: Icons.delete_outline,
                          actionText: 'Manage',
                          isDestructive: true,
                        ),
                        _ComplianceItem(
                          title: 'Retention Policies',
                          description: 'Configure data retention rules and schedules',
                          icon: Icons.timer,
                          actionText: 'Configure',
                        ),
                        _ComplianceItem(
                          title: 'Compliance Reports',
                          description: 'Generate compliance reports for regulations',
                          icon: Icons.summarize,
                          actionText: 'Generate',
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
    );
  }

  Widget _buildHeaderWithActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Compliance & Administration',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.calendar_today, size: 16, color: Color(0xFF6B778D)),
              SizedBox(width: 8),
              Text(
                'Last 30 days',
                style: TextStyle(
                  color: Color(0xFF6B778D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, color: Color(0xFF6B778D)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_ComplianceItem> items,
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
          ),
          const Divider(height: 1),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => items[index],
          ),
        ],
      ),
    );
  }
}

class _ComplianceItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String actionText;
  final bool hasBadge;
  final bool isDestructive;

  const _ComplianceItem({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.actionText,
    this.hasBadge = false,
    this.isDestructive = false,
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
                'New',
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
          backgroundColor: isDestructive 
              ? const Color(0xFFF45B69).withOpacity(0.1)
              : const Color(0xFF6B778D).withOpacity(0.1),
          foregroundColor: isDestructive 
              ? const Color(0xFFF45B69)
              : const Color(0xFF6B778D),
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