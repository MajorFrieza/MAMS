import 'package:flutter/material.dart';
import 'leave_screen.dart';
import 'clock_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  @override
  _StaffHomeScreenState createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    LeaveScreen(),
    ClockScreen(),
    NotificationsScreen(),
    ProfileScreen(),
    Center(child: Text('Clock In/Out')), // placeholder
    Center(child: Text('Notifications')), // placeholder
    Center(child: Text('Profile')), // placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.yellow[700],
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Leave',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Clock In/Out',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
