import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveCalendar extends StatefulWidget {
  final bool
  adminView; // If true, show all staff leave; if false, show user's leave
  final String? staffId; // For admin view to see specific staff

  const LeaveCalendar({super.key, this.adminView = false, this.staffId});

  @override
  State<LeaveCalendar> createState() => _LeaveCalendarState();
}

class _LeaveCalendarState extends State<LeaveCalendar> {
  DateTime selectedMonth = DateTime.now();
  Set<DateTime> approvedLeaveDates = {};

  @override
  void initState() {
    super.initState();
    _loadApprovedLeaves();
  }

  void _loadApprovedLeaves() async {
    try {
      final String userId =
          widget.staffId ?? FirebaseAuth.instance.currentUser!.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('leaveRequests')
          .where('status', isEqualTo: 'Approved')
          .get();

      Set<DateTime> dates = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final startDate = data['startDate'] as String?;
        final endDate = data['endDate'] as String?;

        if (startDate != null && endDate != null) {
          try {
            final start = DateTime.parse(startDate);
            final end = DateTime.parse(endDate);

            // Add all dates in range
            for (
              DateTime d = start;
              d.isBefore(end.add(const Duration(days: 1)));
              d = d.add(const Duration(days: 1))
            ) {
              dates.add(DateTime(d.year, d.month, d.day));
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          approvedLeaveDates = dates;
        });
      }
    } catch (e) {
      debugPrint('Error loading approved leaves: $e');
    }
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = last.day;
    final firstWeekday = first.weekday;

    List<DateTime> days = [];
    // Add previous month's days
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(first.subtract(Duration(days: i)));
    }
    // Add current month's days
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    // Add next month's days
    final remaining = 42 - days.length;
    for (int i = 1; i <= remaining; i++) {
      days.add(DateTime(month.year, month.month + 1, i));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(selectedMonth);
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      selectedMonth = DateTime(
                        selectedMonth.year,
                        selectedMonth.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  '${_monthName(selectedMonth.month)} ${selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      selectedMonth = DateTime(
                        selectedMonth.year,
                        selectedMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weekday Headers
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map(
                    (day) => Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            // Calendar Days
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: days.map((day) {
                final isCurrentMonth = day.month == selectedMonth.month;
                final isLeaveDay = approvedLeaveDates.contains(
                  DateTime(day.year, day.month, day.day),
                );
                final isToday = day == todayNormalized;

                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isLeaveDay
                        ? Colors.green[100]
                        : isToday
                        ? Colors.blue[100]
                        : Colors.transparent,
                    border: isToday
                        ? Border.all(color: Colors.blue, width: 2)
                        : isLeaveDay
                        ? Border.all(color: Colors.green[600]!, width: 1)
                        : Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCurrentMonth
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isCurrentMonth ? Colors.black : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Legend
            Wrap(
              spacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        border: Border.all(color: Colors.green[600]!, width: 1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Approved Leave',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Today', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
