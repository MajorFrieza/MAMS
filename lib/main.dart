import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/staff/staff_home_screen.dart';

void main() {
  runApp(MAMSApp());
}

class MAMSApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAMS Prototype',
      theme: ThemeData(
        primaryColor: Colors.yellow[700],
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/staffHome': (context) => StaffHomeScreen(),
        '/adminHome': (context) => AdminHomeScreen(),
      },
    );
  }
}

// Admin Home Screen
class AdminHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Home')),
      body: Center(child: Text('Admin Screens rah sitok')),
    );
  }
}
