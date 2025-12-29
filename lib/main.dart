import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/staff/staff_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/admin_leave_screen.dart';
import 'screens/admin/admin_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        '/adminHome': (context) => const AdminHomeScreen(),
        '/adminLeave': (context) => const AdminLeaveScreen(),
        '/adminProfile': (context) => const AdminProfileScreen(),
      },
    );
  }
}
