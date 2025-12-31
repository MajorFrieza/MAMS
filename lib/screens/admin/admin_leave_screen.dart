import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminLeaveScreen extends StatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  State<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends State<AdminLeaveScreen> {
  final int _currentIndex = 1;
  String? _selectedFilter; // Track which status filter is selected
  List<_StaffOption> _staffOptions = [];
  bool _loadingStaff = true;
  String? _staffError;

  static const _textGreen600 = Color(0xFF16A34A);
  static const _bgRed50 = Color(0xFFFEF2F2);
  static const _textRed600 = Color(0xFFDC2626);
  static const _brandYellow = Color(0xFFFACC15);
  static const _textYellow700 = Color(0xFFB45309);

  // Live data from Firestore
  List<Map<String, dynamic>> _allLeaveRequests = [];
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;
  StreamSubscription? _leaveRequestsSub;

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
  void initState() {
    super.initState();
    _loadStaff();
    _loadLeaveRequests();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loadingStaff = true;
      _staffError = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .get();
      final options = snap.docs
          .map(
            (d) => _StaffOption(
              id: d.id,
              name:
                  (d.data()['name'] ??
                          d.data()['fullName'] ??
                          d.data()['staffName'] ??
                          d.data()['email'] ??
                          'Unknown')
                      .toString(),
              staffId: (d.data()['staffId'] ?? d.data()['userID'] ?? '')
                  .toString(),
            ),
          )
          .toList();
      setState(() {
        _staffOptions = options;
        _loadingStaff = false;
      });
    } catch (e) {
      setState(() {
        _loadingStaff = false;
        _staffError = 'Failed to load staff';
      });
    }
  }

  void _showAddLeaveBalanceDialog() {
    String? selectedStaffId;
    _StaffOption? selectedStaff;
    String? selectedLeaveType;
    final daysController = TextEditingController();
    final leaveTypes = ['Annual', 'Compassionate'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Leave Balance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add leave balance for a staff member',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              if (_loadingStaff)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_staffError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _staffError!,
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                      TextButton(
                        onPressed: _loadStaff,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<_StaffOption>(
                  initialValue: selectedStaff,
                  hint: const Text('Select staff'),
                  items: _staffOptions
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    selectedStaff = value;
                    selectedStaffId = value?.id;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedLeaveType,
                hint: const Text('Select leave type'),
                items: leaveTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  selectedLeaveType = value;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter number of days to add',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              // Validate inputs first
              if (selectedStaffId == null || selectedStaffId!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select a staff member')),
                );
                return;
              }
              if (selectedLeaveType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select a leave type')),
                );
                return;
              }
              if (daysController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter number of days')),
                );
                return;
              }

              try {
                final days = int.parse(daysController.text);
                final staffRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(selectedStaffId!);

                staffRef
                    .get()
                    .then((staffDoc) async {
                      if (!staffDoc.exists) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Staff not found')),
                          );
                        }
                        return;
                      }

                      final currentBalances =
                          (staffDoc.data()?['leaveBalances'] as Map?) ?? {};
                      final currentDays =
                          (currentBalances[selectedLeaveType] as int?) ?? 0;

                      await staffRef.set({
                        'leaveBalances': {
                          ...currentBalances,
                          selectedLeaveType!: currentDays + days,
                        },
                      }, SetOptions(merge: true));

                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added $days $selectedLeaveType days for ${selectedStaff?.displayName ?? selectedStaffId}',
                            ),
                          ),
                        );
                      }
                    })
                    .catchError((e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    });
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add Balance'),
          ),
        ],
      ),
    );
  }

  void _loadLeaveRequests() {
    // Subscribe to all leave requests from all users
    _leaveRequestsSub = FirebaseFirestore.instance
        .collectionGroup('leaveRequests')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _allLeaveRequests = snapshot.docs.map((doc) {
                final data = doc.data();
                final startDate = data['startDate'] as String? ?? '';
                final endDate = data['endDate'] as String? ?? '';
                int days = 0;
                try {
                  if (startDate.isNotEmpty && endDate.isNotEmpty) {
                    final start = DateTime.parse(startDate);
                    final end = DateTime.parse(endDate);
                    days = end.difference(start).inDays + 1;
                  }
                } catch (e) {
                  days = 0;
                }

                return {
                  'docId': doc.id,
                  'staffId': doc.reference.parent.parent?.id ?? 'Unknown',
                  'staffName': data['staffName'] ?? 'Unknown',
                  'status': data['status'] ?? 'Pending',
                  'leaveType': data['leaveType'] ?? '',
                  'startDate': startDate,
                  'endDate': endDate,
                  'days': days,
                  'appliedDate': data['appliedDate'] ?? '',
                  'reason': data['reason'] ?? '',
                  'attachmentUrl': data['attachmentUrl'],
                  'attachmentName': data['attachmentName'],
                };
              }).toList();

              // Count by status
              _pendingCount = _allLeaveRequests
                  .where((r) => r['status'] == 'Pending')
                  .length;
              _approvedCount = _allLeaveRequests
                  .where((r) => r['status'] == 'Approved')
                  .length;
              _rejectedCount = _allLeaveRequests
                  .where((r) => r['status'] == 'Rejected')
                  .length;
            });
          }
        });
  }

  Future<void> _updateLeaveStatus(
    String staffId,
    String docId,
    String newStatus,
  ) async {
    try {
      // Fetch the leave request to know days and type
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(staffId)
          .collection('leaveRequests')
          .doc(docId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leave request not found')),
          );
        }
        return;
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final startDateStr = data['startDate'] as String? ?? '';
      final endDateStr = data['endDate'] as String? ?? '';
      final leaveType = (data['leaveType'] as String? ?? '').toLowerCase();

      int days = 0;
      try {
        if (startDateStr.isNotEmpty && endDateStr.isNotEmpty) {
          final start = DateTime.parse(startDateStr);
          final end = DateTime.parse(endDateStr);
          days = end.difference(start).inDays + 1;
        }
      } catch (_) {
        days = 0;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(staffId)
          .collection('leaveRequests')
          .doc(docId)
          .update({
            'status': newStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          });

      // If approved, decrement the user's leave balance
      if (newStatus.toLowerCase() == 'approved' && days > 0) {
        final balanceKey = leaveType.contains('annual')
            ? 'Annual'
            : leaveType.contains('compassionate')
            ? 'Compassionate'
            : 'Annual';
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(staffId);
        await FirebaseFirestore.instance.runTransaction((txn) async {
          final snap = await txn.get(userRef);
          final data = snap.data() ?? {};
          final balances = (data['leaveBalances'] as Map?) ?? {};
          final current = (balances[balanceKey] as int?) ?? 0;
          final updated = current - days;
          txn.update(userRef, {
            'leaveBalances': {
              ...balances,
              balanceKey: updated < 0 ? 0 : updated,
            },
          });
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Leave request $newStatus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _leaveRequestsSub?.cancel();
    super.dispose();
  }

  Future<void> _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open attachment')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open attachment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build summary cards dynamically
    final summaryCards = [
      {
        'value': '$_pendingCount',
        'label': 'Pending Requests',
        'icon': Icons.access_time,
        'iconColor': _textYellow700,
        'background': _brandYellow.withValues(alpha: 0.2),
      },
      {
        'value': '$_approvedCount',
        'label': 'Approved',
        'icon': Icons.check_circle,
        'iconColor': _textGreen600,
        'background': Colors.green.withValues(alpha: 0.1),
      },
      {
        'value': '$_rejectedCount',
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
        'background': Colors.blueGrey.withValues(alpha: 0.08),
        'isAdd': true,
      },
    ];

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
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                itemCount: summaryCards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final item = summaryCards[index];
                  final isAdd = (item['isAdd'] as bool?) ?? false;
                  final label = item['label'] as String;
                  final statusFilter = !isAdd
                      ? label.contains('Pending')
                            ? 'Pending'
                            : label.contains('Approved')
                            ? 'Approved'
                            : label.contains('Rejected')
                            ? 'Rejected'
                            : null
                      : null;
                  final isSelected = _selectedFilter == statusFilter;

                  return GestureDetector(
                    onTap: isAdd
                        ? _showAddLeaveBalanceDialog
                        : statusFilter != null
                        ? () {
                            setState(() {
                              _selectedFilter = _selectedFilter == statusFilter
                                  ? null
                                  : statusFilter;
                            });
                          }
                        : null,
                    child: _SummaryCard(
                      value: item['value'] as String,
                      label: item['label'] as String,
                      icon: item['icon'] as IconData,
                      iconColor: item['iconColor'] as Color,
                      background: item['background'] as Color,
                      isAdd: isAdd,
                      isSelected: !isAdd && isSelected,
                    ),
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
                        Icon(
                          Icons.description_outlined,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedFilter != null
                                ? '$_selectedFilter Leave Requests (${_allLeaveRequests.where((e) => e['status'] == _selectedFilter).length})'
                                : 'All Leave Requests (${_allLeaveRequests.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_selectedFilter != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = null;
                              });
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedFilter != null
                          ? _allLeaveRequests
                                .where((e) => e['status'] == _selectedFilter)
                                .length
                          : _allLeaveRequests.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 20,
                        thickness: 1,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final filteredRequests = _selectedFilter != null
                            ? _allLeaveRequests
                                  .where((e) => e['status'] == _selectedFilter)
                                  .toList()
                            : _allLeaveRequests;
                        final leave = filteredRequests[index];

                        // Format dates
                        String formatDate(String dateStr) {
                          try {
                            final date = DateTime.parse(dateStr);
                            const months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec',
                            ];
                            return '${months[date.month - 1]} ${date.day}, ${date.year}';
                          } catch (_) {
                            return dateStr;
                          }
                        }

                        final startDate = leave['startDate'] as String? ?? '';
                        final endDate = leave['endDate'] as String? ?? '';
                        final period =
                            startDate.isNotEmpty && endDate.isNotEmpty
                            ? '${formatDate(startDate)} - ${formatDate(endDate)}'
                            : 'N/A';

                        return _LeaveCard(
                          name: leave['staffName'] as String,
                          status: leave['status'] as String,
                          type: leave['leaveType'] as String,
                          period: period,
                          applied: formatDate(
                            leave['appliedDate'] as String? ?? '',
                          ),
                          attachmentUrl: leave['attachmentUrl'] as String?,
                          attachmentName: leave['attachmentName'] as String?,
                          onViewAttachment: leave['attachmentUrl'] != null
                              ? () => _openAttachment(
                                leave['attachmentUrl'] as String,
                              )
                              : null,
                          onApprove: () => _updateLeaveStatus(
                            leave['staffId'] as String,
                            leave['docId'] as String,
                            'Approved',
                          ),
                          onReject: () => _updateLeaveStatus(
                            leave['staffId'] as String,
                            leave['docId'] as String,
                            'Rejected',
                          ),
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
    this.isSelected = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final bool isAdd;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
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
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
    this.attachmentUrl,
    this.attachmentName,
    this.onViewAttachment,
    required this.onApprove,
    required this.onReject,
  });

  final String name;
  final String status;
  final String type;
  final String period;
  final String applied;
  final String? attachmentUrl;
  final String? attachmentName;
  final VoidCallback? onViewAttachment;
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
        return Colors.green.withValues(alpha: 0.1);
      case 'pending':
        return _AdminLeaveScreenState._brandYellow.withValues(alpha: 0.2);
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
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
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
                    style: TextStyle(fontSize: 13, color: Colors.grey),
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
                    style: TextStyle(fontSize: 13, color: Colors.grey),
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
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              applied,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (attachmentUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: onViewAttachment,
              icon: const Icon(Icons.insert_drive_file),
              label: Text(
                attachmentName ?? 'View attachment',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
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

class _StaffOption {
  final String id;
  final String staffId;
  final String name;

  _StaffOption({required this.id, required this.staffId, required this.name});

  String get displayName => staffId.isNotEmpty ? '$name (ID: $staffId)' : name;
}
