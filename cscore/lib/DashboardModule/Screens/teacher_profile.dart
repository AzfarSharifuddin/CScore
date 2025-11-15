import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cscore/AccountModule/screen/profile_edit.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _userData = null;
        _loading = false;
      });
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!mounted) return;
      setState(() {
        _userData = doc.exists ? (doc.data() as Map<String, dynamic>) : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }

  Future<void> _openEdit({bool openPassword = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileEditPage(openPassword: openPassword)),
    );
    await _loadUser();
  }

  void _openQualifications() {
    Navigator.pushNamed(context, '/qualification'); // ensure this route exists
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey[700]),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('My Profile', style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_userData == null)
              ? const Center(child: Text('Profile not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.blueGrey.shade200,
                        child: Text(
                          (_userData!['name'] ?? 'T').toString().isNotEmpty ? (_userData!['name'][0] ?? 'T').toString().toUpperCase() : 'T',
                          style: const TextStyle(fontSize: 40, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userData!['name'] ?? 'No name',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.school_rounded, size: 18, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(_userData!['role'] ?? 'Teacher', style: const TextStyle(fontSize: 15, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.email_rounded, 'Email', _userData!['email'] ?? ''),
                            _buildInfoRow(Icons.verified_user, 'Status', _userData!['status'] ?? 'Unknown'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openEdit(openPassword: false),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700], minimumSize: const Size(double.infinity, 50)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openEdit(openPassword: true),
                          icon: const Icon(Icons.lock_outline_rounded),
                          label: const Text('Change Password'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], minimumSize: const Size(double.infinity, 50)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openQualifications,
                          icon: const Icon(Icons.library_books),
                          label: const Text('Manage Qualifications'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], minimumSize: const Size(double.infinity, 50)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), minimumSize: const Size(double.infinity, 50)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
