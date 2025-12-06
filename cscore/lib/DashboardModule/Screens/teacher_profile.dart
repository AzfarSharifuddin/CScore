import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cscore/AccountModule/screen/profile_edit.dart';
import 'package:cscore/AccountModule/model/manage_qualification.dart';
import 'package:cscore/AccountModule/screen/qualification_manage.dart';
import 'package:cscore/AccountModule/screen/deactivateaccount.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  List<Qualification> qualifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // ------------------------------
  // LOAD USER + QUALIFICATIONS
  // ------------------------------
  Future<void> _loadUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('user').doc(uid).get();

    qualifications = await _getAllQualifications();

    if (!mounted) return;
    setState(() {
      userData = doc.exists ? doc.data() : null;
      _loading = false;
    });
  }

  // ------------------------------
  // FETCH QUALIFICATIONS
  // ------------------------------
  Future<List<Qualification>> _getAllQualifications() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('user')
        .doc(uid)
        .collection('qualification')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Qualification.fromMap(doc.id, doc.data()))
        .toList();
  }

  // ------------------------------
  // EDIT PROFILE
  // ------------------------------
  Future<void> _openEdit({bool openPassword = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditPage(openPassword: openPassword),
      ),
    );
    await _loadUser();
  }
  
  // ------------------------------
  // MANAGE QUALIFICATIONS
  // ------------------------------
  void _openQualificationManager() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageQualificationPage()),
    ).then((_) => _loadUser());
  }

  // ------------------------------
  // LOGOUT
  // ------------------------------
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
                      // ------------------------------
                      // PROFILE PHOTO
                      // ------------------------------
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.blueGrey.shade400,
                        child: Text(
                          (userData!['name'] ?? 'T')[0]
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(fontSize: 45, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // NAME
                      Text(
                        userData!['name'] ?? 'No name',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),

                      // ROLE
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

                      // ------------------------------
                      // INFO BOX (BIG BOX)
                      // ------------------------------
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            infoRow(Icons.email_rounded, "Email",
                                userData!['email'] ?? ''),
                            const SizedBox(height: 12),
                            infoRow(Icons.verified, "Status",
                                userData!['status'] ?? 'Active'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ------------------------------
                      // QUALIFICATIONS (BIG BOXES)
                      // ------------------------------
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Qualifications",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),

                      qualifications.isEmpty
                          ? const Text(
                              "No qualifications added yet",
                              style: TextStyle(color: Colors.black54),
                            )
                          : Column(
                              children: qualifications.map((q) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Institute: ${q.institution}",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Qualification: ${q.qualification}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                      const SizedBox(height: 25),

                      // ------------------------------
                      // BUTTONS
                      // ------------------------------
                      buildProfileButton(
                        icon: Icons.settings,
                        text: "Edit Profile",
                        onPressed: () => _openEdit(openPassword: false),
                      ),
                      const SizedBox(height: 12),

                      buildProfileButton(
                        icon: Icons.lock_outline,
                        text: "Change Password",
                        onPressed: () => _openEdit(openPassword: true),
                      ),
                      const SizedBox(height: 12),

                      buildProfileButton(
                        icon: Icons.library_books,
                        text: "Manage Qualifications",
                        onPressed: _openQualificationManager,
                      ),
                      const SizedBox(height: 12),
                        const SizedBox(height: 12),

                        buildProfileButton(
                          icon: Icons.pause_circle_filled_rounded,
                          text: 'Deactivate Account',
                          iconColor: Colors.orange,
                          textColor: Colors.orange,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DeactivateAccountPage()),
                            );
                          },
                        ),

                      buildProfileButton(
                        icon: Icons.logout_rounded,
                        text: "Logout",
                        iconColor: Colors.red,
                        textColor: Colors.red,
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
    );
  }

  // ------------------------------
  // INFO ROW COMPONENT
  // ------------------------------
  Widget infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value),
      ],
    );
  }

  // ------------------------------
  // REUSABLE BIG BUTTON
  // ------------------------------
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
