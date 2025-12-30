import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  static const _brandYellow = Color(0xFFFACC15);
  static const _textYellow700 = Color(0xFFB45309);
  final int _currentIndex = 2;

  // Profile state variables
  String _adminName = 'Admin User';
  String _adminEmail = 'admin@company.com';
  String _adminId = 'ADMIN-001';
  String _role = 'admin';
  bool _loadingProfile = true;
  String? _profileError;
  bool _creatingStaff = false;
  bool _deletingStaff = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

      // Primary: lower-case 'users', fallback to 'Users'
      final usersColl = FirebaseFirestore.instance.collection('users');
      final upperUsersColl = FirebaseFirestore.instance.collection('Users');

      DocumentSnapshot<Map<String, dynamic>> snap =
          await usersColl.doc(uid).get();
      if (!snap.exists) {
        snap = await upperUsersColl.doc(uid).get();
      }

      final data = snap.data() ?? {};

      setState(() {
        _adminName =
            (data['name'] ?? data['fullName'] ?? data['adminName'] ?? _adminName)
                .toString();
        _adminEmail = (data['email'] ?? _adminEmail).toString();
        _adminId = (data['adminId'] ?? data['adminID'] ?? _adminId).toString();
        _role = (data['role'] ?? _role).toString();
        _loadingProfile = false;
      });
    } catch (e) {
      setState(() {
        _loadingProfile = false;
        _profileError = 'Failed to load profile';
      });
    }
  }

  void _showCreateStaffDialog() {
    final nameController = TextEditingController();
    final staffIdController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Staff Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Staff ID and password for a new staff member',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Staff Name',
                  hintText: 'Enter staff name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: staffIdController,
                decoration: InputDecoration(
                  labelText: 'Staff ID',
                  hintText: 'e.g., 2024001',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter staff email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandYellow,
              foregroundColor: Colors.black,
            ),
            onPressed: _creatingStaff
                ? null
                : () async {
                    final name = nameController.text.trim();
                    final staffId = staffIdController.text.trim();
                    final email = emailController.text.trim();
                    final password = passwordController.text;

                    if (name.isEmpty ||
                        staffId.isEmpty ||
                        email.isEmpty ||
                        password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _creatingStaff = true;
                    });

                    Navigator.pop(ctx);
                    final result = await _createStaffAccount(
                      name: name,
                      staffId: staffId,
                      email: email,
                      password: password,
                    );
                    if (mounted) {
                      setState(() {
                        _creatingStaff = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                    }
                  },
            child: _creatingStaff
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  Future<String> _createStaffAccount({
    required String name,
    required String staffId,
    required String email,
    required String password,
  }) async {
    FirebaseApp? secondary;
    try {
      secondary = await Firebase.initializeApp(
        name: 'secondary',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final auth = FirebaseAuth.instanceFor(app: secondary);
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        return 'Failed to create user.';
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'staffId': staffId,
        'email': email,
        'role': 'staff',
        'status': 'Active',
        'createdAt': DateTime.now().toIso8601String(),
        'leaveBalances': {
          'Annual': 0,
          'Compassionate': 0,
        },
      }, SetOptions(merge: true));

      await auth.signOut();
      await secondary.delete();
      return 'Staff account created successfully.';
    } catch (e) {
      if (secondary != null) {
        await secondary.delete();
      }
      return 'Error: $e';
    }
  }

  void _showDeleteStaffDialog() async {
    _StaffOption? selectedStaff;
    List<_StaffOption> staffOptions = [];
    bool loading = true;
    String? error;

    Future<void> loadStaff() async {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'staff')
            .get();
        staffOptions = snap.docs
            .map(
              (d) => _StaffOption(
                uid: d.id,
                name: (d.data()['name'] ??
                        d.data()['fullName'] ??
                        d.data()['staffName'] ??
                        d.data()['email'] ??
                        'Unknown')
                    .toString(),
                staffId: (d.data()['staffId'] ?? d.data()['userID'] ?? '')
                    .toString(),
              ),
            )
            .toList();
        error = null;
      } catch (e) {
        error = 'Failed to load staff';
      } finally {
        loading = false;
      }
    }

    // Load before showing dialog so initial state renders
    await loadStaff();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Delete Staff Account'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remove a staff member from the system.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  if (loading)
                    const Center(child: CircularProgressIndicator())
                  else if (error != null)
                    Column(
                      children: [
                        Text(error!, style: TextStyle(color: Colors.red[700])),
                        TextButton(
                          onPressed: () async {
                            setStateDialog(() {
                              loading = true;
                              error = null;
                            });
                            await loadStaff();
                             setStateDialog(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<_StaffOption>(
                      value: selectedStaff,
                      hint: const Text('Select a staff member'),
                      isExpanded: true,
                      items: staffOptions
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedStaff = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedStaff == null
                      ? Colors.red.shade100
                      : Colors.red.shade400,
                  foregroundColor:
                      selectedStaff == null ? Colors.red.shade300 : Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
                onPressed: _deletingStaff
                    ? null
                    : () async {
                        if (selectedStaff == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Select a staff member'),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _deletingStaff = true;
                        });
                        setStateDialog(() {});
                        Navigator.pop(ctx);
                        final msg = await _deleteStaffAccount(selectedStaff!);
                        if (mounted) {
                          setState(() {
                            _deletingStaff = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      },
                child: _deletingStaff
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Delete Account'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String> _deleteStaffAccount(_StaffOption staff) async {
    try {
      // Delete attendance subcollection
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(staff.uid);
      final attendanceSnap = await userRef.collection('attendance').get();
      for (final doc in attendanceSnap.docs) {
        await doc.reference.delete();
      }
      // Delete leaveRequests subcollection
      final leaveSnap = await userRef.collection('leaveRequests').get();
      for (final doc in leaveSnap.docs) {
        await doc.reference.delete();
      }
      // Delete user doc
      await userRef.delete();
      return 'Staff ${staff.displayName} deleted.';
    } catch (e) {
      return 'Error deleting staff: $e';
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/adminHome');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/adminLeave');
        break;
      case 2:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your admin account',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              _card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: _brandYellow,
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 42,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _adminName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _role.isNotEmpty ? _role : 'System Administrator',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _brandYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _textYellow700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_loadingProfile)
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    if (_profileError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _profileError!,
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Admin ID',
                      value: _adminId,
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.mail_outline,
                      label: 'Email',
                      value: _adminEmail,
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Staff Management',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _secondaryButton(
                      label: 'Create New Staff Account',
                      icon: Icons.person_add_alt,
                      onPressed: _showCreateStaffDialog,
                    ),
                    const SizedBox(height: 10),
                    _secondaryButton(
                      label: 'Delete Staff Account',
                      icon: Icons.delete_outline,
                      onPressed: _showDeleteStaffDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _actionButton(
                label: 'Logout',
                icon: Icons.logout,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _brandYellow,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Leave',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: isDestructive ? Colors.red.shade200 : Colors.grey.shade300,
          ),
          foregroundColor: isDestructive ? Colors.red.shade700 : Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey.shade300),
          foregroundColor: Colors.black87,
          backgroundColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _StaffOption {
  final String uid;
  final String staffId;
  final String name;

  _StaffOption({
    required this.uid,
    required this.staffId,
    required this.name,
  });

  String get displayName =>
      staffId.isNotEmpty ? '$name (ID: $staffId)' : name;
}
