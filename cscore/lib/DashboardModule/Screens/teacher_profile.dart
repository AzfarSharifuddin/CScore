import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cscore/AccountModule/screen/profile_edit.dart';
import 'package:cscore/AccountModule/model/manage_qualification.dart';
import 'package:cscore/AccountModule/screen/qualification_manage.dart';
class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();

    if (!mounted) return;
    setState(() {
      userData = doc.exists ? doc.data() : null;
      _loading = false;
    });
  }

  Future<void> _openEdit({bool openPassword = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileEditPage(openPassword: openPassword)),
    );
    await _loadUser();
  }

  void _openQualificationManager() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageQualificationPage()),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Teacher Profile', style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text('No profile found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    children: [
                      // --- PROFILE PHOTO / ICON ---
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.blueGrey.shade400,
                        child: Text(
                          (userData!['name'] ?? 'T')[0].toString().toUpperCase(),
                          style: const TextStyle(fontSize: 45, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- NAME ---
                      Text(
                        userData!['name'] ?? 'No name',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 6),

                      // --- ROLE TAG ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.work, size: 18, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            userData!['role'] ?? 'Teacher',
                            style: const TextStyle(fontSize: 15, color: Colors.black54),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // --- INFORMATION BOX ---
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          children: [
                            // EMAIL
                            Row(
                              children: [
                                const Icon(Icons.email_rounded, color: Colors.black87),
                                const SizedBox(width: 12),
                                const Text(
                                  'Email',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Text(userData!['email'] ?? ''),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // STATUS
                            Row(
                              children: [
                                const Icon(Icons.verified_user, color: Colors.black87),
                                const SizedBox(width: 12),
                                const Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Text(userData!['status'] ?? 'Active'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- EDIT PROFILE ---
                      buildProfileButton(
                        icon: Icons.settings_rounded,
                        text: 'Edit Profile',
                        onPressed: () => _openEdit(openPassword: false),
                      ),

                      const SizedBox(height: 12),

                      // --- CHANGE PASSWORD ---
                      buildProfileButton(
                        icon: Icons.lock_outline_rounded,
                        text: 'Change Password',
                        onPressed: () => _openEdit(openPassword: true),
                      ),

                      const SizedBox(height: 12),

                      // --- MANAGE QUALIFICATIONS ---
                      buildProfileButton(
                        icon: Icons.library_books,
                        text: 'Manage Qualifications',
                        onPressed: _openQualificationManager,
                      ),

                      const SizedBox(height: 12),

                      // --- LOGOUT ---
                      buildProfileButton(
                        icon: Icons.logout_rounded,
                        text: 'Logout',
                        iconColor: Colors.red,
                        textColor: Colors.red,
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
    );
  }

  // --- REUSABLE PROFILE BUTTON WIDGET ---
  Widget buildProfileButton({
    required IconData icon,
    required String text,
    Color iconColor = Colors.black87,
    Color textColor = Colors.black87,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
