import 'package:flutter/material.dart';

class AdminLeaveScreen extends StatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  State<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends State<AdminLeaveScreen> {
  int _currentIndex = 1;

  static const _textGreen600 = Color(0xFF16A34A);
  static const _bgRed50 = Color(0xFFFEF2F2);
  static const _textRed600 = Color(0xFFDC2626);
  static const _bgBlue50 = Color(0xFFEFF6FF);
  static const _textBlue600 = Color(0xFF2563EB);
  static const _brandYellow = Color(0xFFFACC15);
  static const _textYellow700 = Color(0xFFB45309);

  final List<Map<String, dynamic>> _summaryCards = [
    {
      'value': '3',
      'label': 'Pending Requests',
      'icon': Icons.access_time,
      'iconColor': _textYellow700,
      'background': _brandYellow.withOpacity(0.2),
    },
    {
      'value': '1',
      'label': 'Approved',
      'icon': Icons.check_circle,
      'iconColor': _textGreen600,
      'background': Colors.green.withOpacity(0.1),
    },
    {
      'value': '1',
      'label': 'Rejected',
      'icon': Icons.cancel,
      'iconColor': _textRed600,
      'background': _bgRed50,
    },
    {
      'value': '+',
      'label': 'Add\nLeave Balance',
      'icon': Icons.add,
      'iconColor': Colors.blueGrey,
      'background': Colors.blueGrey.withOpacity(0.08),
      'isAdd': true,
    },
  ];

  final List<Map<String, String>> _leaveRequests = [
    {
      'name': 'John Anderson',
      'status': 'Pending',
      'type': 'Vacation Leave',
      'period': 'Dec 15, 2025 - Dec 16, 2025',
      'applied': 'Nov 28, 2025',
    },
    {
      'name': 'Michael Chen',
      'status': 'Approved',
      'type': 'Personal Leave',
      'period': 'Jan 2, 2026 - Jan 5, 2026',
      'applied': 'Nov 25, 2025',
    },
    {
      'name': 'Emily Davis',
      'status': 'Rejected',
      'type': 'Emergency Leave',
      'period': 'Nov 28, 2025 - Nov 28, 2025',
      'applied': 'Nov 27, 2025',
    },
    {
      'name': 'Robert Johnson',
      'status': 'Pending',
      'type': 'Vacation Leave',
      'period': 'Dec 20, 2025 - Dec 24, 2025',
      'applied': 'Nov 30, 2025',
    },
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/adminHome');
        break;
      case 1:
        // already here
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
                'Leave Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review and manage employee leave requests',
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
                    isAdd: (item['isAdd'] as bool?) ?? false,
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
                        Icon(Icons.description_outlined,
                            color: Colors.grey[800]),
                        const SizedBox(width: 8),
                        Text(
                          'All Leave Requests (${_leaveRequests.length})',
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
                      itemCount: _leaveRequests.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 20,
                        thickness: 1,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final leave = _leaveRequests[index];
                        return _LeaveCard(
                          name: leave['name']!,
                          status: leave['status']!,
                          type: leave['type']!,
                          period: leave['period']!,
                          applied: leave['applied']!,
                          onApprove: () {},
                          onReject: () {},
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
    this.isAdd = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: isAdd
          ? Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: background,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Leave Balance',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
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

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({
    required this.name,
    required this.status,
    required this.type,
    required this.period,
    required this.applied,
    required this.onApprove,
    required this.onReject,
  });

  final String name;
  final String status;
  final String type;
  final String period;
  final String applied;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'approved':
        return _AdminLeaveScreenState._textGreen600;
      case 'pending':
        return _AdminLeaveScreenState._textYellow700;
      default:
        return _AdminLeaveScreenState._textRed600;
    }
  }

  Color _statusBackground() {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.withOpacity(0.1);
      case 'pending':
        return _AdminLeaveScreenState._brandYellow.withOpacity(0.2);
      default:
        return _AdminLeaveScreenState._bgRed50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final statusBg = _statusBackground();
    final isPending = status.toLowerCase() == 'pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    status.toLowerCase() == 'approved'
                        ? Icons.check_circle
                        : status.toLowerCase() == 'pending'
                            ? Icons.access_time
                            : Icons.cancel,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leave Type',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Period',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    period,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Applied On',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              applied,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isPending)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.red.shade200),
                    foregroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
