import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ✅ Unified Profile Update Screen for STUDENT + TEACHER
/// File path: lib/AccountModule/screen/profile_update.dart
/// Includes:
/// - Edit Name
/// - Edit Contact
/// - Update Profile Photo (placeholder)
/// - Reset Password (with old password verification)
/// - Teacher Qualification button (if role == Teacher)

class ProfileUpdatePage extends StatefulWidget {
  const ProfileUpdatePage({super.key});

  @override
  State<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _userData;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (doc.exists) {
      _userData = doc.data()!;
      _nameController.text = _userData!['name'] ?? '';
      _contactController.text = _userData!['contact'] ?? '';
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'contact': _contactController.text.trim(),
      'updatedAt': Timestamp.now(),
    });

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  void _openResetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(email: _userData!['email']),
      ),
    );
  }

  void _openQualification() {
    Navigator.pushNamed(context, '/qualification');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueGrey.shade200,
                    child: const Icon(Icons.person, size: 55, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _saving
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.blueGrey,
                          ),
                          child: const Text('Save Changes'),
                        ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _openResetPassword,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Reset Password'),
                  ),
                  const SizedBox(height: 20),

                  if (_userData!['role'] == 'Teacher')
                    ElevatedButton(
                      onPressed: _openQualification,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Manage Qualifications'),
                    ),
                ],
              ),
            ),
    );
  }
}

/// ✅ RESET PASSWORD PAGE
class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _oldPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();

  bool _loading = false;

  Future<void> _updatePassword() async {
    setState(() => _loading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      /// ✅ Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: widget.email,
        password: _oldPass.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      /// ✅ Update password
      await user.updatePassword(_newPass.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _oldPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Old Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),

            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blueGrey,
                    ),
                    child: const Text('Update Password'),
                  )
          ],
        ),
      ),
    );
  }
}
