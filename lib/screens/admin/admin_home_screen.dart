import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final int _currentIndex = 0;
  String? _selectedFilter; // Track which status filter is selected
  bool _loading = true;
  String? _error;
  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;
  List<_StaffAttendance> _staff = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _attendanceSub;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _staffAttendanceSubs = [];

  static const _textGreen600 = Color(0xFF16A34A);
  static const _bgRed50 = Color(0xFFFEF2F2);
  static const _textRed600 = Color(0xFFDC2626);
  static const _bgBlue50 = Color(0xFFEFF6FF);
  static const _textBlue600 = Color(0xFF2563EB);
  static const _brandYellow = Color(0xFFFACC15);

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    await _attendanceSub?.cancel();
    await _cancelStaffSubscriptions();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch only first 100 staff users to avoid overloading
      final usersSnap = await firestore
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .limit(100)
          .get();
      final staffUsers = <String, _StaffAttendance>{};
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final name =
            (data['name'] ??
                    data['fullName'] ??
                    data['staffName'] ??
                    data['email'] ??
                    'Unknown')
                .toString();
        final staffId = (data['staffId'] ?? data['userID'] ?? '').toString();
        staffUsers[doc.id] = _StaffAttendance(
          userId: doc.id,
          staffId: staffId,
          name: name,
          status: 'Absent',
          note: 'No check-in recorded',
        );
      }
      setState(() {
        _staff = staffUsers.values.toList();
      });
      _listenToTodayPerStaff(firestore, staffUsers);
    } catch (e) {
      debugPrint('Admin attendance load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load attendance. ${e.toString()}';
      });
    }
  }

  void _listenToTodayPerStaff(
    FirebaseFirestore firestore,
    Map<String, _StaffAttendance> staffUsers,
  ) {
    final nowLocal = DateTime.now().toLocal();
    final startOfDayUtc =
        DateTime(nowLocal.year, nowLocal.month, nowLocal.day).toUtc();
    final endOfDayUtc = startOfDayUtc.add(const Duration(days: 1));

    // Start one listener per staff (limited to first 100 staff).
    for (final entry in staffUsers.entries) {
      final uid = entry.key;
      final sub = firestore
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
          .where('date', isLessThan: Timestamp.fromDate(endOfDayUtc))
          .limit(1)
          .snapshots()
          .listen(
        (snapshot) {
          final existing = staffUsers[uid]!;

          if (snapshot.docs.isEmpty) {
            // No attendance for today: keep as absent.
            staffUsers[uid] = _StaffAttendance(
              userId: uid,
              staffId: existing.staffId,
              name: existing.name,
              status: 'Absent',
              note: 'No check-in recorded',
            );
          } else {
            final data = snapshot.docs.first.data();
            final status = (data['status'] ?? 'Present').toString();
            final checkIn = data['checkInTime']?.toString();
            staffUsers[uid] = _StaffAttendance(
              userId: uid,
              staffId: existing.staffId,
              name: existing.name,
              status: status,
              note:
                  checkIn != null ? 'Check-in: $checkIn' : 'No check-in recorded',
            );
          }

          // Recompute counts on each update.
          int present = 0;
          int late = 0;
          for (final item in staffUsers.values) {
            final status = item.status.toLowerCase();
            if (status == 'present') present++;
            if (status == 'late') late++;
          }
          final totalStaff = staffUsers.length;
          // Late staff are still counted as present for headcount.
          final presentIncludingLate = present + late;
          final absent = totalStaff - presentIncludingLate;

          if (!mounted) return;
          setState(() {
            _presentCount = presentIncludingLate;
            _lateCount = late;
            _absentCount = absent < 0 ? 0 : absent;
            _staff = staffUsers.values.toList();
            _loading = false;
            _error = null;
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _error = 'Failed to load attendance. ${e.toString()}';
            _loading = false;
          });
        },
      );

      _staffAttendanceSubs.add(sub);
    }
  }

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

  List<_StaffAttendance> _filteredStaff() {
    if (_selectedFilter == null) return _staff;
    final filter = _selectedFilter!.toLowerCase();
    return _staff.where((s) {
      final status = s.status.toLowerCase();
      if (filter == 'present') {
        // Treat late as present in the present view.
        return status == 'present' || status == 'late';
      }
      return status == filter;
    }).toList();
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _cancelStaffSubscriptions();
    super.dispose();
  }

  Future<void> _cancelStaffSubscriptions() async {
    for (final sub in _staffAttendanceSubs) {
      await sub.cancel();
    }
    _staffAttendanceSubs.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadToday,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                  _loading
                      ? 'Loading today...'
                      : _error != null
                      ? _error!
                      : 'Today',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  GridView.builder(
                    itemCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                    itemBuilder: (context, index) {
                      final cards = [
                        (
                          value: _presentCount.toString(),
                          label: 'Present Today',
                          icon: Icons.check_circle,
                          iconColor: _textGreen600,
                          background: Colors.green.withValues(alpha: 0.1),
                          filter: 'Present',
                        ),
                        (
                          value: _absentCount.toString(),
                          label: 'Absent Today',
                          icon: Icons.cancel,
                          iconColor: _textRed600,
                          background: _bgRed50,
                          filter: 'Absent',
                        ),
                        (
                          value: _lateCount.toString(),
                          label: 'Late Today',
                          icon: Icons.access_time,
                          iconColor: Colors.orange,
                          background: _brandYellow.withValues(alpha: 0.18),
                          filter: 'Late',
                        ),
                      ];
                      final item = cards[index];
                      final isSelected = _selectedFilter == item.filter;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = _selectedFilter == item.filter
                                ? null
                                : item.filter;
                          });
                        },
                        child: _SummaryCard(
                          value: item.value,
                          label: item.label,
                          icon: item.icon,
                          iconColor: item.iconColor,
                          background: item.background,
                          isSelected: isSelected,
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
                            Icon(Icons.groups, color: Colors.grey[800]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFilter != null
                                    ? '${_selectedFilter!} Employees (${_filteredStaff().length})'
                                    : 'All Employees (${_staff.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _loadToday,
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
                        if (_staff.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No staff records found for today.',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredStaff().length,
                            separatorBuilder: (_, __) => Divider(
                              height: 16,
                              thickness: 1,
                              color: Colors.grey[200],
                            ),
                            itemBuilder: (context, index) {
                              final employee = _filteredStaff()[index];
                              return _EmployeeTile(
                                name: employee.name,
                                status: employee.status,
                                note: employee.note,
                                staffId: employee.staffId,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
    this.isSelected = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color background;
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
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
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
    this.staffId,
  });

  final String name;
  final String status;
  final String note;
  final String? staffId;

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
        return Colors.green.withValues(alpha: 0.1);
      case 'late':
        return _AdminHomeScreenState._brandYellow.withValues(alpha: 0.2);
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
              if (staffId != null && staffId!.isNotEmpty) ...[
                Text(
                  'ID: $staffId',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                note,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
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

class _StaffAttendance {
  final String userId;
  final String staffId;
  final String name;
  final String status;
  final String note;

  _StaffAttendance({
    required this.userId,
    required this.staffId,
    required this.name,
    required this.status,
    required this.note,
  });
}
