import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/attendance_database.dart';
import '../../models/attendance_record.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AttendanceDatabase _attendanceDb = AttendanceDatabase();
  List<AttendanceRecord> _history = [];
  bool _loadingHistory = true;
  String? _historyError;

  bool _loadingProfile = true;
  String? _profileError;

  String name = 'John Anderson';
  String staffId = '2024001';
  String role = 'Senior Developer';
  String email = 'john.anderson@company.com';
  String joinDate = 'Jan 15, 2024';
  String status = 'Active';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadHistory();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _loadingProfile = false;
          _profileError = 'Not signed in';
        });
        return;
      }

      final usersColl = FirebaseFirestore.instance.collection('users');
      final upperUsersColl = FirebaseFirestore.instance.collection('Users');
      DocumentSnapshot<Map<String, dynamic>> snap =
          await usersColl.doc(uid).get();
      if (!snap.exists) {
        snap = await upperUsersColl.doc(uid).get();
      }
      final data = snap.data() ?? {};

      setState(() {
        name = (data['name'] ??
                data['fullName'] ??
                data['staffName'] ??
                data['email'] ??
                name)
            .toString();
        staffId = (data['staffId'] ?? data['employeeId'] ?? data['userID'] ?? staffId)
            .toString();
        role = (data['role'] ?? role).toString();
        email = (data['email'] ?? email).toString();
        // Prefer explicit joinDate/createdAt fields, fall back to auth creation time
        final createdAtField = data['joinDate'] ?? data['createdAt'];
        if (createdAtField != null) {
          try {
            if (createdAtField is Timestamp) {
              final dt = createdAtField.toDate();
              joinDate = _formatDate(dt);
            } else if (createdAtField is String) {
              final dt = DateTime.parse(createdAtField);
              joinDate = _formatDate(dt);
            } else if (createdAtField is DateTime) {
              joinDate = _formatDate(createdAtField);
            }
          } catch (_) {
            // ignore parse errors, fallback below
          }
        } else if (FirebaseAuth.instance.currentUser?.metadata.creationTime != null) {
          final dt = FirebaseAuth.instance.currentUser!.metadata.creationTime!;
          joinDate = _formatDate(dt);
        }
        status = (data['status'] ?? status).toString();
        _loadingProfile = false;
      });
    } catch (e) {
      setState(() {
        _loadingProfile = false;
        _profileError = 'Failed to load profile';
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final records = await _attendanceDb.getAllAttendance();
      setState(() {
        _history = records;
        _loadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingHistory = false;
        _historyError = 'Could not load attendance history.';
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Late':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  String _initials(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month]} ${date.day}, ${date.year}';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_loadingProfile)
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_profileError != null)
                          Text(
                            _profileError!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          )
                        else
                          Text(
                            'Manage your account',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile Card with Avatar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.yellow[400],
                        child: Text(
                          _initials(name),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Account Information Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _infoRow(Icons.person, 'Employee ID', staffId),
                      const SizedBox(height: 12),
                      _infoRow(Icons.email, 'Email', email),
                      const SizedBox(height: 12),
                      _infoRow(Icons.calendar_today, 'Join Date', joinDate),
                      const SizedBox(height: 12),
                      _infoRow(Icons.info, 'Status', status),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Attendance History Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingHistory)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_historyError != null)
                        Text(
                          _historyError!,
                          style: TextStyle(color: Colors.red[700]),
                        )
                      else if (_history.isEmpty)
                        Text(
                          'No records available.',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _history.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final record = _history[index];
                            final statusColor = _getStatusColor(record.status);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(record.date),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        record.status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      (record.checkInTime != null &&
                                              record.checkOutTime != null)
                                          ? '${record.checkInTime} - ${record.checkOutTime}'
                                          : 'N/A',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _workingHours(record),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button
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
                const SizedBox(height: 20),
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
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
