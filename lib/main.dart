import 'package:flutter/material.dart';
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

// Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String role = 'Staff'; // Default toggle

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToggleButtons(
              children: [Text('Staff'), Text('Admin')],
              isSelected: [role == 'Staff', role == 'Admin'],
              onPressed: (index) {
                setState(() {
                  role = index == 0 ? 'Staff' : 'Admin';
                });
              },
            ),
            SizedBox(height: 20),
            TextField(decoration: InputDecoration(labelText: 'Username')),
            TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () {
                if (role == 'Staff') {
                  Navigator.pushReplacementNamed(context, '/staffHome');
                } else {
                  Navigator.pushReplacementNamed(context, '/adminHome');
                }
              },
            ),
          ],
        ),
      ),
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
