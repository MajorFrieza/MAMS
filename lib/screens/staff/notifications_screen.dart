import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Dummy notification data
  final List<Map<String, dynamic>> notifications = [
    {
      'status': 'approved',
      'title': 'Leave Request Approved',
      'message': 'Your leave request has been approved by the admin',
      'leaveType': 'Annual Leave',
      'dateRange': 'Dec 15-16, 2025',
      'timeAgo': '2 hours ago',
    },
    {
      'status': 'approved',
      'title': 'Leave Request Approved',
      'message': 'Your leave request has been approved by the admin',
      'leaveType': 'Sick Leave',
      'dateRange': 'Dec 10, 2025',
      'timeAgo': '3 days ago',
    },
    {
      'status': 'rejected',
      'title': 'Leave Request Rejected',
      'message':
          'Your leave request has been rejected. Reason: Insufficient coverage',
      'leaveType': 'Annual Leave',
      'dateRange': 'Dec 22-24, 2025',
      'timeAgo': '5 days ago',
    },
    {
      'status': 'approved',
      'title': 'Leave Request Approved',
      'message': 'Your leave request has been approved by the admin',
      'leaveType': 'Casual Leave',
      'dateRange': 'Dec 20, 2025',
      'timeAgo': '1 week ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leave Notifications',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Track your leave request approvals and rejections',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Mark all as read
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text('Mark all as read'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Clear all
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text('Clear all'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Notifications List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final isApproved = notif['status'] == 'approved';

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
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
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with Icon
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isApproved ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                isApproved ? Icons.check_circle : Icons.cancel,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                notif['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Message
                        Text(
                          notif['message'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 12),
                        // Leave Type and Date Range
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                notif['leaveType'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              notif['dateRange'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Time Ago
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              notif['timeAgo'],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
