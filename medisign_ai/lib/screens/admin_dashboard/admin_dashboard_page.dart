import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  static const Color primaryColor = Color(0xFFF45B69);
  static const Color accentColor = Color(0xFF6B778D);
  static const Color darkColor = Color(0xFF2D3142);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: darkColor,
        elevation: 0,
        actions: const [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: null,
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: null,
          ),
          SizedBox(width: 8),
          Icon(Icons.account_circle, size: 32, color: Colors.white),
          SizedBox(width: 16),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Container(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Overview header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  _buildDateSelector(),
                ],
              ),
              const SizedBox(height: 20),

              // Stat cards
              Row(
                children: const [
                  _StatCard(
                    title: 'Appointments',
                    value: '128',
                    icon: Icons.calendar_today,
                    color: primaryColor,
                    trendValue: '+12%',
                    trendUp: true,
                  ),
                  SizedBox(width: 16),
                  _StatCard(
                    title: 'Pending Bills',
                    value: '24',
                    icon: Icons.payment,
                    color: Color(0xFF5C80BC),
                    trendValue: '-3%',
                    trendUp: false,
                  ),
                  SizedBox(width: 16),
                  _StatCard(
                    title: 'Active Sessions',
                    value: '8',
                    icon: Icons.chat_bubble_outline,
                    color: Color(0xFFAD7A99),
                    trendValue: '+2%',
                    trendUp: true,
                  ),
                  SizedBox(width: 16),
                  _StatCard(
                    title: 'Users',
                    value: '563',
                    icon: Icons.people,
                    color: Color(0xFF50AE54),
                    trendValue: '+8%',
                    trendUp: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Charts row
              Expanded(
                child: Row(
                  children: const [
                    Expanded(flex: 3, child: _AppointmentTrendChart()),
                    SizedBox(width: 16),
                    Expanded(flex: 2, child: _BillingOverviewChart()),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Activity & upcoming
              Expanded(
                child: Row(
                  children: const [
                    Expanded(flex: 2, child: _RecentActivityList()),
                    SizedBox(width: 16),
                    Expanded(child: _UpcomingAppointments()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
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
      child: const Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: accentColor),
          SizedBox(width: 8),
          Text(
            'Last 30 days',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_drop_down, color: accentColor),
        ],
      ),
    );
  }

  static Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: darkColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 28,
                      child: Icon(Icons.account_circle, size: 32, color: darkColor),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Admin Portal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),

              // Menu items
              _DrawerItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                isActive: true,
                onTap: () => Navigator.pop(context),
              ),
            _DrawerItem(
  icon: Icons.assignment, 
  label: 'Audit Compliance',
  onTap: () => Navigator.pushNamed(context, '/admin_audit_compliance'), 
),
_DrawerItem(
  icon: Icons.content_copy, 
  label: 'Content Management',
  onTap: () => Navigator.pushNamed(context, '/admin_manage_content'), 
),
_DrawerItem(
  icon: Icons.monitor, 
  label: 'Session Monitoring',
  onTap: () => Navigator.pushNamed(context, '/session_monitoring'), 
),
_DrawerItem(
  icon: Icons.translate, 
  label: 'Translation Review',
  onTap: () => Navigator.pushNamed(context, '/translation_review'), 
),
              const Spacer(),
              const Divider(color: Colors.white24),
              _DrawerItem(
                icon: Icons.logout,
                label: 'Logout',
                onTap: () {
                  // TODO: sign out logic
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trendValue;
  final bool trendUp;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trendValue,
    required this.trendUp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                Row(
                  children: [
                    Icon(
                      trendUp ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: trendUp ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendValue,
                      style: TextStyle(
                        color: trendUp ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AdminDashboardPage.darkColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Appointments Trend Chart ─────────────────────────────────────────────────
class _AppointmentTrendChart extends StatelessWidget {
  const _AppointmentTrendChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointments Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AdminDashboardPage.darkColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        const style = TextStyle(
                          color: AdminDashboardPage.accentColor,
                          fontSize: 12,
                        );
                        switch (v.toInt()) {
                          case 0:
                            return Text('JAN', style: style);
                          case 2:
                            return Text('FEB', style: style);
                          case 4:
                            return Text('MAR', style: style);
                          case 6:
                            return Text('APR', style: style);
                          case 8:
                            return Text('MAY', style: style);
                          case 10:
                            return Text('JUN', style: style);
                          default:
                            return const SizedBox();
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          color: AdminDashboardPage.accentColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 35),
                      FlSpot(1, 40),
                      FlSpot(2, 30),
                      FlSpot(3, 45),
                      FlSpot(4, 38),
                      FlSpot(5, 48),
                      FlSpot(6, 55),
                      FlSpot(7, 62),
                      FlSpot(8, 58),
                      FlSpot(9, 70),
                      FlSpot(10, 75),
                      FlSpot(11, 82),
                    ],
                    isCurved: true,
                    color: AdminDashboardPage.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          AdminDashboardPage.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Billing Overview Pie Chart ────────────────────────────────────────────────
class _BillingOverviewChart extends StatelessWidget {
  const _BillingOverviewChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Billing Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AdminDashboardPage.darkColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: 45,
                    title: '45%',
                    color: AdminDashboardPage.primaryColor,
                    radius: 90,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: 30,
                    title: '30%',
                    color: const Color(0xFF5C80BC),
                    radius: 90,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: 15,
                    title: '15%',
                    color: const Color(0xFFAD7A99),
                    radius: 90,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: 10,
                    title: '10%',
                    color: const Color(0xFF50AE54),
                    radius: 90,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _LegendItem(color: AdminDashboardPage.primaryColor, title: 'Completed', value: '45%'),
              _LegendItem(color: Color(0xFF5C80BC), title: 'Pending', value: '30%'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _LegendItem(color: Color(0xFFAD7A99), title: 'Cancelled', value: '15%'),
              _LegendItem(color: Color(0xFF50AE54), title: 'Other', value: '10%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String title;
  final String value;

  const _LegendItem({
    Key? key,
    required this.color,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      const SizedBox(width: 4),
      Text(value, style: const TextStyle(color: AdminDashboardPage.darkColor, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }
}

/// ─── Recent Activity ────────────────────────────────────────────────────────────
class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminDashboardPage.darkColor),
              ),
              TextButton(
                onPressed: null,
                child: const Text(
                  'View All',
                  style: TextStyle(color: AdminDashboardPage.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: const [
                _ActivityItem(
                  icon: Icons.payment,
                  iconColor: Color(0xFF50AE54),
                  title: 'New Payment Received',
                  description: 'James Smith completed payment',
                  time: '2 mins ago',
                ),
                _ActivityItem(
                  icon: Icons.calendar_today,
                  iconColor: AdminDashboardPage.primaryColor,
                  title: 'New Appointment Booked',
                  description: 'Anna Johnson booked a consultation',
                  time: '15 mins ago',
                ),
                _ActivityItem(
                  icon: Icons.person_add_outlined,
                  iconColor: Color(0xFF5C80BC),
                  title: 'New User Registration',
                  description: 'Michael Brown created an account',
                  time: '42 mins ago',
                ),
                _ActivityItem(
                  icon: Icons.cancel_outlined,
                  iconColor: Color(0xFFAD7A99),
                  title: 'Appointment Cancelled',
                  description: 'Robert Davis cancelled a consultation',
                  time: '1 hour ago',
                ),
                _ActivityItem(
                  icon: Icons.chat_bubble_outline,
                  iconColor: Color(0xFFE9B000),
                  title: 'New Support Request',
                  description: 'Sarah Wilson needs assistance',
                  time: '2 hours ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String time;

  const _ActivityItem({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AdminDashboardPage.darkColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ]),
    );
  }
}

/// ─── Upcoming Appointments ─────────────────────────────────────────────────────
class _UpcomingAppointments extends StatelessWidget {
  const _UpcomingAppointments({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AdminDashboardPage.darkColor,
                ),
              ),
              TextButton(
                onPressed: null,
                child: const Text(
                  'View All',
                  style: TextStyle(color: AdminDashboardPage.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: const [
                _AppointmentItem(name: 'Dr. Mim', type: 'Consultation', time: '10:00 AM - 10:30 AM', date: 'Today'),
                _AppointmentItem(name: 'Dr. Aziz', type: 'Follow-up', time: '11:15 AM - 11:45 AM', date: 'Today'),
                _AppointmentItem(name: 'Dr. Lim', type: 'Initial Assessment', time: '2:00 PM - 3:00 PM', date: 'Today'),
                _AppointmentItem(name: 'Dr. Tan', type: 'Consultation', time: '9:30 AM - 10:00 AM', date: 'Tomorrow'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentItem extends StatelessWidget {
  final String name;
  final String type;
  final String time;
  final String date;

  const _AppointmentItem({
    Key? key,
    required this.name,
    required this.type,
    required this.time,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AdminDashboardPage.primaryColor,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AdminDashboardPage.darkColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$type • $time',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AdminDashboardPage.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AdminDashboardPage.primaryColor,
            ),
          ),
        ),
      ]),
    );
  }
}

/// ─── Drawer Item ───────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _DrawerItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: isActive ? AdminDashboardPage.primaryColor : Colors.white70,
          size: 22),
      title: Text(label,
          style: TextStyle(
            color: isActive ? AdminDashboardPage.primaryColor : Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          )),
      trailing: isActive
          ? Container(
              width: 4,
              height: 32,
              decoration: const BoxDecoration(
                color: AdminDashboardPage.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            )
          : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
      onTap: onTap,
      tileColor:
          isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
    );
  }
} 