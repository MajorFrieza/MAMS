import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  StreamSubscription? _notificationsSub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Subscribe to all leave requests for this user (approved/rejected only)
    // Subscribe to recent leave requests for this user (approved/rejected only)
    // Limit to 200 to avoid heavy processing on large collections.
    _notificationsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('leaveRequests')
        .where('status', whereIn: ['Approved', 'Rejected'])
        .orderBy('updatedAt', descending: true)
        .limit(200)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            // Build notifications list but skip already-read items (isRead == true)
            final List<Map<String, dynamic>> list = [];
            for (final doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) continue;
              if ((data['isRead'] as bool?) == true) continue;

              final startDate = data['startDate'] as String? ?? '';
              final endDate = data['endDate'] as String? ?? '';
              final updatedAt = data['updatedAt'] as String? ?? '';

              String period = 'N/A';
              if (startDate.isNotEmpty && endDate.isNotEmpty) {
                try {
                  final start = DateTime.parse(startDate);
                  final end = DateTime.parse(endDate);
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
                  period =
                      '${months[start.month - 1]} ${start.day}-${months[end.month - 1]} ${end.day}, ${start.year}';
                } catch (_) {}
              }

              String timeAgo = '';
              if (updatedAt.isNotEmpty) {
                try {
                  final updateTime = DateTime.parse(updatedAt);
                  final now = DateTime.now();
                  final diff = now.difference(updateTime);

                  if (diff.inSeconds < 60) {
                    timeAgo = 'just now';
                  } else if (diff.inMinutes < 60) {
                    timeAgo = '${diff.inMinutes} min ago';
                  } else if (diff.inHours < 24) {
                    timeAgo =
                        '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
                  } else if (diff.inDays < 7) {
                    timeAgo =
                        '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
                  } else {
                    timeAgo =
                        '${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() > 1 ? 's' : ''} ago';
                  }
                } catch (_) {
                  timeAgo = 'recently';
                }
              }

              list.add({
                'id': doc.id,
                'status': data['status'] ?? 'Pending',
                'leaveType': data['leaveType'] ?? '',
                'dateRange': period,
                'timeAgo': timeAgo,
                'reason': data['reason'] ?? '',
              });
            }

            setState(() {
              notifications = list;
              _loading = false;
            });
          },
          onError: (error) {
            // Handle Firestore errors (e.g., missing composite index) gracefully
            if (!mounted) return;
            setState(() {
              _loading = false;
              notifications = [];
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Notifications failed to load. If this mentions an index, create it in Firebase Console.',
                ),
                action: SnackBarAction(
                  label: 'Open Console',
                  onPressed: () async {
                    // Console link (for debugging):
                    // https://console.firebase.google.com/v1/r/project/mams-dev-7e9b8/firestore/indexes?create_composite=ClRwcm9qZWN0cy9tYW1zLWRldi03ZTliOC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbGVhdmVSZXF1ZXN0cy9pbmRleGVzL18QARoKCgZzdGF0dXMQARoNCgl1cGRhdGVkQXQQAhoMCghfX25hbWVfXxAC
                  },
                ),
              ),
            );
            // Also print the error for debugging
            // ignore: avoid_print
            // ignore: avoid_print
            print('Notifications listener error: $error');
            // ignore: avoid_print
            print(
              'If index needed, create it here: https://console.firebase.google.com/v1/r/project/mams-dev-7e9b8/firestore/indexes?create_composite=ClRwcm9qZWN0cy9tYW1zLWRldi03ZTliOC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbGVhdmVSZXF1ZXN0cy9pbmRleGVzL18QARoKCgZzdGF0dXMQARoNCgl1cGRhdGVkQXQQAhoMCghfX25hbWVfXxAC',
            );
          },
        );
  }

  @override
  void dispose() {
    _notificationsSub?.cancel();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('leaveRequests');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marking notifications as read...')),
    );

    try {
      const int chunkSize = 500; // Firestore batch limit
      DocumentSnapshot? lastDoc;
      while (true) {
        Query q = col
            .where('status', whereIn: ['Approved', 'Rejected'])
            .orderBy('updatedAt', descending: true)
            .limit(chunkSize);

        if (lastDoc != null) q = q.startAfterDocument(lastDoc);

        final snap = await q.get();
        if (snap.docs.isEmpty) break;

        final batch = FirebaseFirestore.instance.batch();
        int updates = 0;
        for (final d in snap.docs) {
          final data = d.data() as Map<String, dynamic>?;
          if (data == null) continue;
          if ((data['isRead'] as bool?) == true) continue;
          batch.update(d.reference, {'isRead': true});
          updates++;
        }

        if (updates > 0) await batch.commit();

        if (snap.docs.length < chunkSize) break;
        lastDoc = snap.docs.last;
      }

      if (!mounted) return;
      setState(() {
        notifications = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark notifications: $e')),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    await _markAllAsRead();
    if (!mounted) return;
    setState(() {
      notifications = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leave Notifications',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your leave request approvals and rejections',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _loading ? null : _markAllAsRead,
                        child: const Text('Mark all read'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _loading ? null : _clearAllNotifications,
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Notifications List
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_loading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your leave approvals/rejections will appear here',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final isApproved =
                          notif['status'].toString().toLowerCase() ==
                          'approved';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isApproved ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: isApproved ? Colors.green : Colors.red,
                              width: 4,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey[200]!,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isApproved
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Icon(
                                    isApproved
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isApproved
                                        ? 'Leave Request Approved'
                                        : 'Leave Request Rejected',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    notif['leaveType'] ?? 'Leave',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notif['dateRange'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notif['timeAgo'] ?? 'recently',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
