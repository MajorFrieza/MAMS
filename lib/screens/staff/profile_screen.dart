import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Simple profile fields (cached/default) shown immediately
  String name = 'Loading...';
  String staffId = '--';
  String role = '--';
  String email = '--';
  String joinDate = '--';
  String status = 'Active';

  // Firestore-backed state
  bool _profileLoading = false;
  bool _historyLoading = false;
  bool _hasMoreHistory = true;
  String? _errorMessage;
  final List<AttendanceRecord> _history = [];
  DocumentSnapshot? _lastHistoryDoc;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    // Auto-load profile in background but do not block UI.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _loadProfileSafely();
    });
  }

  Future<void> _loadProfileSafely() async {
    if (_profileLoading) return;
    setState(() {
      _profileLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not signed in');
      final uid = user.uid;

      // Try both 'users' and 'Users' collections to be tolerant of naming.
      final usersColl = FirebaseFirestore.instance.collection('users');
      final upperUsersColl = FirebaseFirestore.instance.collection('Users');

      DocumentSnapshot<Map<String, dynamic>> doc = await usersColl
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 6));
      if (!doc.exists) {
        doc = await upperUsersColl
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 6));
      }

      if (!mounted) return;
      final data = doc.data() ?? {};
      setState(() {
        name =
            (data['displayName'] as String?) ??
            (data['name'] as String?) ??
            (data['fullName'] as String?) ??
            (user.displayName ??
                (user.email != null ? user.email!.split('@')[0] : 'Unknown'));
        email = (data['email'] as String?) ?? (user.email ?? '--');
        staffId =
            (data['employeeId'] as String?) ??
            (data['staffId'] as String?) ??
            '--';
        role = (data['role'] as String?) ?? '--';
        joinDate = _resolveJoinDate(data, user);
        status = (data['status'] as String?) ?? 'Active';
      });

      // Load initial history page
      await _loadHistoryPage();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile';
        });
      }
      // Do not crash; show message
    } finally {
      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistoryPage() async {
    if (_historyLoading || !_hasMoreHistory) return;
    setState(() => _historyLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not signed in');
      final uid = user.uid;

      Query q = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .orderBy('date', descending: true)
          .limit(_pageSize);

      if (_lastHistoryDoc != null) q = q.startAfterDocument(_lastHistoryDoc!);

      final snap = await q.get().timeout(const Duration(seconds: 6));
      if (!mounted) return;

      final docs = snap.docs;
      if (docs.isEmpty) {
        setState(() => _hasMoreHistory = false);
        return;
      }

      final newRecords = docs.map((d) {
        final data = d.data();
        return AttendanceRecord.fromMap(data as Map<String, dynamic>, d.id);
      }).toList();

      setState(() {
        _history.addAll(newRecords);
        _lastHistoryDoc = docs.last;
        if (docs.length < _pageSize) _hasMoreHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load history';
      });
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  String _initials(String fullName) {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  DateTime? _parseDynamicDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _prettyDate(DateTime d) {
    const months = [
      '',
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
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  String _resolveJoinDate(Map<String, dynamic> data, User user) {
    // Priority: explicit joinDate -> createdAt -> auth creationTime -> '--'
    final jd = _parseDynamicDate(data['joinDate']);
    if (jd != null) return _prettyDate(jd);

    final created = _parseDynamicDate(data['createdAt']);
    if (created != null) return _prettyDate(created);

    final metaCreated = user.metadata.creationTime;
    if (metaCreated != null) return _prettyDate(metaCreated);

    return '--';
  }

  DateTime? _parseTimeString(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final period = parts[1].toUpperCase();
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  String _workingHours(AttendanceRecord rec) {
    final checkIn = _parseTimeString(rec.checkInTime);
    final checkOut = _parseTimeString(rec.checkOutTime);
    if (checkIn == null || checkOut == null) return '--';
    final diff = checkOut.difference(checkIn);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _profileLoading ? null : () => _loadProfileSafely(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _lastHistoryDoc = null;
          _history.clear();
          _hasMoreHistory = true;
          await _loadProfileSafely();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.yellow[400],
                        child: Text(
                          _initials(name),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              role,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Account info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _infoRow(Icons.badge, 'Employee ID', staffId),
                      const SizedBox(height: 6),
                      _infoRow(Icons.calendar_today, 'Join Date', joinDate),
                      const SizedBox(height: 6),
                      _infoRow(Icons.info, 'Status', status),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Error or loading indicator
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Attendance history
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance History',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_history.isEmpty && _historyLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_history.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No recent records. Pull to refresh or tap load.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      else
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _history.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 12),
                          itemBuilder: (context, i) {
                            final rec = _history[i];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(rec.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${rec.checkInTime ?? '--'} • ${rec.checkOutTime ?? '--'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      rec.status,
                                      style: TextStyle(
                                        color: _getStatusColor(rec.status),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _workingHours(rec),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),

                      const SizedBox(height: 8),
                      if (_hasMoreHistory)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _historyLoading
                                ? null
                                : () => _loadHistoryPage(),
                            child: _historyLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Load more'),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[600],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      navigator.pushReplacementNamed('/');
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
