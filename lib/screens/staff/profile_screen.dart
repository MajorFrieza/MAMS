import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = 'John Anderson';
  String staffId = '2024001';
  String role = 'Senior Developer';
  String email = 'john.anderson@company.com';
  String phone = '+1 (555) 123-4567';
  String department = 'Engineering';
  String joinDate = 'Jan 15, 2024';
  String status = 'Active';

  // Attendance history
  final List<Map<String, dynamic>> attendanceHistory = [
    {
      'date': 'Dec 10, 2025',
      'checkIn': '09:00 AM',
      'checkOut': '05:30 PM',
      'status': 'Present',
      'hours': '8.5h',
    },
    {
      'date': 'Dec 9, 2025',
      'checkIn': '08:55 AM',
      'checkOut': '05:15 PM',
      'status': 'Present',
      'hours': '8.3h',
    },
    {
      'date': 'Dec 8, 2025',
      'checkIn': '09:10 AM',
      'checkOut': '05:45 PM',
      'status': 'Present',
      'hours': '8.6h',
    },
    {
      'date': 'Dec 7, 2025',
      'checkIn': null,
      'checkOut': null,
      'status': 'Absent',
      'hours': '0h',
    },
    {
      'date': 'Dec 6, 2025',
      'checkIn': '09:05 AM',
      'checkOut': '05:20 PM',
      'status': 'Present',
      'hours': '8.2h',
    },
    {
      'date': 'Dec 5, 2025',
      'checkIn': '09:15 AM',
      'checkOut': '05:30 PM',
      'status': 'Late',
      'hours': '8.2h',
    },
    {
      'date': 'Dec 4, 2025',
      'checkIn': '08:50 AM',
      'checkOut': '05:25 PM',
      'status': 'Present',
      'hours': '8.6h',
    },
  ];

  void _openEditProfile() {
    final nameController = TextEditingController(text: name);
    final roleController = TextEditingController(text: role);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);
    final deptController = TextEditingController(text: department);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: roleController,
              decoration: InputDecoration(labelText: 'Role'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: deptController,
              decoration: InputDecoration(labelText: 'Department'),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        name = nameController.text;
                        role = roleController.text;
                        email = emailController.text;
                        phone = phoneController.text;
                        department = deptController.text;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text('Save'),
                  ),
                ),
                SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel'),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
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
    if (parts.length == 1) return parts[0][0];
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your account',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: _openEditProfile,
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Profile Card with Avatar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.yellow[400],
                        child: Text(
                          _initials(name),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Name
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      // Role
                      Text(
                        role,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(
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
                SizedBox(height: 20),

                // Account Information Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _infoRow(Icons.person, 'Employee ID', staffId),
                      SizedBox(height: 12),
                      _infoRow(Icons.email, 'Email', email),
                      SizedBox(height: 12),
                      _infoRow(Icons.phone, 'Phone', phone),
                      SizedBox(height: 12),
                      _infoRow(Icons.business, 'Department', department),
                      SizedBox(height: 12),
                      _infoRow(Icons.calendar_today, 'Join Date', joinDate),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Attendance History Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: attendanceHistory.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 16),
                        itemBuilder: (context, index) {
                          final record = attendanceHistory[index];
                          final statusColor = _getStatusColor(record['status']);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    record['date'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      record['status'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    record['checkIn'] != null
                                        ? '${record['checkIn']} - ${record['checkOut']}'
                                        : 'N/A',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    record['hours'],
                                    style: TextStyle(
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
                SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[600],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 20),
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
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
