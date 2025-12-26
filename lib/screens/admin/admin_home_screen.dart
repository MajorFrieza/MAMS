import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  static const _textGreen600 = Color(0xFF16A34A);
  static const _bgRed50 = Color(0xFFFEF2F2);
  static const _textRed600 = Color(0xFFDC2626);
  static const _bgBlue50 = Color(0xFFEFF6FF);
  static const _textBlue600 = Color(0xFF2563EB);
  static const _brandYellow = Color(0xFFFACC15);

  final List<Map<String, dynamic>> _summaryCards = [
    {
      'value': '3',
      'label': 'Present Today',
      'icon': Icons.check_circle,
      'iconColor': _textGreen600,
      'background': Colors.green.withOpacity(0.1),
    },
    {
      'value': '5',
      'label': 'Absent Today',
      'icon': Icons.cancel,
      'iconColor': _textRed600,
      'background': _bgRed50,
    },
    {
      'value': '2',
      'label': 'Late Today',
      'icon': Icons.access_time,
      'iconColor': Colors.orange,
      'background': _brandYellow.withOpacity(0.18),
    },
  ];

  final List<Map<String, String>> _employees = [
    {
      'name': 'Emily Davis',
      'status': 'Absent',
      'note': 'No check-in recorded',
    },
    {
      'name': 'David Thompson',
      'status': 'Absent',
      'note': 'No check-in recorded',
    },
    {
      'name': 'Rachel Green',
      'status': 'Absent',
      'note': 'No check-in recorded',
    },
    {
      'name': 'Tom Wilson',
      'status': 'Absent',
      'note': 'No check-in recorded',
    },
    {
      'name': 'Anna Martinez',
      'status': 'Absent',
      'note': 'No check-in recorded',
    },
    {
      'name': 'Michael Chen',
      'status': 'Late',
      'note': 'Check-in: 09:20 AM  •  20 min late',
    },
    {
      'name': 'James Brown',
      'status': 'Late',
      'note': 'Check-in: 09:15 AM  •  15 min late',
    },
    {
      'name': 'John Smith',
      'status': 'Present',
      'note': 'Check-in: 08:45 AM',
    },
    {
      'name': 'Sarah Williams',
      'status': 'Present',
      'note': 'Check-in: 08:55 AM',
    },
    {
      'name': 'Robert Johnson',
      'status': 'Present',
      'note': 'Check-in: 08:50 AM',
    },
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        // already here
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/adminLeave');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/adminProfile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Review',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'December 1, 2025',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                itemCount: _summaryCards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final item = _summaryCards[index];
                  return _SummaryCard(
                    value: item['value'] as String,
                    label: item['label'] as String,
                    icon: item['icon'] as IconData,
                    iconColor: item['iconColor'] as Color,
                    background: item['background'] as Color,
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.groups, color: Colors.grey[800]),
                        const SizedBox(width: 8),
                        Text(
                          'All Employees (${_employees.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _employees.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 16,
                        thickness: 1,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final employee = _employees[index];
                        return _EmployeeTile(
                          name: employee['name']!,
                          status: employee['status']!,
                          note: employee['note']!,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _brandYellow,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Leave',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.name,
    required this.status,
    required this.note,
  });

  final String name;
  final String status;
  final String note;

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'present':
        return _AdminHomeScreenState._textGreen600;
      case 'late':
        return Colors.orange;
      case 'pending':
        return _AdminHomeScreenState._textBlue600;
      default:
        return _AdminHomeScreenState._textRed600;
    }
  }

  Color _statusBackground() {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green.withOpacity(0.1);
      case 'late':
        return _AdminHomeScreenState._brandYellow.withOpacity(0.2);
      case 'pending':
        return _AdminHomeScreenState._bgBlue50;
      default:
        return _AdminHomeScreenState._bgRed50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final statusBg = _statusBackground();
    final lowerStatus = status.toLowerCase();
    final iconData = lowerStatus == 'present'
        ? Icons.check_circle
        : lowerStatus == 'late'
            ? Icons.access_time
            : Icons.cancel;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: statusBg,
          child: Icon(iconData, color: statusColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.4)),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
