import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String role = 'Staff'; // Default role
  bool _obscurePassword = true;
  bool _isLoading = false;
  late TextEditingController _idController;
  late TextEditingController _passwordController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String?> _lookupEmailForId(String idInput) async {
    final trimmed = idInput.trim();
    final numericId = int.tryParse(trimmed);

    // Helper to query a collection name (handles case differences like users/Users)
    Future<QuerySnapshot<Map<String, dynamic>>> query(
      String collection,
      String field,
      dynamic value,
    ) {
      return _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .limit(1)
          .get();
    }

    // Try both numeric and string matches for staffId/adminId
    final List<Future<QuerySnapshot<Map<String, dynamic>>>> queries = [];
    if (numericId != null) {
      for (final col in ['users', 'Users']) {
        queries.add(query(col, 'staffId', numericId));
        queries.add(query(col, 'adminId', numericId));
      }
    }
    // Fallback to string match in case IDs are stored as strings
    for (final col in ['users', 'Users']) {
      queries.add(query(col, 'staffId', trimmed));
      queries.add(query(col, 'adminId', trimmed));
    }

    for (final future in queries) {
      final snap = await future;
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        if (data['email'] is String && (data['email'] as String).isNotEmpty) {
          return (data['email'] as String).trim();
        }
      }
    }
    return null;
  }

  Future<void> _login() async {
    if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Resolve email from staffId/adminId
      final resolvedEmail = await _lookupEmailForId(_idController.text.trim());
      if (resolvedEmail == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID not found. Please check with admin.'),
          ),
        );
        return;
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: _passwordController.text,
      );

      // Fetch role from Firestore users collection if present
      String resolvedRole = role; // fallback to UI toggle
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user?.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        if (data['role'] is String && (data['role'] as String).isNotEmpty) {
          resolvedRole = (data['role'] as String).trim();
        }
      }

      if (!mounted) return;
      if (resolvedRole.toLowerCase() == 'admin') {
        Navigator.pushReplacementNamed(context, '/adminHome');
      } else {
        Navigator.pushReplacementNamed(context, '/staffHome');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please check your credentials.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email/ID.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email/ID format.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.yellow[100]!, Colors.yellow[50]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Mutiara Attendance Management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      'System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(MAMS)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.yellow[700],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Login Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Role Toggle Tabs
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => role = 'Staff'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: role == 'Staff'
                                            ? Colors.yellow[600]
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: role == 'Staff'
                                                ? Colors.black
                                                : Colors.grey[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Staff Login',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: role == 'Staff'
                                                  ? Colors.black
                                                  : Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => role = 'Admin'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: role == 'Admin'
                                            ? Colors.yellow[600]
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.shield,
                                            color: role == 'Admin'
                                                ? Colors.black
                                                : Colors.grey[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Admin Login',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: role == 'Admin'
                                                  ? Colors.black
                                                  : Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ID Field
                          Text(
                            role == 'Staff' ? 'Staff ID' : 'Admin ID',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _idController,
                            decoration: InputDecoration(
                              hintText: role == 'Staff'
                                  ? 'Enter Staff ID'
                                  : 'Enter Admin ID',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.grey[600],
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(
                                _isLoading ? 'Signing In...' : 'Sign In',
                              ),
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow[600],
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer
                    Text(
                      '© 2025 Mutiara Attendance Management System',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
